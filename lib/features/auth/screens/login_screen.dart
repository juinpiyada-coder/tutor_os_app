import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../admin/screens/admin_main_screen.dart';
import '../../admin/screens/super_admin/super_admin_platform_screen.dart';
import '../../admin/screens/branch_admin/branch_admin_main_screen.dart';
import '../../admin/screens/register_institute_screen.dart';
import '../../admin/screens/register_solo_tutor_screen.dart';
import '../../admin/screens/solo_tutor_dashboard.dart';
import '../../student/screens/student_dashboard.dart';
import '../../parent/screens/parent_dashboard.dart';
import '../../teacher/screens/teacher_dashboard.dart';
import 'student_coaching_enroll_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username/email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.login(
        username,
        password,
      );

      final role = (response['user'] != null && response['user'] is Map
              ? (response['user']['role'] ?? '')
              : (response['role'] ?? ''))
          .toString()
          .toUpperCase();
      
      if (!mounted) return;
      
      Widget nextScreen;
      switch (role) {
        case 'SUPER_ADMIN':
          nextScreen = const SuperAdminPlatformScreen();
          break;
        case 'SOLO_TUTOR':
          nextScreen = const SoloTutorDashboard();
          break;
        case 'ADMIN':
          nextScreen = const AdminMainScreen();
          break;
        case 'BRANCH_ADMIN':
          nextScreen = const BranchAdminMainScreen();
          break;
        case 'TEACHER':
          nextScreen = const TeacherDashboard();
          break;
        case 'STUDENT':
          nextScreen = const StudentDashboard();
          break;
        case 'PARENT':
          nextScreen = const ParentDashboard();
          break;
        default:
          nextScreen = const StudentDashboard();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTopBranding() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Official TutorOS Logo SVG Badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SvgPicture.asset(
            'lib/assets/logo.svg',
            fit: BoxFit.contain,
            placeholderBuilder: (BuildContext context) => Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF4338CA),
                    size: 34,
                  ),
                ),
                Positioned(
                  left: 4,
                  top: 24,
                  child: Container(
                    width: 5,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Tutor',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1B4B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'OS',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4338CA),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Smarter Teaching.\nBetter Learning.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive hero character height for uncropped, big prominent display
    final heroHeight = (screenHeight * 0.42).clamp(310.0, 440.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: Stack(
        children: [
          // Ambient warm sunny background circles
          Positioned(
            top: -40,
            right: -50,
            width: screenWidth * 0.75,
            height: screenWidth * 0.75,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFEF3C7).withValues(alpha: 0.8),
                    const Color(0xFFFFFBEB).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.12,
            left: -60,
            width: screenWidth * 0.6,
            height: screenWidth * 0.6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEEF2FF).withValues(alpha: 0.9),
                    const Color(0xFFF8FAFC).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Bottom decorative ambient lavender wave
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFEEF2FF),
                      Color(0xFFE0E7FF),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scrollable Content Layer
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),

                  // Top Branding Header with logo.svg
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildTopBranding(),
                  ),

                  const SizedBox(height: 6),

                  // Hero SVG Illustration - Big, Crisp, Scaled Girl Character
                  Container(
                    height: heroHeight,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: 1.35,
                      alignment: Alignment.bottomCenter,
                      child: SvgPicture.asset(
                        'lib/assets/assestes.svg',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        placeholderBuilder: (BuildContext context) => Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overlapping Curved White Form Container (Smooth Top Arc)
                  Transform.translate(
                    offset: const Offset(0, -26),
                    child: ClipPath(
                      clipper: CurvedTopClipper(),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 28,
                              offset: Offset(0, -8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.only(
                          top: 40.0,
                          left: 28.0,
                          right: 28.0,
                          bottom: 52.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // "Welcome to TutorOS" Headline
                            Text(
                              'Welcome to TutorOS',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 29,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E1B4B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle
                            Text(
                              'Sign in to access your coaching dashboard',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Error Message Banner
                            if (_errorMessage.isNotEmpty) ...[
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 20.0),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFB91C1C),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Username / Email Input Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _usernameController,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF1E1B4B),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your username or email',
                                  hintStyle: GoogleFonts.inter(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 14.5,
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 14.0),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF4F46E5),
                                      size: 22,
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2),
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Input Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF1E1B4B),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: GoogleFonts.inter(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 14.5,
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 14.0),
                                    child: Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF4F46E5),
                                      size: 22,
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3AF),
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2),
                                  ),
                                ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _login(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sign In Button (Royal Indigo Gradient + Ambient Glow)
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4F46E5), // Royal Indigo
                                    Color(0xFF4338CA), // Deep Indigo
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4338CA).withValues(alpha: 0.38),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Register Institute Footer Link
                            // Dedicated Solo Tutor Quick Register Banner
                            // Student Coaching Self-Enrollment Card
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B5AE6).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0B5AE6).withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B5AE6).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.school_rounded, color: Color(0xFF0B5AE6), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Student Joining a Coaching Center?',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: const Color(0xFF0B5AE6),
                                          ),
                                        ),
                                        Text(
                                          'Search your institute & enroll instantly',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF1E40AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const StudentCoachingEnrollScreen()),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF0B5AE6),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    child: const Text('Enroll →'),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.cast_for_education_rounded, color: Color(0xFF0D9488), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Single Teacher / Solo Tutor?',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: const Color(0xFF0F766E),
                                          ),
                                        ),
                                        Text(
                                          'Combined Educator & Business Desk',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF115E59),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const RegisterSoloTutorScreen()),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF0D9488),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    child: const Text('Start Solo'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New coaching academy? ',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterInstituteScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Register Institute',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF4338CA),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom clipper for the curved top of the form sheet
class CurvedTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 32);
    path.quadraticBezierTo(size.width / 2, -14, size.width, 32);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom clipper for the bottom background wave
class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 42);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 32);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


