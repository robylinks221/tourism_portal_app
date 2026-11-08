import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/supported_countries.dart';
import '../config/world_countries.dart';
import '../models/auth_user.dart';
import '../models/catalog_item.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../services/session_navigation.dart';
import '../utils/text_case.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  static const _callingCodes = {
    'Uganda': '+256',
    'Rwanda': '+250',
    'Kenya': '+254',
    'Tanzania': '+255',
  };
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _biographyController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  final _languagesController = TextEditingController();
  final _yearsExperienceController = TextEditingController();

  String? _country;
  String? _gender;
  String? _profilePhoto;
  String? _coverImage;
  String? _companyLogo;
  final List<String?> _gallery = [null, null, null];
  List<CatalogItem> _activities = const [];
  List<CatalogItem> _destinations = const [];
  final Set<int> _selectedActivities = {};
  final Set<int> _selectedDestinations = {};
  final Set<String> _selectedOperatingCountries = {};
  bool _submitting = false;
  bool _loading = false;
  bool _catalogLoading = false;
  String? _loadError;

  AuthUser? get _user => AuthService.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final user = _user;
    if (user != null) {
      _nameController.text = user.name;
      _contactPersonController.text = user.name;
    }
    if (user?.role == 'tourist_guide' || user?.role == 'tour_operator') {
      _loadCatalog();
    }
    if (widget.isEditing) _loadProfile();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _catalogLoading = true;
      _loadError = null;
    });
    try {
      final catalog = await CatalogService.instance.fetchCatalog();
      if (mounted)
        setState(() {
          _activities = catalog.activities;
          _destinations = catalog.destinations;
          _catalogLoading = false;
        });
    } on ApiException catch (error) {
      if (mounted)
        setState(() {
          _catalogLoading = false;
          _loadError = error.message;
        });
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final profile = await AuthService.instance.fetchProfile();
      if (!mounted) return;

      final socialLinks = profile['social_links'];
      final social =
          socialLinks is Map
              ? Map<String, dynamic>.from(socialLinks)
              : <String, dynamic>{};
      final country = profile['country']?.toString();
      final phone = profile['phone']?.toString() ?? '';
      final isTourist = _user?.role == 'tourist';
      final code = _callingCodes[country] ?? '';

      setState(() {
        _country = country;
        _phoneController.text =
            isTourist
                ? phone
                : phone.startsWith(code)
                ? phone.substring(code.length)
                : phone;
        _nameController.text =
            profile['full_name']?.toString() ?? _nameController.text;
        _gender = profile['gender']?.toString();
        _biographyController.text = profile['biography']?.toString() ?? '';
        _companyNameController.text = profile['company_name']?.toString() ?? '';
        _contactPersonController.text =
            profile['contact_person']?.toString() ??
            _contactPersonController.text;
        _addressController.text = profile['address']?.toString() ?? '';
        _descriptionController.text =
            profile['company_description']?.toString() ?? '';
        _facebookController.text = social['facebook']?.toString() ?? '';
        _instagramController.text = social['instagram']?.toString() ?? '';
        _xController.text = social['x']?.toString() ?? '';
        _languagesController.text = _stringList(
          profile['languages'],
        ).join(', ');
        final years = int.tryParse(
          profile['years_experience']?.toString() ?? '',
        );
        _yearsExperienceController.text = years == null ? '' : '$years';
        _profilePhoto = _storedImage(profile['profile_photo']);
        _coverImage = _storedImage(profile['cover_image']);
        _companyLogo = _storedImage(profile['company_logo']);

        _selectedActivities
          ..clear()
          ..addAll(_intList(profile['activity_ids']));
        _selectedDestinations
          ..clear()
          ..addAll(_intList(profile['destination_ids']));

        final operatingCountries =
            _stringList(
              profile['operating_countries'],
            ).where(TourismCountries.isSupported).toList();

        _selectedOperatingCountries
          ..clear()
          ..addAll(
            operatingCountries.isNotEmpty
                ? operatingCountries
                : [
                  if (country != null && TourismCountries.isSupported(country))
                    country,
                ],
          );

        final gallery = _stringList(profile['gallery']);
        for (var index = 0; index < _gallery.length; index++) {
          _gallery[index] =
              index < gallery.length
                  ? AuthService.storageUrl(gallery[index])
                  : null;
        }
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error.message;
        });
      }
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  List<int> _intList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
  }

  String? _storedImage(dynamic value) {
    final path = value?.toString().trim() ?? '';
    return path.isEmpty ? null : AuthService.storageUrl(path);
  }

  bool _isLocalImage(String? path) {
    return path != null &&
        !path.startsWith('http://') &&
        !path.startsWith('https://');
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _phoneController,
      _biographyController,
      _companyNameController,
      _contactPersonController,
      _addressController,
      _descriptionController,
      _facebookController,
      _instagramController,
      _xController,
      _languagesController,
      _yearsExperienceController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _roleTitle {
    if (widget.isEditing) return 'Edit account';
    switch (_user?.role) {
      case 'tourist_guide':
        return 'Complete guide profile';
      case 'tour_operator':
        return 'Complete company profile';
      default:
        return 'Complete tourist profile';
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _url(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Enter a complete link beginning with https://';
    }
    return null;
  }

  Future<void> _pickImage(ValueChanged<String> onPicked) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2200,
    );
    if (image != null && mounted) {
      setState(() => onPicked(image.path));
    }
  }

  String? _imageError() {
    switch (_user?.role) {
      case 'tourist_guide':
        if (_selectedOperatingCountries.isEmpty) {
          return 'Please select at least one country where you operate.';
        }
        if (_coverImage == null) return 'Please select a cover image.';
        if (_profilePhoto == null) return 'Please select a profile picture.';
        if (_gallery.any((image) => image == null)) {
          return 'Please select exactly three gallery images.';
        }
        if (_selectedActivities.isEmpty) {
          return 'Please select at least one safari activity.';
        }
        if (_selectedDestinations.isEmpty) {
          return 'Please select at least one destination.';
        }
        return null;
      case 'tour_operator':
        if (_selectedOperatingCountries.isEmpty) {
          return 'Please select at least one country where your company operates.';
        }
        if (_coverImage == null) return 'Please select a cover image.';
        if (_companyLogo == null) return 'Please select a company logo.';
        if (_selectedActivities.isEmpty)
          return 'Please select at least one safari activity.';
        if (_selectedDestinations.isEmpty)
          return 'Please select at least one destination.';
        return null;
      default:
        return _profilePhoto == null
            ? 'Please select a profile picture.'
            : null;
    }
  }

  Map<String, String> _socialLinks() {
    return {
      if (_facebookController.text.trim().isNotEmpty)
        'social_links[facebook]': _facebookController.text.trim(),
      if (_instagramController.text.trim().isNotEmpty)
        'social_links[instagram]': _instagramController.text.trim(),
      if (_xController.text.trim().isNotEmpty)
        'social_links[x]': _xController.text.trim(),
    };
  }

  String get _completePhone {
    if (_user?.role == 'tourist') {
      return _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    }

    final localNumber = _phoneController.text.trim().replaceFirst(
      RegExp(r'^0+'),
      '',
    );

    return '${_callingCodes[_country]}$localNumber';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_submitting || !_formKey.currentState!.validate()) return;

    final imageError = _imageError();
    if (imageError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(imageError)));
      return;
    }

    setState(() => _submitting = true);

    final role = _user!.role;
    final fields = <String, String>{
      'country': _country!,
      'phone': _completePhone,
    };
    final files = <String, String>{};
    final fileLists = <String, List<String>>{};
    final listFields = <String, List<String>>{};

    if (role == 'tourist') {
      fields['full_name'] = _nameController.text.trim();
      if (_isLocalImage(_profilePhoto)) {
        files['profile_photo'] = _profilePhoto!;
      }
    } else if (role == 'tourist_guide') {
      fields.addAll({
        'full_name': _nameController.text.trim(),
        'gender': _gender!,
        'biography': _biographyController.text.trim(),
        'years_experience': _yearsExperienceController.text.trim(),
        ..._socialLinks(),
      });
      if (_isLocalImage(_profilePhoto)) {
        files['profile_photo'] = _profilePhoto!;
      }
      if (_isLocalImage(_coverImage)) {
        files['cover_image'] = _coverImage!;
      }
      if (widget.isEditing) {
        for (var index = 0; index < _gallery.length; index++) {
          if (_isLocalImage(_gallery[index])) {
            files['gallery_$index'] = _gallery[index]!;
          }
        }
      } else {
        fileLists['gallery'] = _gallery.cast<String>();
      }
      listFields['activity_ids'] =
          _selectedActivities.map((id) => '$id').toList();
      listFields['destination_ids'] =
          _selectedDestinations.map((id) => '$id').toList();
      listFields['languages'] = _professionalLanguages();
      listFields['operating_countries'] = _orderedOperatingCountries();
    } else {
      fields.addAll({
        'company_name': _companyNameController.text.trim(),
        'contact_person': _contactPersonController.text.trim(),
        'address': _addressController.text.trim(),
        'company_description': _descriptionController.text.trim(),
        'years_experience': _yearsExperienceController.text.trim(),
        ..._socialLinks(),
      });
      if (_isLocalImage(_coverImage)) {
        files['cover_image'] = _coverImage!;
      }
      if (_isLocalImage(_companyLogo)) {
        files['company_logo'] = _companyLogo!;
      }
      listFields['activity_ids'] =
          _selectedActivities.map((id) => '$id').toList();
      listFields['destination_ids'] =
          _selectedDestinations.map((id) => '$id').toList();
      listFields['languages'] = _professionalLanguages();
      listFields['operating_countries'] = _orderedOperatingCountries();
    }

    try {
      final user =
          widget.isEditing
              ? await AuthService.instance.updateProfile(
                fields: fields,
                files: files,
                fileLists: fileLists,
                listFields: listFields,
              )
              : await AuthService.instance.completeProfile(
                fields: fields,
                files: files,
                fileLists: fileLists,
                listFields: listFields,
              );
      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          user.homeRoute,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          user.homeRoute,
          (route) => false,
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session expired.')));
    }

    if (_loading || _catalogLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Account')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (_user?.role == 'tourist_guide' ||
                        _user?.role == 'tour_operator')
                      _loadCatalog();
                    if (widget.isEditing) _loadProfile();
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: widget.isEditing,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.isEditing,
          title: Text(_roleTitle.toTitleCase()),
          actions: [
            if (!widget.isEditing)
              TextButton(
                onPressed:
                    _submitting ? null : () => signOutAndShowLogin(context),
                child: const Text('Sign out'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              _IntroCard(role: user.role, isEditing: widget.isEditing),
              const SizedBox(height: 24),
              if (user.role == 'tourist') _touristFields(user),
              if (user.role == 'tourist_guide') _guideFields(user),
              if (user.role == 'tour_operator') _operatorFields(user),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon:
                    _submitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _submitting
                      ? 'Saving...'
                      : widget.isEditing
                      ? 'Save Changes'
                      : 'Complete Profile',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _touristFields(AuthUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Profile picture'),
        _ImagePickerCard(
          label: 'Select profile picture',
          path: _profilePhoto,
          icon: Icons.account_circle_outlined,
          onTap: () => _pickImage((path) => _profilePhoto = path),
          circular: true,
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Personal information'),
        _textField(
          controller: _nameController,
          label: 'Full names',
          icon: Icons.person_outline_rounded,
          validator: (value) => _required(value, 'Full names'),
        ),
        _touristCountryField(),
        _touristPhoneField(),
        _emailField(user.email),
      ],
    );
  }

  Widget _guideFields(AuthUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Profile images'),
        _ImagePickerCard(
          label: 'Select cover image',
          path: _coverImage,
          icon: Icons.landscape_outlined,
          onTap: () => _pickImage((path) => _coverImage = path),
          height: 150,
        ),
        const SizedBox(height: 12),
        _ImagePickerCard(
          label: 'Select profile picture',
          path: _profilePhoto,
          icon: Icons.account_circle_outlined,
          onTap: () => _pickImage((path) => _profilePhoto = path),
          circular: true,
        ),
        const SizedBox(height: 16),
        Text(
          'Gallery · exactly 3 images',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
                child: _ImagePickerCard(
                  label: '${index + 1}',
                  path: _gallery[index],
                  icon: Icons.add_photo_alternate_outlined,
                  onTap: () => _pickImage((path) => _gallery[index] = path),
                  compact: true,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 26),
        const _SectionTitle('Personal information'),
        _textField(
          controller: _nameController,
          label: 'Full names',
          icon: Icons.person_outline_rounded,
          validator: (value) => _required(value, 'Full names'),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.wc_rounded),
            ),
            items:
                ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _gender = value),
            validator: (value) => _required(value, 'Gender'),
          ),
        ),
        _countryField(),
        _phoneField(),
        _emailField(user.email),
        const SizedBox(height: 12),
        _operatingCountriesField(
          title: 'Countries I operate in',
          helper:
              'Select every country where you can personally guide travellers.',
        ),
        const SizedBox(height: 22),
        _professionalTrustFields(),
        const SizedBox(height: 12),
        const _SectionTitle('Safari activities'),
        _choiceChips(_activities, _selectedActivities),
        const SizedBox(height: 22),
        const _SectionTitle('Destinations'),
        _choiceChips(_destinations, _selectedDestinations),
        const SizedBox(height: 22),
        const _SectionTitle('Biography'),
        _textField(
          controller: _biographyController,
          label: 'Tell tourists about your experience',
          icon: Icons.description_outlined,
          minLines: 4,
          maxLines: 7,
          validator: (value) {
            final required = _required(value, 'Biography');
            if (required != null) return required;
            return value!.trim().length < 30
                ? 'Biography must have at least 30 characters.'
                : null;
          },
        ),
        const SizedBox(height: 8),
        _socialFields(),
      ],
    );
  }

  Widget _operatorFields(AuthUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Company images'),
        _ImagePickerCard(
          label: 'Select cover image',
          path: _coverImage,
          icon: Icons.landscape_outlined,
          onTap: () => _pickImage((path) => _coverImage = path),
          height: 150,
        ),
        const SizedBox(height: 12),
        _ImagePickerCard(
          label: 'Select company logo',
          path: _companyLogo,
          icon: Icons.business_rounded,
          onTap: () => _pickImage((path) => _companyLogo = path),
          circular: true,
        ),
        const SizedBox(height: 26),
        const _SectionTitle('Company information'),
        _textField(
          controller: _companyNameController,
          label: 'Company name',
          icon: Icons.business_outlined,
          validator: (value) => _required(value, 'Company name'),
        ),
        _textField(
          controller: _contactPersonController,
          label: 'Contact person',
          icon: Icons.person_outline_rounded,
          validator: (value) => _required(value, 'Contact person'),
        ),
        _countryField(),
        _phoneField(),
        _emailField(user.email),
        const SizedBox(height: 12),
        _operatingCountriesField(
          title: 'Countries we operate in',
          helper:
              'Select every country where your company can organize safaris.',
        ),
        const SizedBox(height: 22),
        _professionalTrustFields(),
        const SizedBox(height: 12),
        const _SectionTitle('Safari activities'),
        _choiceChips(_activities, _selectedActivities),
        const SizedBox(height: 22),
        const _SectionTitle('Destinations'),
        _choiceChips(_destinations, _selectedDestinations),
        const SizedBox(height: 22),
        _textField(
          controller: _addressController,
          label: 'Company address',
          icon: Icons.location_on_outlined,
          validator: (value) => _required(value, 'Company address'),
        ),
        _textField(
          controller: _descriptionController,
          label: 'Company description',
          icon: Icons.description_outlined,
          minLines: 4,
          maxLines: 7,
          validator: (value) {
            final required = _required(value, 'Company description');
            if (required != null) return required;
            return value!.trim().length < 30
                ? 'Description must have at least 30 characters.'
                : null;
          },
        ),
        const SizedBox(height: 8),
        _socialFields(),
      ],
    );
  }

  Widget _touristCountryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _WorldCountryPickerField(
        value: _country,
        label: 'Country of residence',
        helperText: 'Select the country where you currently live.',
        onChanged: (value) {
          setState(() {
            _country = value;
          });
        },
      ),
    );
  }

  Widget _touristPhoneField() {
    return _textField(
      controller: _phoneController,
      label: 'International telephone number',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: (value) {
        final required = _required(value, 'Telephone number');
        if (required != null) return required;

        final number = value!.trim().replaceAll(RegExp(r'\s+'), '');

        if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(number)) {
          return 'Use international format, for example +256774123456.';
        }

        return null;
      },
    );
  }

  Widget _countryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _country,
        decoration: const InputDecoration(
          labelText: 'Based in',
          prefixIcon: Icon(Icons.public_rounded),
        ),
        items:
            TourismCountries.names
                .map(
                  (country) =>
                      DropdownMenuItem(value: country, child: Text(country)),
                )
                .toList(),
        onChanged:
            (value) => setState(() {
              _country = value;
              _phoneController.clear();

              if (value != null &&
                  (_user?.role == 'tourist_guide' ||
                      _user?.role == 'tour_operator')) {
                _selectedOperatingCountries.add(value);
              }
            }),
        validator: (value) => _required(value, 'Country'),
      ),
    );
  }

  List<String> _orderedOperatingCountries() {
    return TourismCountries.names
        .where(_selectedOperatingCountries.contains)
        .toList();
  }

  Widget _operatingCountriesField({
    required String title,
    required String helper,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title),
        Text(helper, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              TourismCountries.names.map((country) {
                final selected = _selectedOperatingCountries.contains(country);

                return FilterChip(
                  label: Text(country),
                  selected: selected,
                  avatar:
                      selected
                          ? const Icon(Icons.check_rounded, size: 18)
                          : null,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        _selectedOperatingCountries.add(country);
                      } else {
                        _selectedOperatingCountries.remove(country);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        if (_country != null && !_selectedOperatingCountries.contains(_country))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Tip: your home country is $_country. Select it too if you operate safaris there.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.primary),
            ),
          ),
      ],
    );
  }

  Widget _phoneField() {
    return _textField(
      controller: _phoneController,
      label:
          _country == null
              ? 'Telephone number'
              : 'Telephone number (without ${_callingCodes[_country]})',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      prefixText: _country == null ? null : '${_callingCodes[_country]} ',
      validator: (value) {
        final required = _required(value, 'Telephone number');
        if (required != null) return required;
        final digits = value!.replaceAll(RegExp(r'\D'), '');
        return digits.length < 7 || digits.length > 12
            ? 'Enter a valid telephone number.'
            : null;
      },
    );
  }

  Widget _emailField(String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: email,
        enabled: false,
        decoration: const InputDecoration(
          labelText: 'Account email',
          prefixIcon: Icon(Icons.email_outlined),
          helperText: 'Captured from account registration',
        ),
      ),
    );
  }

  Widget _socialFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Social media links · optional'),
        _textField(
          controller: _facebookController,
          label: 'Facebook link',
          icon: Icons.facebook_rounded,
          keyboardType: TextInputType.url,
          validator: _url,
        ),
        _textField(
          controller: _instagramController,
          label: 'Instagram link',
          icon: Icons.camera_alt_outlined,
          keyboardType: TextInputType.url,
          validator: _url,
        ),
        _textField(
          controller: _xController,
          label: 'X / Twitter link',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.url,
          validator: _url,
        ),
      ],
    );
  }

  List<String> _professionalLanguages() {
    return _languagesController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(10)
        .toList();
  }

  Widget _professionalTrustFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Professional trust details'),
        _textField(
          controller: _languagesController,
          label: 'Languages spoken',
          icon: Icons.translate_rounded,
          validator: (value) {
            final required = _required(value, 'Languages spoken');
            if (required != null) return required;
            return _professionalLanguages().isEmpty
                ? 'Enter at least one language.'
                : null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Separate languages with commas, for example English, Luganda, Swahili.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _textField(
          controller: _yearsExperienceController,
          label: 'Years of safari experience',
          icon: Icons.workspace_premium_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {
            final years = int.tryParse(value?.trim() ?? '');
            if (years == null) return 'Enter the number of years.';
            return years < 0 || years > 80
                ? 'Enter a value from 0 to 80.'
                : null;
          },
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(.42),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.admin_panel_settings_outlined, size: 20),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'The verified badge is granted only after an administrator reviews the profile. Editing professional details returns a verified profile to pending review.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _choiceChips(List<CatalogItem> choices, Set<int> selected) {
    if (choices.isEmpty) {
      return const Text(
        'No options have been published by the administrator yet.',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          choices.map((choice) {
            return FilterChip(
              label: Text(choice.name),
              selected: selected.contains(choice.id),
              onSelected:
                  (isSelected) => setState(() {
                    isSelected
                        ? selected.add(choice.id)
                        : selected.remove(choice.id);
                  }),
            );
          }).toList(),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          prefixText: prefixText,
        ),
      ),
    );
  }
}

class _WorldCountryPickerField extends FormField<String> {
  _WorldCountryPickerField({
    required String? value,
    required String label,
    required String helperText,
    required ValueChanged<String> onChanged,
  }) : super(
         initialValue: WorldCountries.isSupported(value) ? value : null,
         validator: (selected) {
           if (selected == null || selected.trim().isEmpty) {
             return 'Country is required.';
           }
           return null;
         },
         builder: (state) {
           const ink = Color(0xFF17211F);
           const primary = Color(0xFF165B5D);
           final selected = WorldCountries.byName(state.value);
           final hasError = state.hasError;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Padding(
                 padding: const EdgeInsets.only(left: 4, bottom: 8),
                 child: Text(
                   label,
                   style: const TextStyle(
                     color: ink,
                     fontSize: 14,
                     fontWeight: FontWeight.w800,
                   ),
                 ),
               ),
               Material(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 child: InkWell(
                   borderRadius: BorderRadius.circular(16),
                   onTap: () async {
                     final country = await showModalBottomSheet<WorldCountry>(
                       context: state.context,
                       isScrollControlled: true,
                       useSafeArea: true,
                       backgroundColor: Colors.transparent,
                       builder: (_) => const _WorldCountryPickerSheet(),
                     );
                     if (country == null) return;
                     state.didChange(country.name);
                     onChanged(country.name);
                   },
                   child: Container(
                     constraints: const BoxConstraints(minHeight: 58),
                     padding: const EdgeInsets.symmetric(
                       horizontal: 14,
                       vertical: 13,
                     ),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(
                         color: hasError
                             ? const Color(0xFFB3261E)
                             : primary.withOpacity(.28),
                       ),
                     ),
                     child: Row(
                       children: [
                         const Icon(Icons.public_rounded, color: primary),
                         const SizedBox(width: 12),
                         Expanded(
                           child: selected == null
                               ? const Text(
                                   'Select your country of residence',
                                   maxLines: 2,
                                   style: TextStyle(
                                     color: ink,
                                     fontSize: 15,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 )
                               : Row(
                                   children: [
                                     _WorldCountryFlag(country: selected),
                                     const SizedBox(width: 10),
                                     Expanded(
                                       child: Text(
                                         selected.name,
                                         maxLines: 2,
                                         overflow: TextOverflow.ellipsis,
                                         style: const TextStyle(
                                           color: ink,
                                           fontSize: 15,
                                           fontWeight: FontWeight.w700,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                         ),
                         const SizedBox(width: 8),
                         const Icon(
                           Icons.keyboard_arrow_down_rounded,
                           color: primary,
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
               Padding(
                 padding: const EdgeInsets.only(left: 4, top: 6),
                 child: Text(
                   state.errorText ?? helperText,
                   style: TextStyle(
                     color: hasError
                         ? const Color(0xFFB3261E)
                         : const Color(0xFF46534F),
                     fontSize: 12,
                   ),
                 ),
               ),
             ],
           );
         },
       );
}

class _WorldCountryPickerSheet extends StatefulWidget {
  const _WorldCountryPickerSheet();

  @override
  State<_WorldCountryPickerSheet> createState() =>
      _WorldCountryPickerSheetState();
}

class _WorldCountryPickerSheetState extends State<_WorldCountryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final countries =
        WorldCountries.all.where((country) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) return true;
          return country.name.toLowerCase().contains(query) ||
              country.code.toLowerCase().contains(query);
        }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      minChildSize: .55,
      maxChildSize: .94,
      builder: (context, controller) {
        return Material(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline.withOpacity(.28),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select your country',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search country',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    countries.isEmpty
                        ? const Center(child: Text('No country found.'))
                        : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: countries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final country = countries[index];
                            return ListTile(
                              onTap: () => Navigator.pop(context, country),
                              leading: _WorldCountryFlag(country: country),
                              title: Text(
                                country.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: Text(
                                country.code,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurface.withOpacity(.48),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorldCountryFlag extends StatelessWidget {
  const _WorldCountryFlag({required this.country});

  final WorldCountry country;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 21,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Image.network(
        country.flagUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const Icon(Icons.flag_outlined, size: 16),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.role, required this.isEditing});

  final String role;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final roleName = switch (role) {
      'tourist_guide' => 'guide',
      'tour_operator' => 'tour operator',
      _ => 'tourist',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF18A999), Color(0xFF117D73)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person_pin_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (isEditing ? 'Keep your details current' : 'One final step')
                      .toTitleCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Update the information shown on your $roleName account.'
                      : 'Complete your $roleName profile before entering the dashboard.',
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toTitleCase(),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w300),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.label,
    required this.path,
    required this.icon,
    required this.onTap,
    this.circular = false,
    this.compact = false,
    this.height = 116,
  });

  final String label;
  final String? path;
  final IconData icon;
  final VoidCallback onTap;
  final bool circular;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRemote =
        path?.startsWith('http://') == true ||
        path?.startsWith('https://') == true;
    final ImageProvider? avatarImage =
        path == null
            ? null
            : isRemote
            ? NetworkImage(path!)
            : FileImage(File(path!));
    final image =
        path == null
            ? null
            : isRemote
            ? Image.network(
              path!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Icon(icon, color: colors.primary),
            )
            : Image.file(
              File(path!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );

    if (circular) {
      return Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(70),
          child: Column(
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: colors.primary.withOpacity(0.10),
                backgroundImage: avatarImage,
                child:
                    path == null
                        ? Icon(icon, size: 42, color: colors.primary)
                        : null,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: compact ? 100 : height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.primary.withOpacity(0.35)),
        ),
        child:
            image ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: colors.primary, size: compact ? 27 : 34),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
