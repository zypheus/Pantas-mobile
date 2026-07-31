import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/faculty/screens/faculty_home_screen.dart';
import '../../features/faculty/screens/my_folders_screen.dart';
import '../../features/faculty/screens/create_folder_screen.dart';
import '../../features/faculty/screens/folder_details_screen.dart';
import '../../features/faculty/screens/my_rooms_screen.dart';
import '../../features/faculty/screens/create_room_screen.dart';
import '../../features/faculty/screens/room_details_screen.dart';
import '../../features/faculty/screens/share_room_screen.dart';
import '../../features/faculty/screens/manage_students_screen.dart';
import '../../features/faculty/screens/add_books_to_room_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../services/user_service.dart';
import '../../features/catalog/screens/catalog_search_screen.dart';
import '../../features/catalog/screens/book_details_screen.dart';
import '../../features/catalog/screens/book_reservations_screen.dart';
import '../../features/faculty/screens/faculty_catalog_screen.dart';
import '../../features/faculty/screens/faculty_book_details_screen.dart';
import '../../features/faculty/screens/faculty_profile_screen.dart';
import '../../features/borrow_cart/screens/borrow_cart_screen.dart';
import '../../features/borrow_cart/screens/borrow_requests_screen.dart';
import '../../features/borrowed_books/screens/borrowed_books_screen.dart';
import '../../features/classrooms/screens/classroom_detail_screen.dart';
import '../../features/classrooms/screens/faculty_recommendations_screen.dart';
import '../../features/classrooms/screens/join_classroom_screen.dart';
import '../../features/classrooms/screens/my_classrooms_screen.dart';
import '../../features/rooms/screens/room_reservation_screen.dart';
import '../../features/rooms/screens/room_reservation_details_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/digital_id_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/feedback/screens/feedback_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/faculty_bottom_nav.dart';

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
        builder: (context, state, child) => FacultyShell(child: child),
        routes: [
          GoRoute(
            path: '/faculty_home',
            builder: (context, state) => const FacultyHomeScreen(),
          ),
          GoRoute(
            path: '/faculty/folders',
            builder: (context, state) => const MyFoldersScreen(),
          ),
          GoRoute(
            path: '/faculty/create-folder',
            builder: (context, state) => const CreateFolderScreen(),
          ),
          GoRoute(
            path: '/faculty/folders/details',
            builder: (context, state) {
              final folderId = state.uri.queryParameters['id'] ?? '';
              return FolderDetailsScreen(folderId: folderId);
            },
          ),
          GoRoute(
            path: '/faculty/rooms',
            builder: (context, state) => const MyRoomsScreen(),
          ),
          GoRoute(
            path: '/faculty/create-room',
            builder: (context, state) => const CreateRoomScreen(),
          ),
          GoRoute(
            path: '/faculty/rooms/details',
            builder: (context, state) {
              final roomId = state.uri.queryParameters['id'] ?? '';
              return RoomDetailsScreen(classroomId: roomId);
            },
          ),
          GoRoute(
            path: '/faculty/rooms/share',
            builder: (context, state) {
              final roomId = state.uri.queryParameters['id'] ?? '';
              return ShareRoomScreen(classroomId: roomId);
            },
          ),
          GoRoute(
            path: '/faculty/rooms/manage',
            builder: (context, state) {
              final roomId = state.uri.queryParameters['id'] ?? '';
              return ManageStudentsScreen(classroomId: roomId);
            },
          ),
          GoRoute(
            path: '/faculty/rooms/add-books',
            builder: (context, state) {
              final roomId = state.uri.queryParameters['id'] ?? '';
              return AddBooksToRoomScreen(classroomId: roomId);
            },
          ),
          GoRoute(
            path: '/faculty/catalog',
            builder: (context, state) {
              final folderId = state.uri.queryParameters['folderId'];
              return FacultyCatalogScreen(folderId: folderId);
            },
          ),
          GoRoute(
            path: '/faculty/book_details',
            builder: (context, state) {
              final id = state.uri.queryParameters['id'] ?? '';
              final folderId = state.uri.queryParameters['folderId'];
              return FacultyBookDetailsScreen(
                bookId: id,
                folderId: folderId,
              );
            },
          ),
          GoRoute(
            path: '/faculty/profile',
            builder: (context, state) => const FacultyProfileScreen(),
          ),
        ],
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
        path: '/borrow_requests',
        builder: (context, state) => const BorrowRequestsScreen(),
      ),
      GoRoute(
        path: '/book_reservations',
        builder: (context, state) => const BookReservationsScreen(),
      ),
      GoRoute(
        path: '/classrooms',
        builder: (context, state) => const MyClassroomsScreen(),
      ),
      GoRoute(
        path: '/classrooms/join',
        builder: (context, state) => const JoinClassroomScreen(),
      ),
      GoRoute(
        path: '/classrooms/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ClassroomDetailScreen(classroomId: id);
        },
      ),
      GoRoute(
        path: '/faculty_recommendations',
        builder: (context, state) => const FacultyRecommendationsScreen(),
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

class FacultyShell extends StatelessWidget {
  final Widget child;
  const FacultyShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const FacultyFloatingNavBar());
  }
}

/// Returns the post-auth home route for the current user role.
String homeRouteForCurrentUser() {
  final user = UserService().currentUser;
  if (user?.isFaculty == true) {
    return '/faculty_home';
  }
  return '/home';
}
