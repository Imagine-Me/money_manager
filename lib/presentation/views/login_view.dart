import 'package:flutter/material.dart';
import 'package:money_manager/core/services/preferences_service.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/presentation/views/home_shell.dart';
import 'package:money_manager/presentation/views/onboarding_view.dart';
import 'package:money_manager/services/backup_service.dart';
import 'package:money_manager/services/google_auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoading = false;

  Future<void> _continueAsGuest() async {
    await PreferencesService.instance.saveLoginDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingView()),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await GoogleAuthService.instance.signIn();
      if (user == null) {
        // User cancelled the sign-in dialog
        setState(() => _isLoading = false);
        return;
      }
      await PreferencesService.instance.saveLoginDone();

      // Try to restore an existing backup from Drive.
      // If found, preferences (including currency + isSetupDone) are restored.
      bool restored = false;
      try {
        restored = await BackupService.instance.restoreFromDrive();
        if (restored) {
          // Reload the in-memory preferences so the app reads the restored values.
          await PreferencesService.instance.load();
        }
      } catch (_) {
        // Restore failure is non-fatal — fall through to onboarding.
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => restored ? const HomeShell() : const OnboardingView(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // ── App logo ─────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.storeColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 32),

              // ── Headline ─────────────────────────────────────────────────
              const Text(
                'Welcome to\nVaultCash',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Track your money, your way.\nSign in with Google to enable cloud sync,\nor continue offline as a guest.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              const Spacer(flex: 3),

              // ── Google sign-in button ─────────────────────────────────────
              _GoogleSignInButton(
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _signInWithGoogle,
              ),
              const SizedBox(height: 14),

              // ── Guest button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Footer note ───────────────────────────────────────────────
              const Center(
                child: Text(
                  'Guest mode works fully offline.\nYou can sign in later from Settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Google sign-in button ────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          disabledBackgroundColor: Colors.white24,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleGLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3C4043),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Draws the coloured Google "G" mark using RichText.
class _GoogleGLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    // Draw the coloured arc segments of the Google "G"
    const sweepAngles = <double>[
      1.05, // Blue (right): ~60° gap at end
      1.10, // Red (bottom-left)
      1.05, // Yellow (bottom)
      1.05, // Green (top-left)
    ];
    const colors = <Color>[
      Color(0xFF4285F4), // Blue
      Color(0xFFEA4335), // Red
      Color(0xFFFBBC05), // Yellow
      Color(0xFF34A853), // Green
    ];
    // Start from ~-15° (approx right-side cutout start in radians)
    const startAngle = -0.26; // ~-15 deg in radians

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    double angle = startAngle;
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        angle,
        sweepAngles[i],
        false,
        paint,
      );
      angle += sweepAngles[i] + 0.10; // 0.10 rad gap between segments
    }

    // Draw the horizontal bar of the "G"
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barLeft = center.dx; // starts at center
    final barRight = center.dx + radius * 0.72;
    final barTop = center.dy - size.height * 0.11;
    final barBottom = center.dy + size.height * 0.11;
    canvas.drawRect(
      Rect.fromLTRB(barLeft, barTop, barRight, barBottom),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
