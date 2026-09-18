import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/rides/presentation/screens/create_ride_screen.dart';
import '../../features/rides/presentation/screens/ride_details_screen.dart';
import '../../features/tracking/presentation/screens/live_tracking_screen.dart';
import '../providers/firebase_providers.dart';
import '../widgets/root_shell.dart';

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const register = '/register';
  static const roleSelection = '/role-selection';
  static const home = '/';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const createRide = '/rides/new';
  static const rideDetails = '/rides/:rideId';
  static const chatList = '/chats';
  static const chatThread = '/chats/:threadId';
  static const liveTracking = '/rides/:rideId/tracking';

  static String rideDetailsPath(String rideId) => '/rides/$rideId';
  static String chatThreadPath(String threadId) => '/chats/$threadId';
  static String liveTrackingPath(String rideId) => '/rides/$rideId/tracking';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Solange der Auth-Status noch lädt, nichts umleiten.
      if (authState.isLoading) return null;

      if (!loggedIn && !loggingIn) return AppRoutes.login;
      if (loggedIn && loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => RootShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.chatList,
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.createRide,
        builder: (context, state) => const CreateRideScreen(),
      ),
      GoRoute(
        path: AppRoutes.rideDetails,
        builder: (context, state) => RideDetailsScreen(
          rideId: state.pathParameters['rideId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.chatThread,
        builder: (context, state) => ChatScreen(
          threadId: state.pathParameters['threadId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.liveTracking,
        builder: (context, state) => LiveTrackingScreen(
          rideId: state.pathParameters['rideId']!,
        ),
      ),
    ],
  );
});

