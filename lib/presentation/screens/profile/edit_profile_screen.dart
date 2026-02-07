import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/core/services/cloudinary_service.dart';
import 'package:gozapper/core/utils/snackbar_utils.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:gozapper/presentation/widgets/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  String _phoneNumber = '';
  bool _hasChanges = false;
  File? _selectedImage;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  final _imagePicker = ImagePicker();
  final _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');

    // Store the original phone number and normalize it
    _phoneNumber = _normalizePhoneNumber(user?.phoneNumber ?? '');

    // Extract just the national number (without country code) for the controller
    final nationalNumber = _extractNationalNumber(user?.phoneNumber);
    _phoneController = TextEditingController(text: nationalNumber);

    // Listen for changes
    _firstNameController.addListener(_checkForChanges);
    _lastNameController.addListener(_checkForChanges);
  }

  String _getCountryCode(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return 'US';

    // Remove spaces and any non-digit characters except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Common country codes
    if (cleaned.startsWith('+234')) return 'NG'; // Nigeria
    if (cleaned.startsWith('+1')) return 'US'; // US/Canada
    if (cleaned.startsWith('+44')) return 'GB'; // UK
    if (cleaned.startsWith('+33')) return 'FR'; // France
    if (cleaned.startsWith('+91')) return 'IN'; // India
    if (cleaned.startsWith('+254')) return 'KE'; // Kenya
    if (cleaned.startsWith('+27')) return 'ZA'; // South Africa

    return 'US'; // Default to US
  }

  String _extractNationalNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return '';

    // Remove spaces and any non-digit characters except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove common country codes
    if (cleaned.startsWith('+234')) return cleaned.substring(4); // Nigeria
    if (cleaned.startsWith('+1')) return cleaned.substring(2); // US/Canada
    if (cleaned.startsWith('+44')) return cleaned.substring(3); // UK
    if (cleaned.startsWith('+33')) return cleaned.substring(3); // France
    if (cleaned.startsWith('+91')) return cleaned.substring(3); // India
    if (cleaned.startsWith('+254')) return cleaned.substring(4); // Kenya
    if (cleaned.startsWith('+27')) return cleaned.substring(3); // South Africa

    // If no country code found, return as is
    return cleaned.replaceAll('+', '');
  }

  /// Normalizes phone number by removing leading 0 after country code
  /// e.g., +23409067468544 -> +2349067468544
  String _normalizePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;

    // Remove spaces and non-digit characters except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check for Nigerian numbers with extra 0: +234 0...
    if (cleaned.startsWith('+2340')) {
      return '+234${cleaned.substring(5)}'; // Remove the 0 after 234
    }

    // Check for other common patterns with leading 0 after country code
    if (cleaned.startsWith('+10')) {
      return '+1${cleaned.substring(3)}'; // US/Canada
    }
    if (cleaned.startsWith('+440')) {
      return '+44${cleaned.substring(4)}'; // UK
    }
    if (cleaned.startsWith('+330')) {
      return '+33${cleaned.substring(4)}'; // France
    }
    if (cleaned.startsWith('+910')) {
      return '+91${cleaned.substring(4)}'; // India
    }
    if (cleaned.startsWith('+2540')) {
      return '+254${cleaned.substring(5)}'; // Kenya
    }
    if (cleaned.startsWith('+270')) {
      return '+27${cleaned.substring(4)}'; // South Africa
    }

    return cleaned;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final hasChanges = _firstNameController.text.trim() != user.firstName ||
        _lastNameController.text.trim() != user.lastName ||
        _phoneNumber != user.phoneNumber;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingImage = true;
          _hasChanges = true;
        });

        // Upload to Cloudinary
        final imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);

        if (imageUrl != null) {
          setState(() {
            _uploadedImageUrl = imageUrl;
            _isUploadingImage = false;
          });
          // if (mounted) {
          //   SnackBarUtils.showSuccess(context, 'Photo uploaded successfully!');
          // }
        } else {
          setState(() {
            _selectedImage = null;
            _isUploadingImage = false;
          });
          if (mounted) {
            SnackBarUtils.showError(context, 'Failed to upload photo');
          }
        }
      }
    } catch (e) {
      setState(() {
        _selectedImage = null;
        _isUploadingImage = false;
      });
      if (mounted) {
        SnackBarUtils.showError(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> _handleSave() async {
    context.hideKeyboard();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneNumber,
      photoUrl: _uploadedImageUrl,
    );

    if (!mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(
        context,
        'Profile updated successfully!',
      );
      context.pop();
    } else {
      SnackBarUtils.showError(
        context,
        authProvider.errorMessage ?? 'Failed to update profile',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Edit Profile'),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return GestureDetector(
            onTap: context.hideKeyboard,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar with image picker
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _isUploadingImage ? null : _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (authProvider.user?.photoUrl != null &&
                                          authProvider
                                              .user!.photoUrl!.isNotEmpty
                                      ? NetworkImage(
                                          authProvider.user!.photoUrl!)
                                      : null) as ImageProvider?,
                              child: _isUploadingImage
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.white),
                                    )
                                  : (_selectedImage == null &&
                                          (authProvider.user?.photoUrl ==
                                                  null ||
                                              authProvider
                                                  .user!.photoUrl!.isEmpty))
                                      ? Text(
                                          authProvider.user?.firstName
                                                      .isNotEmpty ==
                                                  true
                                              ? authProvider.user!.firstName[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                        )
                                      : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingImage ? null : _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // First Name Field
                    CustomTextField(
                      labelText: 'First Name',
                      controller: _firstNameController,
                      hintText: 'Enter your first name',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        if (value.trim().length < 2) {
                          return 'First name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Last Name Field
                    CustomTextField(
                      labelText: 'Last Name',
                      controller: _lastNameController,
                      hintText: 'Enter your last name',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your last name';
                        }
                        if (value.trim().length < 2) {
                          return 'Last name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Phone Number Field
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntlPhoneField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      initialCountryCode:
                          _getCountryCode(authProvider.user?.phoneNumber),
                      onChanged: (phone) {
                        // Normalize phone number to remove extra 0 after country code
                        _phoneNumber =
                            _normalizePhoneNumber(phone.completeNumber);
                        _checkForChanges();
                      },
                      validator: (phone) {
                        if (phone == null || phone.completeNumber.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email (Read-only)
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.border.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authProvider.user?.email ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.lock_outline,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'Email cannot be changed',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading || !_hasChanges
                            ? null
                            : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.border,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 56,
                    //   child: OutlinedButton(
                    //     onPressed:
                    //         authProvider.isLoading ? null : () => context.pop(),
                    //     style: OutlinedButton.styleFrom(
                    //       side: const BorderSide(color: AppColors.border),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //     ),
                    //     child: const Text(
                    //       'Cancel',
                    //       style: TextStyle(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w600,
                    //         color: AppColors.textPrimary,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
