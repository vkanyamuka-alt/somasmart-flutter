# "Continue with Google" in the Android app

The full owner guide (Google Cloud project, consent screen, Web and Android
OAuth clients, Supabase provider, production switch, undo) is in the website
repo: `SomaSmart-app/docs/GOOGLE_SIGN_IN.md`. This page is the app-specific part.

## How it works

1. **Login** and **Sign up** show *Continue with Google* under the phone form,
   only in builds made with `--dart-define=GOOGLE_WEB_CLIENT_ID=…`.
2. `google_sign_in` 7 opens Android's own account picker (Credential Manager)
   and returns a Google **ID token** for the *Web* client ID.
3. `supabase.auth.signInWithIdToken(provider: google, idToken: …)` signs in.
   No browser, no deep link, no client secret in the app.
4. First time: the `on_auth_user_created` trigger creates the profile as a free
   student. Google gives no phone number or form, so the app opens
   **Finish your account** (`/complete-profile`: name, phone, form) before Home.
   The splash screen sends a Google student back there if they closed the app
   before finishing. Saved through `student_profiles` (form) and the
   `update_my_profile` RPC (name + phone), like the website.
5. Sign out also signs out of Google, so the next student on a shared phone gets
   the account picker.

## What Google Cloud needs for Android

An **Android** OAuth client with:

- Package name: `com.example.somasmart_flutter` (current `applicationId`)
- SHA-1 of the key the APK/AAB is signed with. Builds are currently signed with
  this PC's debug key (`android/app/build.gradle.kts` → `signingConfigs.debug`):

  ```
  SHA-1:   CF:D3:77:6D:8D:6B:EC:97:24:95:B9:A6:68:43:87:3C:A8:70:59:A4
  SHA-256: 18:F0:BD:8E:DC:21:F3:DF:08:52:93:B1:1F:83:6E:79:A7:BF:41:D1:81:7C:8E:03:41:06:EB:C2:14:DD:CE:8E
  ```

  Read it again with:

  ```bash
  "/c/Program Files/Android/Android Studio/jbr/bin/keytool.exe" -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```

A build from another PC (other debug key) needs that PC's SHA-1 added too.

**Before Google Play:** Play rejects `com.example.*`, and Play App Signing
re-signs the app with Google's key. When the package name changes, add an
Android client for the new name with the **upload key** SHA-1 *and* the
**App signing key** SHA-1 (Play Console → Test and release → App integrity).
Missing the Play one shows up as a "canceled" error right after the student
picks an account.

## Builds

The app still talks to **production** unless told otherwise
(`lib/core/config/env.dart`). Staging test build for the phone:

```bash
flutter build apk --release --build-number=2014 --dart-define=SUPABASE_URL=https://eflfzxhyzjkdwbddrsha.supabase.co --dart-define=SUPABASE_ANON_KEY=<staging anon key> --dart-define=GOOGLE_WEB_CLIENT_ID=<web client id>.apps.googleusercontent.com
```

(The phone has build 2013; Android refuses a lower build number.)

Production release, once Google is on in production Supabase:

```bash
flutter build appbundle --release --build-number=<next> --dart-define=GOOGLE_WEB_CLIENT_ID=<web client id>.apps.googleusercontent.com
```

Without `GOOGLE_WEB_CLIENT_ID` the app has no Google button and works exactly
as before.
