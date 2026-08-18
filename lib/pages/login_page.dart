import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../theme/field_guide_theme.dart';
import 'tourist_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final Future<List<LoginCommunityAvatar>> _communityAvatars;

  bool _hidePassword = true;
  bool _isSubmitting = false;

  static const Color _primary = FieldGuidePalette.primary;
  static const Color _secondary = FieldGuidePalette.secondary;
  static const Color _background = FieldGuidePalette.background;

  @override
  void initState() {
    super.initState();

    _communityAvatars =
        CommunityService.instance.fetchLoginAvatars();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() ||
        _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await AuthService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        user.nextRoute,
            (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to sign in. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
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

  void _continueAsGuest() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const TouristHomePage(
          isGuest: true,
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildLoginPanel(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _primary,
      padding: const EdgeInsets.fromLTRB(
        22,
        10,
        22,
        32,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(.10),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                  ),
                  color: Colors.white,
                  iconSize: 20,
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 26),

          const Text(
            'Explore East Africa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Discover. Connect. Experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.78),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: .1,
            ),
          ),

          const SizedBox(height: 28),

          FutureBuilder<List<LoginCommunityAvatar>>(
            future: _communityAvatars,
            builder: (context, snapshot) {
              return Column(
                children: [
                  _LoginAvatarCluster(
                    avatars: snapshot.data ?? const [],
                    loading:
                    snapshot.connectionState !=
                        ConnectionState.done,
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Meet travellers, guides and local experts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN PANEL
  // ============================================================

  Widget _buildLoginPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        24,
        30,
        24,
        42,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FieldGuidePalette.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Sign in to continue exploring',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FieldGuidePalette.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // EMAIL
            // ==================================================

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.email,
              ],
              decoration: _fieldDecoration(
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Please enter your email address.';
                }

                if (!email.contains('@') ||
                    !email.contains('.')) {
                  return 'Please enter a valid email address.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PASSWORD
            // ==================================================

            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [
                AutofillHints.password,
              ],
              onFieldSubmitted: (_) {
                _submitLogin();
              },
              decoration: _fieldDecoration(
                label: 'Password',
                hint: 'Enter your password',
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
                    color: FieldGuidePalette.mutedText,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password.';
                }

                if (value.length < 8) {
                  return 'Password must have at least 8 characters.';
                }

                return null;
              },
            ),

            const SizedBox(height: 5),

            // ==================================================
            // FORGOT PASSWORD
            // ==================================================

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 8,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password recovery will be added soon.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ==================================================
            // PREMIUM SIGN IN BUTTON
            // SAME DESIGN AS CREATE ACCOUNT BUTTON
            // ==================================================

            _SignInButton(
              loading: _isSubmitting,
              onPressed: _submitLogin,
            ),

            const SizedBox(height: 20),

            // ==================================================
            // GUEST
            // ==================================================

            _buildGuestButton(),

            const SizedBox(height: 26),

            // ==================================================
            // CREATE ACCOUNT
            // ==================================================

            _buildCreateAccountRow(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GUEST BUTTON
  // ============================================================

  Widget _buildGuestButton() {
    return Material(
      color: FieldGuidePalette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap:
        _isSubmitting ? null : _continueAsGuest,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 72,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: FieldGuidePalette.border,
            ),
          ),
          child: const Row(
            children: [
              _GuestIcon(),

              SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue as Guest',
                      style: TextStyle(
                        color: FieldGuidePalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Explore first, create an account later',
                      style: TextStyle(
                        color:
                        FieldGuidePalette.mutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_rounded,
                color: _primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CREATE ACCOUNT ROW
  // ============================================================

  Widget _buildCreateAccountRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Don’t have an account?',
          style: TextStyle(
            color: FieldGuidePalette.mutedText,
            fontSize: 13,
          ),
        ),

        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: _secondary,
            padding: const EdgeInsets.only(
              left: 6,
              right: 4,
            ),
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/register',
            );
          },
          child: const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FIELD DECORATION
  // ============================================================

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      labelStyle: const TextStyle(
        color: FieldGuidePalette.mutedText,
        fontSize: 13,
      ),

      hintStyle: TextStyle(
        color:
        FieldGuidePalette.mutedText.withOpacity(.62),
        fontSize: 13,
      ),

      prefixIcon: Padding(
        padding: const EdgeInsets.all(11),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _primary,
            size: 21,
          ),
        ),
      ),

      prefixIconConstraints: const BoxConstraints(
        minWidth: 64,
        minHeight: 62,
      ),

      suffixIcon: suffix,

      filled: true,
      fillColor: FieldGuidePalette.surface,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: FieldGuidePalette.border,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: FieldGuidePalette.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: _primary,
          width: 1.6,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}

// ================================================================
// PREMIUM SIGN IN BUTTON
// ================================================================

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // 180° darker gradient
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF165B5D),
              Color(0xFF0A3D3F),
            ],
          ),

          // Full pill shape
          borderRadius: BorderRadius.circular(100),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.14),
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
              padding: const EdgeInsets.fromLTRB(
                20,
                5,
                6,
                5,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        loading
                            ? 'Signing In...'
                            : 'Sign In',
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
                    child: loading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(
                          0xFF165B5D,
                        ),
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

// ================================================================
// GUEST ICON
// ================================================================

class _GuestIcon extends StatelessWidget {
  const _GuestIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color:
        FieldGuidePalette.primary.withOpacity(.09),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.travel_explore_rounded,
        color: FieldGuidePalette.primary,
        size: 22,
      ),
    );
  }
}

// ================================================================
// LOGIN AVATAR CLUSTER
// ================================================================

class _LoginAvatarCluster extends StatelessWidget {
  const _LoginAvatarCluster({
    required this.avatars,
    required this.loading,
  });

  final List<LoginCommunityAvatar> avatars;
  final bool loading;

  static const _fallbackColors = [
    FieldGuidePalette.primary,
    FieldGuidePalette.secondary,
    FieldGuidePalette.lake,
    Color(0xFF706477),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label:
      'Profile photos of newly joined guides and tourists',
      child: Center(
        child: SizedBox(
          width: 166,
          height: 60,
          child: ExcludeSemantics(
            child: Stack(
              children: [
                for (
                var index = 0;
                index < 4;
                index++
                )
                  Positioned(
                    left: index * 36,
                    child: _LoginAvatar(
                      profile:
                      index < avatars.length
                          ? avatars[index]
                          : null,
                      background:
                      _fallbackColors[index],
                      loading: loading,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SINGLE LOGIN AVATAR
// ================================================================

class _LoginAvatar extends StatelessWidget {
  const _LoginAvatar({
    required this.profile,
    required this.background,
    required this.loading,
  });

  final LoginCommunityAvatar? profile;
  final Color background;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: background.withOpacity(
        loading ? .45 : 1,
      ),
      alignment: Alignment.center,
      child:
      profile == null
          ? const Icon(
        Icons.person_rounded,
        color: Colors.white70,
        size: 27,
      )
          : Text(
        _initials(profile!.name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    final photoUrl =
        profile?.profilePhotoUrl ?? '';

    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FieldGuidePalette.background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child:
        photoUrl.isEmpty
            ? fallback
            : Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

// ================================================================
// INITIALS
// ================================================================

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where(
        (part) => part.isNotEmpty,
  )
      .take(2);

  return parts
      .map(
        (part) => part[0].toUpperCase(),
  )
      .join();
}