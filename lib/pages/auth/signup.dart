import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/colors.dart';
import '../../services/user_services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _userService = UserService();
  bool _showPwd = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'Email already in use.';
      case 'invalid-email':        return 'Invalid email address.';
      case 'weak-password':        return 'Password is too weak.';
      case 'operation-not-allowed':return 'Email/password sign-up not enabled.';
      default:                     return e.message ?? 'Could not sign up.';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final pwd = _pwdCtrl.text;

    try {
      // 1) Create auth user
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pwd);

      // 2) Update display name (optional)
      await cred.user?.updateDisplayName(name);

      // 3) Create Firestore user doc
      await _userService.createUserDoc(
        uid: cred.user!.uid,
        fullName: name,
        email: email,
      );

      if (!mounted) return;

      // 4) Go to Home (or SignIn if you prefer)
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_mapAuthError(e))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
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
          // =================== CONTENT ===================
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: media.size.height - media.padding.vertical),
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
                            top: 24, left: -48,
                            child: _circle(130, AppColors.secondaryGreen),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  top: -35, right: -36,
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
                                  width: 90, height: 90,
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
                          horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            'Create Your\nAccount',
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
                                  controller: _nameCtrl,
                                  hint: 'Full Name',
                                  keyboardType: TextInputType.name,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Enter your full name'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                _RoundedField(
                                  controller: _emailCtrl,
                                  hint: 'Email',
                                  keyboardType: TextInputType.emailAddress,
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
                                  suffix: IconButton(
                                    icon: Icon(_showPwd
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () =>
                                        setState(() => _showPwd = !_showPwd),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return 'Min 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _RoundedField(
                                  controller: _confirmCtrl,
                                  hint: 'Confirm Password',
                                  obscureText: !_showConfirm,
                                  suffix: IconButton(
                                    icon: Icon(_showConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(
                                            () => _showConfirm = !_showConfirm),
                                  ),
                                  validator: (v) => (v != _pwdCtrl.text)
                                      ? 'Passwords do not match'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // primary button
                                SizedBox(
                                  width: double.infinity, height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      elevation: 0,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: _submit,
                                    child: const Text('Sign Up'),
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
                                padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('OR',
                                    style: TextStyle(
                                        color: Colors.grey.shade600)),
                              ),
                              const Expanded(child: Divider(thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Google button (not implemented)
                          SizedBox(
                            width: double.infinity, height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.black.withOpacity(.15),
                                    width: 1.2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28)),
                                foregroundColor: Colors.black87,
                                backgroundColor: Colors.white,
                              ),
                              onPressed: () {},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('lib/assets/images/google_logo.png',
                                      width: 20, height: 20),
                                  const SizedBox(width: 10),
                                  const Text('Sign Up with Google',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Text.rich(
                            TextSpan(
                              text: 'Already have an account? ',
                              style: const TextStyle(color: Colors.black54),
                              children: [
                                TextSpan(
                                  text: 'Sign In!',
                                  style: TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushNamed(context, '/signin');
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

          // loading overlay
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

class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _RoundedField({
    Key? key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F3F5),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffix,
      ),
    );
  }
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()..lineTo(0, size.height - 40);
    p.quadraticBezierTo(
        size.width * .25, size.height, size.width * .5, size.height - 24);
    p.quadraticBezierTo(
        size.width * .75, size.height - 48, size.width, size.height - 10);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
