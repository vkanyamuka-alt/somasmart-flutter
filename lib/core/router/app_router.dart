import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notes/presentation/screens/note_viewer_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/app_shell.dart';
import '../../features/shop/presentation/screens/payment_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/shop/presentation/screens/subscription_screen.dart';
import '../../features/subjects/presentation/screens/subject_detail_screen.dart';
import '../../features/subjects/presentation/screens/level_screen.dart';
import '../../features/forum/presentation/screens/discussion_detail_screen.dart';
import '../../features/forum/presentation/screens/forum_screen.dart';
import '../../features/practice/presentation/screens/quiz_exams_screen.dart';
import '../../features/practice/presentation/screens/quiz_results_screen.dart';
import '../../features/practice/presentation/screens/quiz_session_screen.dart';
import '../../features/syllabus/presentation/screens/syllabus_library_screen.dart';
import '../../features/tutor/presentation/screens/ask_me_screen.dart';
import '../../features/practicals/data/models/practical_model.dart';
import '../../features/practicals/presentation/screens/practical_level_screen.dart';
import '../../features/practicals/presentation/screens/practical_theory_screen.dart';
import '../../features/practicals/presentation/screens/practical_subject_screen.dart';
import '../../features/practicals/presentation/screens/practical_mode_screen.dart';
import '../../features/practicals/presentation/screens/microscope_screen.dart';
import '../../features/practicals/presentation/screens/ohms_law_screen.dart';
import '../../features/practicals/presentation/screens/optics_screen.dart';
import '../../features/practicals/presentation/screens/osmosis_screen.dart';
import '../../features/practicals/presentation/screens/pendulum_screen.dart';
import '../../features/practicals/presentation/screens/rates_of_reaction_screen.dart';
import '../../features/practicals/presentation/screens/gas_preparation_screen.dart';
import '../../features/practicals/presentation/screens/titration_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/screens/contact_support_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Routes reachable without signing in. Every other route requires a Supabase session.
const publicRoutes = {
  '/splash',
  '/welcome',
  '/login',
  '/signup',
  '/forgot-password',
  '/contact-support',
};

/// go_router redirect: signed-out users are sent to /login from any non-public route.
String? authRedirect({required String location, required bool isSignedIn}) {
  if (isSignedIn || publicRoutes.contains(location)) return null;
  return '/login';
}

/// Re-runs the redirect whenever Supabase signs in, signs out or drops the session.
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthChangeNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // main() initialises Supabase before runApp. If it is not available (e.g. widget tests),
  // fail closed: treat the user as signed out, like the splash screen does.
  GoTrueClient? auth;
  try {
    auth = ref.watch(supabaseClientProvider).auth;
  } catch (_) {
    auth = null;
  }
  final authChanges = _AuthChangeNotifier(auth?.onAuthStateChange ?? const Stream.empty());
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authChanges,
    redirect: (context, state) => authRedirect(
      location: state.matchedLocation,
      isSignedIn: auth?.currentSession != null,
    ),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => NoTransitionPage(
          child: Theme(
            data: AppTheme.lightTheme,
            child: const SplashScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        parentNavigatorKey: rootNavigatorKey,
        // Fades in from the splash instead of sliding.
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
          child: Theme(
            data: AppTheme.lightTheme,
            child: const WelcomeScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          child: Theme(
            data: AppTheme.lightTheme,
            child: const LoginScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          child: Theme(
            data: AppTheme.lightTheme,
            child: const SignUpScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          child: Theme(
            data: AppTheme.lightTheme,
            child: const ForgotPasswordScreen(),
          ),
        ),
      ),
      // First Google sign-in: phone number and form (signed-in only).
      GoRoute(
        path: '/complete-profile',
        name: 'complete-profile',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          child: Theme(
            data: AppTheme.lightTheme,
            child: const CompleteProfileScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/contact-support',
        name: 'contact-support',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          child: Theme(
            data: AppTheme.lightTheme,
            child: const ContactSupportScreen(),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // 1. Home Branch (Tab 0)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // 2. Shop Branch (Tab 1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                name: 'shop',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ShopScreen(),
                ),
              ),
            ],
          ),

          // 3. Progress Branch (Tab 2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                name: 'progress',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProgressScreen(),
                ),
              ),
            ],
          ),

          // 4. Account Branch (Tab 3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                name: 'account',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AccountScreen(),
                ),
              ),
            ],
          ),

          // 5. Settings Branch (Tab 4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Direct Deep Routes (Above Shell)
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/payment',
        name: 'payment',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/subjects',
        name: 'subjects',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            LevelScreen(level: state.uri.queryParameters['level'] ?? 'o-level'),
      ),
      GoRoute(
        // A form's (or stream's) own screen: /subjects/o-level/2, /subjects/a-level/arts.
        path: '/subjects/:level/:choice',
        name: 'level-choice',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => LevelScreen(
          level: state.pathParameters['level'] ?? 'o-level',
          choice: state.pathParameters['choice'],
        ),
      ),
      GoRoute(
        path: '/subjects/:id',
        name: 'subject-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final subjectId = state.pathParameters['id'] ?? '1';
          return SubjectDetailScreen(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/notes/:id',
        name: 'note-viewer',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final noteId = state.pathParameters['id'] ?? '';
          return NoteViewerScreen(noteId: noteId);
        },
      ),
      GoRoute(
        path: '/syllabus',
        name: 'syllabus',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SyllabusLibraryScreen(),
      ),
      GoRoute(
        path: '/quiz-exams',
        name: 'quiz-exams',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return QuizExamsScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/exams',
        name: 'exams',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return QuizExamsScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/quiz/:id',
        name: 'quiz-session',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final quizId = state.pathParameters['id'] ?? '';
          return QuizSessionScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: '/quiz/results/:attemptId',
        name: 'quiz-results',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final attemptId = state.pathParameters['attemptId'] ?? '';
          final scoreStr = state.uri.queryParameters['score'];
          final timeStr = state.uri.queryParameters['time'];
          final totalStr = state.uri.queryParameters['total'];
          final quizId = state.uri.queryParameters['quiz_id'];

          return QuizResultsScreen(
            attemptId: attemptId,
            fallbackScore: double.tryParse(scoreStr ?? ''),
            fallbackTime: int.tryParse(timeStr ?? ''),
            fallbackTotal: int.tryParse(totalStr ?? ''),
            fallbackQuizId: quizId,
          );
        },
      ),
      GoRoute(
        path: '/forum',
        name: 'forum',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForumScreen(),
      ),
      GoRoute(
        path: '/forum/:id',
        name: 'forum-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DiscussionDetailScreen(discussionId: id);
        },
      ),
      GoRoute(
        path: '/ask-me',
        name: 'ask-me',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final prompt = state.uri.queryParameters['prompt'];
          return AskMeScreen(initialPrompt: prompt);
        },
      ),
      GoRoute(
        path: '/practicals',
        name: 'practicals',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PracticalLevelScreen(),
      ),
      GoRoute(
        path: '/practical',
        name: 'practical',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PracticalLevelScreen(),
      ),
      GoRoute(
        path: '/practical/mode-selection/:practicalId',
        name: 'practical-mode-selection',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final practicalId = state.pathParameters['practicalId'] ?? 'titration';
          return PracticalModeScreen(practicalId: practicalId);
        },
      ),
      GoRoute(
        path: '/practical/theory/:practicalId',
        name: 'practical-theory',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PracticalTheoryScreen(practicalId: state.pathParameters['practicalId'] ?? 'titration'),
      ),
      GoRoute(
        path: '/practical/simulation/:practicalId',
        name: 'practical-simulation',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final practicalId = state.pathParameters['practicalId'] ?? 'titration';
          final modeStr = state.uri.queryParameters['mode'] ?? 'guidedPractice';
          final mode = PracticalModeExtension.fromId(modeStr);
          if (practicalId == 'ohms-phys' || practicalId == 'ohms_law') {
            return OhmsLawScreen(mode: mode);
          }
          if (practicalId == 'microscope-bio' || practicalId == 'microscope') {
            return MicroscopeScreen(mode: mode);
          }
          if (practicalId == 'pendulum-phys' || practicalId == 'pendulum') {
            return PendulumScreen(mode: mode);
          }
          if (practicalId == 'optics-phys' || practicalId == 'optics') {
            return OpticsScreen(mode: mode);
          }
          if (practicalId == 'osmosis-bio' || practicalId == 'osmosis') {
            return OsmosisScreen(mode: mode);
          }
          if (practicalId == 'reaction-rates' || practicalId == 'rates_of_reaction' || practicalId == 'rates-of-reaction') {
            return RatesOfReactionScreen(mode: mode);
          }
          if (practicalId == 'gas-prep' || practicalId == 'gas_prep' || practicalId == 'gas-preparation' || practicalId == 'gas_preparation') {
            return GasPreparationScreen(mode: mode);
          }
          return TitrationScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/practical/:level/:subject',
        name: 'practical-subject',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final levelStr = state.pathParameters['level'] ?? 'o-level';
          final subjectStr = state.pathParameters['subject'] ?? 'chemistry';
          final level = PracticalLevelExtension.fromId(levelStr);
          final subject = PracticalSubjectExtension.fromId(subjectStr);
          return PracticalSubjectScreen(level: level, initialSubject: subject);
        },
      ),
      GoRoute(
        path: '/practical/:level',
        name: 'practical-level',
        parentNavigatorKey: rootNavigatorKey,
        // The lab home lists the subjects (one place for it, as on the web).
        builder: (context, state) => const PracticalLevelScreen(),
      ),
    ],
  );
});
