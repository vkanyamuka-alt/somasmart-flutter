# Push notifications (Firebase Cloud Messaging)

Students get:

- **a daily study reminder** at a time they pick (Settings → Notifications, or
  the card on Home from their second day of use);
- **announcements** that an admin chooses to send to phones (admin panel →
  Announcements → "Also send to phones");
- **a test notification** they can send themselves (Settings → Notifications).

Tapping a notification opens the app: reminders open Home, announcements open
Home with the announcements sheet. When the app is open, a navy banner with
**Open** is shown instead.

## How it fits together

```
 Phone (this app)                      Supabase                                Google
 ─────────────────                     ────────                                ──────
 firebase_messaging ── token ──►  register_device_token() → device_tokens
 Settings / Home card ──────────►  study_reminders (time, language, zone)
                                   pg_cron every 5 min → kick_study_reminders()
                                        └─ only if one is due → Edge Function push-reminders ─┐
 admin panel "send to phones" ──►  Edge Function push-send ───────────────────────────────────┤
                                                                     FCM HTTP v1 (service account)
 ◄──────────────────────────────────────────────────────────────── notification ──────────────┘
```

The server side (migration, Edge Functions, admin panel checkbox) lives in the
website repo, `vkanyamuka-alt/SomaSmart-app`, like every other migration:
`supabase/migrations/20261107120000_push_notifications.sql`,
`supabase/functions/push-send`, `supabase/functions/push-reminders`.

## In the app

| File | What it does |
| --- | --- |
| `lib/core/services/push/push_messaging.dart` | Firebase behind a small interface (tests use a fake) |
| `lib/core/services/push/push_controller.dart` | when to register, refresh, remove the token; no permission dialog at launch |
| `lib/core/services/push/push_routing.dart` | which screen a tap opens (allow-list, anything else → Home), time zone for reminders |
| `lib/core/services/push/push_providers.dart` | Supabase backend, foreground banner, tap navigation (waits past splash/sign-in) |
| `lib/features/settings/data/study_reminder.dart` | the reminder row in `study_reminders` |
| `lib/features/settings/presentation/widgets/study_reminder_flow.dart` | permission → time picker → save; the Home card |
| `android/app/src/main/kotlin/.../MainActivity.kt` | creates the channels "Study reminders" / "Announcements" (Swahili names on Swahili phones) |
| `android/app/src/main/res/drawable/ic_stat_somasmart.xml` | white status-bar icon; accent colour is logo navy |

**Permission (Android 13+).** Android's "Allow notifications?" dialog appears
only when the student turns notifications or the reminder on. Phones on Android
12 and older allow notifications by default; those phones register for
announcements as soon as the student signs in (the Settings switch turns them off).

**Sign-out** deletes this phone's row before the session ends, then deletes
the FCM token on the phone. If a session ends some other way, the phone token
is deleted, FCM reports it as gone, and the server removes the row on the next send.
A shared phone that signs in as another student moves the token to them.

**Builds without `google-services.json`** still build and run; push is simply
off ("Not available in this version of the app").

## Firebase setup (one time, by the owner)

Use the existing Google Cloud project **SomaSmart (`somasmart-514020`)**: it
already holds the Google sign-in clients and both owner accounts. One Firebase
project serves staging and production: the phone's token is stored in whichever
Supabase project the build talks to.

1. Open <https://console.firebase.google.com> signed in as **vkanyamuka@gmail.com**.
2. **Create a project**. On the first step, choose **Add Firebase to a Google
   Cloud project** (link under the name box) and pick **SomaSmart
   (somasmart-514020)**. Accept the terms. **Google Analytics: turn it off**
   (not needed; no extra data collection). Click **Add Firebase**.
3. In the new project: **Project overview → Add app → Android**.
   - Android package name: `com.example.somasmart_flutter`
   - App nickname: `SomaSmart Android`
   - Debug signing certificate SHA-1:
     `CF:D3:77:6D:8D:6B:EC:97:24:95:B9:A6:68:43:87:3C:A8:70:59:A4`
   - **Register app**.
4. **Download google-services.json** (save it in Downloads). Skip the "Add
   Firebase SDK" steps (the code already does this) → **Continue to console**.
   Tell Claude; it copies the file to `android/app/google-services.json`.
5. **Project settings (gear) → Cloud Messaging.** "Firebase Cloud Messaging API
   (V1)" must say **Enabled**. If not: ⋮ → **Manage API in Google Cloud
   Console** → **Enable**. (Ignore the "Legacy API", which is retired.)
6. **A key for the server, with only the messaging permission** (recommended
   over the all-powerful "Firebase Admin SDK" key):
   1. <https://console.cloud.google.com/iam-admin/serviceaccounts?project=somasmart-514020>
      → **Create service account**. Name `somasmart-push` → **Create and continue**.
   2. Role: **Firebase Cloud Messaging API Admin** → **Continue** → **Done**.
   3. Click `somasmart-push@…` → **Keys → Add key → Create new key → JSON →
      Create**. A `.json` file downloads. **This file is a password**: never
      commit it, email it or paste it into a chat.
7. **Give the key to Supabase staging** (the owner pastes it; Claude never sees it):
   - Dashboard → project **somasmart-staging** → **Edge Functions → Secrets**
     → **Add new secret**. Name `FIREBASE_SERVICE_ACCOUNT`. Value: open the key
     file in Notepad, Ctrl+A, Ctrl+C, paste. **Save**.
   - Or from your own PowerShell (base64 avoids quoting problems):

     ```powershell
     $b = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\Downloads\somasmart-514020-XXXX.json"))
     supabase secrets set --project-ref eflfzxhyzjkdwbddrsha "FIREBASE_SERVICE_ACCOUNT=$b"
     ```
   - Keep the key file somewhere safe outside the repo (it is needed again
     for production), or delete it and make a new key then.
8. Optional hardening: Cloud Console → **APIs & Services → Credentials** →
   "Android key (auto created by Firebase)" → Application restrictions:
   **Android apps**, add `com.example.somasmart_flutter` + the SHA-1 above.

### Is `google-services.json` committed? No.

It is not really a secret (it names the Firebase project and holds an API key
that only identifies the app), but this repo is **public** and `.gitignore`
already lists it: a public Google API key triggers GitHub and Google
"exposed key" alerts. So it stays out of git:

- The copy kept for builds: `Desktop\somasmart_backups\firebase\google-services.json`.
  Before any build that should receive notifications, copy it to
  `android/app/google-services.json`. Or download it again: Firebase console →
  Project settings → General → SomaSmart Android → `google-services.json`.
- **A build without it still works, but has no push** ("Not available in this
  version of the app"). Check before shipping a release.
- If the repo becomes private, committing it is fine (`git add -f`).

The service-account key (step 6) is the real secret, and it stays in Supabase only.

## Staging builds

```powershell
flutter build apk --release --build-number=2016 `
  --dart-define=SUPABASE_URL=https://eflfzxhyzjkdwbddrsha.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<staging anon key>
```

Build numbers must keep rising (the test Pixel has 2015).

## Going to production (owner's yes first)

1. Apply `20261107120000_push_notifications.sql` to production, then
   `select vault.create_secret('https://jgdsinabjhytasybgtix.supabase.co', 'project_url', 'Used by pg_cron to call Edge Functions');`
2. Deploy `push-send` and `push-reminders` with `--project-ref jgdsinabjhytasybgtix`.
3. Set the same `FIREBASE_SERVICE_ACCOUNT` secret on production.
4. Merge this PR and ship a build made with `android/app/google-services.json`
   in place (it is not in git; see above).
5. Before Google Play: `com.example.*` is not accepted, so a new package name
   means a new Android app in Firebase (and a new `google-services.json`).

## Web push (not built)

The website could get the same notifications with the Firebase JS SDK and a
service worker (`device_tokens.platform = 'web'` is already allowed). It needs
a VAPID key from Firebase → Cloud Messaging → Web Push certificates, and works
only while the browser keeps permission; iPhones need the site installed to the
home screen. Ask before building it.
