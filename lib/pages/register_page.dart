import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ============================================================
  // APP COLOURS
  // ============================================================

  static const Color primary = Color(0xFF165B5D);
  static const Color secondary = Color(0xFFF46627);
  static const Color background = Color(0xFFF4EEE1);

  static const Color fieldBackground = Color(0xFFFFFCF7);
  static const Color textColor = Color(0xFF1C2727);
  static const Color mutedText = Color(0xFF77766F);
  static const Color borderColor = Color(0xFFD8D2C8);

  // ============================================================
  // FORM
  // ============================================================

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRole;

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTRATION
  // ============================================================

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Privacy Policy.'),
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.register(
        name: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole!,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/complete-profile',
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create the account. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // FIELD DECORATION
  // ============================================================

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Color(0xFF8B8982),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),

      filled: true,
      fillColor: fieldBackground,

      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),

      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 5, right: 3),
        child: Icon(icon, color: primary, size: 21),
      ),

      suffixIcon: suffix,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: secondary, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: secondary, width: 1.5),
      ),
    );
  }

  // ============================================================
  // PAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                // ==================================================
                // TOP BAR
                // ==================================================
                Row(
                  children: [
                    _BackButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),

                    const Spacer(),

                    // Simple brand accent
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ==================================================
                // HEADING
                // ==================================================
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,

                  child: RichText(
                    maxLines: 1,
                    textAlign: TextAlign.center,

                    text: const TextSpan(
                      style: TextStyle(
                        color: textColor,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                      ),

                      children: [
                        TextSpan(text: 'Create your '),

                        TextSpan(
                          text: 'account',
                          style: TextStyle(color: secondary),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Join the Tourism Portal and start planning your next experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // FORM CARD
                // ==================================================
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),

                    borderRadius: BorderRadius.circular(28),

                    border: Border.all(color: Colors.white, width: 1),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.045),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      // ============================================
                      // FULL NAME
                      // ============================================
                      const _FieldLabel(label: 'Full Name'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _fullNameController,

                        textCapitalization: TextCapitalization.words,

                        textInputAction: TextInputAction.next,

                        autofillHints: const [AutofillHints.name],

                        decoration: _fieldDecoration(
                          hint: 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                        ),

                        validator: (value) {
                          final name = value?.trim() ?? '';

                          if (name.isEmpty) {
                            return 'Please enter your full name.';
                          }

                          if (name.length < 3) {
                            return 'Name must have at least 3 characters.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ============================================
                      // EMAIL
                      // ============================================
                      const _FieldLabel(label: 'Email Address'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _emailController,

                        keyboardType: TextInputType.emailAddress,

                        textInputAction: TextInputAction.next,

                        autofillHints: const [AutofillHints.email],

                        decoration: _fieldDecoration(
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                        ),

                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Please enter your email address.';
                          }

                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Please enter a valid email address.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ============================================
                      // ACCOUNT TYPE
                      // ============================================
                      const _FieldLabel(label: 'Account Type'),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        isExpanded: true,

                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primary,
                        ),

                        decoration: _fieldDecoration(
                          hint: 'Select your account type',
                          icon: Icons.badge_outlined,
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 'tourist',
                            child: Text('Tourist'),
                          ),

                          DropdownMenuItem(
                            value: 'tourist_guide',
                            child: Text('Tourist Guide'),
                          ),

                          DropdownMenuItem(
                            value: 'tour_operator',
                            child: Text('Tour Operator'),
                          ),
                        ],

                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your account type.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 7),

                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Administrator accounts are created by the platform.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ============================================
                      // PASSWORD
                      // ============================================
                      const _FieldLabel(label: 'Password'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,

                        obscureText: _hidePassword,

                        textInputAction: TextInputAction.next,

                        autofillHints: const [AutofillHints.newPassword],

                        decoration: _fieldDecoration(
                          hint: 'Create a password',

                          icon: Icons.lock_outline_rounded,

                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },

                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,

                              color: mutedText,
                              size: 21,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please create a password.';
                          }

                          if (value.length < 8) {
                            return 'Password must have at least 8 characters.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ============================================
                      // CONFIRM PASSWORD
                      // ============================================
                      const _FieldLabel(label: 'Confirm Password'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _confirmPasswordController,

                        obscureText: _hideConfirmPassword,

                        textInputAction: TextInputAction.done,

                        onFieldSubmitted: (_) {
                          _submitRegistration();
                        },

                        decoration: _fieldDecoration(
                          hint: 'Enter your password again',

                          icon: Icons.verified_user_outlined,

                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                _hideConfirmPassword = !_hideConfirmPassword;
                              });
                            },

                            icon: Icon(
                              _hideConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,

                              color: mutedText,
                              size: 21,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }

                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 13),

                      // ============================================
                      // TERMS
                      // ============================================
                      InkWell(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },

                        borderRadius: BorderRadius.circular(12),

                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,

                                child: Checkbox(
                                  value: _acceptTerms,

                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },

                                  activeColor: primary,

                                  checkColor: Colors.white,

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),

                                  side: const BorderSide(
                                    color: borderColor,
                                    width: 1.4,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 11),

                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Text(
                                    'I agree to the Terms of Service and Privacy Policy.',
                                    style: TextStyle(
                                      color: mutedText,
                                      fontSize: 11.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 17),

                      // ============================================
                      // CREATE ACCOUNT BUTTON
                      // ============================================
                      _CreateAccountButton(
                        loading: _isSubmitting,
                        onPressed: _submitRegistration,
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // LOGIN
                // ==================================================
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: mutedText, fontSize: 13),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },

                      style: TextButton.styleFrom(
                        foregroundColor: secondary,

                        padding: const EdgeInsets.symmetric(horizontal: 7),
                      ),

                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// FIELD LABEL
// ================================================================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF263333),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ================================================================
// BACK BUTTON
// ================================================================

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFCF7),
      shape: const CircleBorder(),

      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),

        child: Container(
          width: 45,
          height: 45,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(color: const Color(0xFFD8D2C8)),
          ),

          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF263333),
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CREATE ACCOUNT BUTTON
// ================================================================

class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,

      child: DecoratedBox(
        decoration: BoxDecoration(
          // Darker premium 180° gradient
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF165B5D), Color(0xFF0A3D3F)],
          ),

          // Full pill radius
          borderRadius: BorderRadius.circular(100),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Material(
          color: Colors.transparent,

          borderRadius: BorderRadius.circular(100),

          child: InkWell(
            onTap: loading ? null : onPressed,

            borderRadius: BorderRadius.circular(100),

            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 6, 5),

              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        loading ? 'Creating Account...' : 'Create Account',

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: 40,
                    height: 40,

                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),

                    alignment: Alignment.center,

                    child:
                        loading
                            ? const SizedBox(
                              width: 16,
                              height: 16,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF165B5D),
                              ),
                            )
                            : const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: 19,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
