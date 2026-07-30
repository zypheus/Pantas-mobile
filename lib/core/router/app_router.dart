import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/catalog/screens/catalog_search_screen.dart';
import '../../features/catalog/screens/book_details_screen.dart';
import '../../features/catalog/screens/book_reservations_screen.dart';
import '../../features/borrow_cart/screens/borrow_cart_screen.dart';
import '../../features/borrowed_books/screens/borrowed_books_screen.dart';
import '../../features/rooms/screens/room_reservation_screen.dart';
import '../../features/rooms/screens/room_reservation_details_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/digital_id_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/feedback/screens/feedback_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/app_bottom_nav.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'register',
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: 'change-password',
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const CatalogSearchScreen(),
          ),
          GoRoute(
            path: '/borrowed',
            builder: (context, state) => const BorrowedBooksScreen(),
          ),
          GoRoute(
            path: '/room_reservation',
            builder: (context, state) => const RoomReservationScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/feedback',
            builder: (context, state) => const FeedbackScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/book_details',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return BookDetailsScreen(bookId: id);
        },
      ),
      GoRoute(
        path: '/borrow_cart',
        builder: (context, state) => const BorrowCartScreen(),
      ),
      GoRoute(
        path: '/book_reservations',
        builder: (context, state) => const BookReservationsScreen(),
      ),
      GoRoute(
        path: '/room_reservation_details',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return RoomReservationDetailsScreen(reservationId: id);
        },
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/digital-id',
        builder: (context, state) => const DigitalIdScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const FloatingNavBar());
  }
}
