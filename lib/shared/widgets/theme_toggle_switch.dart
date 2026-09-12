import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// BB-8 & Scenery Inspired Day/Night Animated Theme Toggle Switch
class ThemeToggleSwitch extends StatefulWidget {
  final double width;
  final double height;

  const ThemeToggleSwitch({
    super.key,
    this.width = 66,
    this.height = 34,
  });

  @override
  State<ThemeToggleSwitch> createState() => _ThemeToggleSwitchState();
}

class _ThemeToggleSwitchState extends State<ThemeToggleSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: AppTheme.isDarkMode ? 1.0 : 0.0,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    AppTheme.themeModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (AppTheme.isDarkMode) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    AppTheme.themeModeNotifier.removeListener(_onThemeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    AppTheme.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;
    final knobSize = h - 6;

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final t = _animation.value; // 0.0 = Light (Day), 1.0 = Dark (Night)

          return Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    const Color(0x334338CA),
                    const Color(0x66000000),
                    t,
                  )!,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(h / 2),
              child: Stack(
                children: [
                  // 1. Sky Background Gradient (Day / Night)
                  Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(const Color(0xFF38BDF8), const Color(0xFF0F172A), t)!,
                          Color.lerp(const Color(0xFF93C5FD), const Color(0xFF030712), t)!,
                        ],
                      ),
                    ),
                  ),

                  // 2. Stars (Fade in on Night mode)
                  if (t > 0.05) ...[
                    Positioned(
                      left: w * 0.22,
                      top: h * 0.25,
                      child: Opacity(
                        opacity: t,
                        child: const _Star(size: 2.2),
                      ),
                    ),
                    Positioned(
                      left: w * 0.38,
                      top: h * 0.6,
                      child: Opacity(
                        opacity: t,
                        child: const _Star(size: 1.8),
                      ),
                    ),
                    Positioned(
                      left: w * 0.48,
                      top: h * 0.2,
                      child: Opacity(
                        opacity: t,
                        child: const _Star(size: 2.5),
                      ),
                    ),
                    Positioned(
                      left: w * 0.16,
                      top: h * 0.68,
                      child: Opacity(
                        opacity: t * 0.8,
                        child: const _Star(size: 1.5),
                      ),
                    ),
                  ],

                  // 3. Desert Dunes / Horizon (Tatooine Scenery)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: h * 0.32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFD4A373).withValues(alpha: 0.9),
                          const Color(0xFF1E293B).withValues(alpha: 0.9),
                          t,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(w * 0.3),
                          topRight: Radius.circular(w * 0.2),
                        ),
                      ),
                    ),
                  ),

                  // 4. Day Clouds (Fade and move out on Night)
                  if (t < 0.95) ...[
                    Positioned(
                      right: (1 - t) * (w * 0.2) + (t * (w * 0.8)),
                      top: h * 0.2,
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Container(
                          width: w * 0.24,
                          height: h * 0.24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: (1 - t) * (w * 0.1) - (t * (w * 0.4)),
                      bottom: h * 0.28,
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Container(
                          width: w * 0.18,
                          height: h * 0.18,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 5. Moons (Crescent / Twin Suns)
                  Positioned(
                    left: w * 0.18,
                    top: h * 0.18,
                    child: Opacity(
                      opacity: t,
                      child: Container(
                        width: h * 0.28,
                        height: h * 0.28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE2E8F0),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x66FFFFFF),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 6. Sliding Droid / Sun-Moon Knob
                  Positioned(
                    left: 3 + t * (w - knobSize - 6),
                    top: 3,
                    width: knobSize,
                    height: knobSize,
                    child: Transform.rotate(
                      angle: t * math.pi * 2,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            const Color(0xFFFFFFFF),
                            const Color(0xFFF1F5F9),
                            t,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.lerp(
                                const Color(0x4D000000),
                                const Color(0x8038BDF8),
                                t,
                              )!,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Droid Body Ring (BB-8 Orange Accent in Day, Indigo in Night)
                            Container(
                              width: knobSize * 0.72,
                              height: knobSize * 0.72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color.lerp(
                                    const Color(0xFFEA580C), // BB-8 orange
                                    const Color(0xFF6366F1), // Night Indigo
                                    t,
                                  )!,
                                  width: 2.2,
                                ),
                              ),
                            ),
                            // Center Icon / Lens Dot
                            Container(
                              width: knobSize * 0.32,
                              height: knobSize * 0.32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.lerp(
                                  const Color(0xFFF97316),
                                  const Color(0xFF38BDF8),
                                  t,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  t > 0.5 ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                  size: knobSize * 0.24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Star extends StatelessWidget {
  final double size;

  const _Star({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xAAFFFFFF),
            blurRadius: 2,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}
