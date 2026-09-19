import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/network/api_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/admin/screens/admin_main_screen.dart';
import 'features/admin/screens/solo_tutor_dashboard.dart';
import 'features/admin/screens/super_admin/super_admin_platform_screen.dart';
import 'features/admin/screens/branch_admin/branch_admin_main_screen.dart';
import 'features/teacher/screens/teacher_dashboard.dart';
import 'features/student/screens/student_dashboard.dart';
import 'features/parent/screens/parent_dashboard.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await ApiService.initSessionFromStorage();
  runApp(const TutorOSApp());
}

class TutorOSApp extends StatelessWidget {
  const TutorOSApp({super.key});

  Widget _getHomeScreen() {
    final bool hasValidSession = ApiService.currentTenantId != null && 
        ApiService.currentUserId != null && 
        ApiService.currentToken != null && 
        (ApiService.currentToken?.isNotEmpty ?? false);
    if (!hasValidSession) {
      return const LoginScreen();
    }

    final role = ApiService.currentRole?.toUpperCase();
    switch (role) {
      case 'SUPER_ADMIN':
        return const SuperAdminPlatformScreen();
      case 'ADMIN':
        return const AdminMainScreen();
      case 'BRANCH_ADMIN':
        return const BranchAdminMainScreen();
      case 'SOLO_TUTOR':
        return const SoloTutorDashboard();
      case 'TEACHER':
        return const TeacherDashboard();
      case 'STUDENT':
        return const StudentDashboard();
      case 'PARENT':
        return const ParentDashboard();
      default:
        return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'TutorOS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: _getHomeScreen(),
        );
      },
    );
  }
}

