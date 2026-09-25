import 'package:flutter/material.dart';

import '../models/onboarding_slide.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../theme/field_guide_theme.dart';
import 'tourist_home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const Color _primary = Color(0xFF165B5D);
  static const Color _secondary = Color(0xFFF46627);
  static const Color _background = Color(0xFFF4EEE1);

  // Image overlay colour requested
  static const Color _imageOverlay = Color(0xFF000000);

  static const List<String> _fallbackAssets = [
    'assets/onboarding/discover_uganda.png',
    'assets/onboarding/trusted_guides.png',
    'assets/onboarding/build_safari.png',
  ];

  final PageController _pageController = PageController();

  late final Future<List<OnboardingSlide>> _slidesFuture = _loadSlides();

  int _currentIndex = 0;
  bool _busy = false;

  Future<List<OnboardingSlide>> _loadSlides() async {
    try {
      final slides = await OnboardingService.instance.fetchSlides();

      if (slides.isEmpty) {
        return fallbackOnboardingSlides;
      }

      return List.generate(slides.length, (index) {
        final fallbackIndex =
            index < _fallbackAssets.length ? index : _fallbackAssets.length - 1;

        return slides[index].withFallback(_fallbackAssets[fallbackIndex]);
      });
    } catch (_) {
      return fallbackOnboardingSlides;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markCompleted() async {
    try {
      await OnboardingService.instance.complete();
    } catch (_) {
      // Do not prevent navigation if local storage fails.
    }
  }

  Future<void> _openRegistration() async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    await _markCompleted();

    if (!mounted) return;

    setState(() {
      _busy = false;
    });

    Navigator.pushReplacementNamed(context, '/register');
  }

  Future<void> _openLogin() async {
    if (_busy) return;

    await _markCompleted();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _continueAsGuest() async {
    if (_busy) return;

    await _markCompleted();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const TouristHomePage(isGuest: true),
      ),
      (route) => false,
    );
  }

  Future<void> _skip() async {
    await _continueAsGuest();
  }

  void _nextSlide(int totalSlides) {
    if (_currentIndex >= totalSlides - 1) {
      _openRegistration();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OnboardingSlide>>(
      future: _slidesFuture,
      builder: (context, snapshot) {
        final slides = snapshot.data ?? fallbackOnboardingSlides;

        if (slides.isEmpty) {
          return const Scaffold(
            backgroundColor: _background,
            body: Center(child: CircularProgressIndicator(color: _primary)),
          );
        }

        final safeIndex = _currentIndex < slides.length ? _currentIndex : 0;

        return Scaffold(
          backgroundColor: _background,
          body: Column(
            children: [
              // =====================================================
              // HERO / IMAGE
              // =====================================================
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: slides.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _SlideBackground(slide: slides[index]);
                      },
                    ),

                    // #253D49 image tint / opacity
                    IgnorePointer(
                      child: Container(color: _imageOverlay.withOpacity(0.50)),
                    ),

                    // Additional lower gradient for text readability
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _imageOverlay.withOpacity(0.06),
                              _imageOverlay.withOpacity(0.30),
                              _imageOverlay.withOpacity(0.83),
                            ],
                            stops: const [0.0, 0.42, 0.69, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // HEADER
                    // =================================================
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 15, 18, 0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _secondary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),

                              const SizedBox(width: 12),

                              const Text(
                                'Tourism Portal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),

                              const Spacer(),

                              TextButton(
                                onPressed: _busy ? null : _skip,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Skip',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 1),
                                    Icon(Icons.chevron_right_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // HERO CONTENT
                    // =================================================
                    Positioned(
                      left: 27,
                      right: 27,
                      bottom: 26,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: _HeroContent(
                          key: ValueKey(safeIndex),
                          slide: slides[safeIndex],
                          slideCount: slides.length,
                          currentIndex: safeIndex,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // =====================================================
              // CREAM BOTTOM PANEL
              // =====================================================
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Your journey starts here.',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Let’s make your next adventure amazing.',
                        style: TextStyle(
                          color: FieldGuidePalette.mutedText,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _GetStartedButton(
                        busy: _busy,
                        label:
                            safeIndex == slides.length - 1
                                ? 'Get Started'
                                : 'Next',
                        onPressed: () {
                          _nextSlide(slides.length);
                        },
                      ),

                      const SizedBox(height: 6),

                      _BottomAction(
                        icon: Icons.person_outline_rounded,
                        label: 'Login',
                        onTap: _openLogin,
                      ),

                      Divider(
                        height: 1,
                        thickness: 1,
                        color: FieldGuidePalette.border.withOpacity(0.72),
                      ),

                      _BottomAction(
                        icon: Icons.public_rounded,
                        label: 'Continue as a guest',
                        onTap: _continueAsGuest,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================================
// HERO CONTENT
// =====================================================================

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.slide,
    required this.slideCount,
    required this.currentIndex,
    super.key,
  });

  final OnboardingSlide slide;
  final int slideCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DISCOVER UGANDA',
          style: TextStyle(
            color: FieldGuidePalette.secondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.4,
          ),
        ),

        const SizedBox(height: 10),

        _PremiumTitle(title: slide.title),

        const SizedBox(height: 10),

        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            color: FieldGuidePalette.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(height: 13),

        Text(
          slide.subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            height: 1.48,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 17),

        _SlideIndicators(count: slideCount, selected: currentIndex),
      ],
    );
  }
}

// =====================================================================
// DEFAULT APP FONT TITLE
// =====================================================================

class _PremiumTitle extends StatelessWidget {
  const _PremiumTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final normalized = title.trim().toLowerCase();

    // Custom styling for the third/default safari slide.
    if (normalized == 'build your safari') {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: RichText(
          maxLines: 1,
          text: const TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
            children: [
              TextSpan(text: 'Build Your '),
              TextSpan(
                text: 'Safari',
                style: TextStyle(color: FieldGuidePalette.secondary),
              ),
            ],
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 38,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

// =====================================================================
// PAGE DOTS
// =====================================================================

class _SlideIndicators extends StatelessWidget {
  const _SlideIndicators({required this.count, required this.selected});

  final int count;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final active = index == selected;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 16 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 9),
          decoration: BoxDecoration(
            color:
                active
                    ? FieldGuidePalette.secondary
                    : Colors.white.withOpacity(.85),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

// =====================================================================
// GET STARTED / NEXT BUTTON
// =====================================================================

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Material(
        color: FieldGuidePalette.primary,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.15),

        // Fully rounded/pill ends
        borderRadius: BorderRadius.circular(100),

        child: InkWell(
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 6, 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child:
                      busy
                          ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
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
    );
  }
}

// =====================================================================
// LOGIN / GUEST ROW
// =====================================================================

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Icon(icon, color: FieldGuidePalette.primary, size: 20),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: FieldGuidePalette.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: FieldGuidePalette.primary,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// ADMIN CONTROLLED IMAGE
// =====================================================================

class _SlideBackground extends StatelessWidget {
  const _SlideBackground({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final fallback =
        slide.assetFallback ?? fallbackOnboardingSlides.first.assetFallback!;

    final remoteUrl = AuthService.storageUrl(slide.image);

    if (remoteUrl.isEmpty) {
      return Image.asset(
        fallback,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      remoteUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          fallback,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(fallback, fit: BoxFit.cover),
            Container(color: const Color(0xFF253D49).withOpacity(0.18)),
          ],
        );
      },
    );
  }
}
