/// Environment configuration for SomaSmart.
///
/// Release builds talk to PRODUCTION. A test build for the staging project
/// passes its own values, without editing this file:
///
///   flutter build apk
///     --dart-define=SUPABASE_URL=https://eflfzxhyzjkdwbddrsha.supabase.co
///     --dart-define=SUPABASE_ANON_KEY=STAGING_ANON_KEY
///     --dart-define=GOOGLE_WEB_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jgdsinabjhytasybgtix.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnZHNpbmFiamh5dGFzeWJndGl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NjY1NTIsImV4cCI6MjA5ODI0MjU1Mn0.GMEFjQvutfajy36sTHdsTMb6lo3ApAhp2cWlkHMbKx4',
  );

  /// The *Web application* OAuth client ID from Google Cloud (not the Android
  /// one): Google signs the ID token for it, and Supabase checks it is on the
  /// Google provider's client ID list. Client IDs are public, not secrets.
  /// Empty = no "Continue with Google" button in this build.
  static const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool get googleSignInConfigured => googleWebClientId.isNotEmpty;
}
