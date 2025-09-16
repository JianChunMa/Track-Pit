import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/user_services.dart';
import '../../models/user.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  final _userService = UserService();

  bool _showPwd = false;
  bool _rememberMe = false; // (mostly relevant on web)
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_loading) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _pwdCtrl.text.trim();

    try {
      // Optional provider pre-check (uncomment if you want this UX)
      // final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      // if (methods.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('No account found. Please sign up.')),
      //   );
      //   return;
      // }
      // if (methods.contains('google.com') && !methods.contains('password')) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('This email uses Google Sign-In. Use “Login with Google”.')),
      //   );
      //   return;
      // }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      final msg = _mapAuthError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Google sign-in (forces account chooser each time)
  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final googleSignIn = GoogleSignIn();

      // Ensure previous session is cleared so user can select a different account
      try {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      } catch (_) {
        // ignore if not previously signed in
      }

      // Trigger account picker
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user cancelled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw Exception('Google sign-in failed (no user)');
      }

      final isNew = result.additionalUserInfo?.isNewUser ?? false;

      if (isNew) {
        final model = UserModel(
          uid: user.uid,
          fullName: user.displayName ?? 'User',
          email: (user.email ?? '').toLowerCase(),
          createdAt: DateTime.now(),
          points: 0,
          hasCompletedVehicleSetup: false,
          vehicleCount: 0,
        );
        await _userService.createUserDoc(model);
      } else {
        await _userService.ensureUserDoc(
          uid: user.uid,
          fullName: user.displayName ?? 'User',
          email: (user.email ?? '').toLowerCase(),
        );
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method.',
        'invalid-credential' => 'Invalid credentials. Try again.',
        'operation-not-allowed' => 'Google sign-in is disabled for this project.',
        'user-disabled' => 'This account has been disabled.',
        _ => e.message ?? 'Google sign-in failed.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const topH = 260.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ===== MAIN CONTENT =====
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: media.size.height - media.padding.vertical,
                ),
                child: Column(
                  children: [
                    // =================== HEADER ===================
                    SizedBox(
                      height: topH,
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ClipPath(
                              clipper: _BottomWaveClipper(),
                              child: Container(color: AppColors.primaryGreen),
                            ),
                          ),
                          Positioned(
                            top: 24,
                            left: -48,
                            child: _circle(130, AppColors.secondaryGreen),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: Stack(
                              clipBehavior: Clip.hardEdge, // hides overflow
                              children: [
                                Positioned(
                                  top: -35,
                                  right: -36,
                                  child: _circle(120, AppColors.secondaryGreen),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, -0.1),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    // keep your current path if already declared in pubspec
                                    'lib/assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'TrackPit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =================== FORM ===================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            'Sign In',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 18),

                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _RoundedField(
                                  controller: _emailCtrl,
                                  hint: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter your email';
                                    }
                                    final ok = RegExp(
                                      r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$',
                                    ).hasMatch(v);
                                    return ok ? null : 'Enter a valid email';
                                  },
                                ),
                                const SizedBox(height: 12),
                                _RoundedField(
                                  controller: _pwdCtrl,
                                  hint: 'Password',
                                  obscureText: !_showPwd,
                                  textInputAction: TextInputAction.done,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showPwd
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () =>
                                        setState(() => _showPwd = !_showPwd),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter your password'
                                      : null,
                                ),
                                const SizedBox(height: 8),

                                // remember + forgot
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (v) => setState(
                                                  () => _rememberMe = v ?? false,
                                            ),
                                            activeColor:
                                            AppColors.primaryGreen,
                                            materialTapTargetSize:
                                            MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          const Text('Remember me'),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final email = _emailCtrl.text.trim();
                                          if (email.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Enter your email first',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          try {
                                            await FirebaseAuth.instance
                                                .sendPasswordResetEmail(
                                              email: email,
                                            );
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Password reset email sent',
                                                ),
                                              ),
                                            );
                                          } on FirebaseAuthException catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(_mapAuthError(e)),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('Forgot Password?'),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // primary button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      elevation: 0,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: _loading ? null : _submit,
                                    child: const Text('Login'),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Expanded(child: Divider(thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const Expanded(child: Divider(thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Google sign in button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.black.withOpacity(.15),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                foregroundColor: Colors.black87,
                                backgroundColor: Colors.white,
                              ),
                              onPressed: _loading ? null : _signInWithGoogle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'lib/assets/images/google_logo.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Login with Google',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          // footer link
                          Text.rich(
                            TextSpan(
                              text: "Don't have an account? ",
                              style: const TextStyle(color: Colors.black54),
                              children: [
                                TextSpan(
                                  text: 'Sign Up!',
                                  style: TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushNamed(context, '/signup');
                                    },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== LOADING OVERLAY =====
          if (_loading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withOpacity(0.15),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// Rounded field used in signup/signin
class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const _RoundedField({
    Key? key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
    this.textInputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F3F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffix,
      ),
    );
  }
}

// Wave clipper
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()..lineTo(0, size.height - 40);
    p.quadraticBezierTo(
      size.width * .25,
      size.height,
      size.width * .5,
      size.height - 24,
    );
    p.quadraticBezierTo(
      size.width * .75,
      size.height - 48,
      size.width,
      size.height - 10,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
