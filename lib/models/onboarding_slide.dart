class OnboardingSlide {
  const OnboardingSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.sortOrder,
    required this.isActive,
    this.image,
    this.assetFallback,
  });

  final int id;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final int sortOrder;
  final bool isActive;
  final String? image;
  final String? assetFallback;

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    return OnboardingSlide(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      buttonLabel: json['button_label']?.toString() ?? 'Swipe to Explore',
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      image: json['image']?.toString(),
    );
  }

  OnboardingSlide withFallback(String asset) {
    return OnboardingSlide(
      id: id,
      title: title,
      subtitle: subtitle,
      buttonLabel: buttonLabel,
      sortOrder: sortOrder,
      isActive: isActive,
      image: image,
      assetFallback: asset,
    );
  }
}

const fallbackOnboardingSlides = [
  OnboardingSlide(
    id: -1,
    title: 'Discover Uganda',
    subtitle: 'Unforgettable places, all in one journey.',
    buttonLabel: 'Swipe to Explore',
    sortOrder: 0,
    isActive: true,
    assetFallback: 'assets/onboarding/discover_uganda.png',
  ),
  OnboardingSlide(
    id: -2,
    title: 'Meet Trusted Guides',
    subtitle: 'Connect with verified local experts.',
    buttonLabel: 'Swipe to Explore',
    sortOrder: 1,
    isActive: true,
    assetFallback: 'assets/onboarding/trusted_guides.png',
  ),
  OnboardingSlide(
    id: -3,
    title: 'Build Your Safari',
    subtitle: 'Create a trip designed around you.',
    buttonLabel: 'Get Started',
    sortOrder: 2,
    isActive: true,
    assetFallback: 'assets/onboarding/build_safari.png',
  ),
];
