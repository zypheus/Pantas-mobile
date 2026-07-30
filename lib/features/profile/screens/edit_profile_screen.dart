import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/user.dart';
import '../../../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Design tokens matching profile_screen.dart
  static const Color _ink = Color(0xFF0C1130);
  static const Color _inkDeep = Color(0xFF070A1F);
  static const Color _inkSoft = Color(0xFF1B2354);
  static const Color _gold = Color(0xFFE8AC3E);
  static const Color _goldSoft = Color(0xFFF6D290);
  static const Color _parchment = Color(0xFFFBF8F1);
  static const Color _paper = Color(0xFFF4F1E8);
  static const Color _cardLine = Color(0xFFE7E1D0);
  static const Color _slate = Color(0xFF3E4260);
  static const Color _slateSoft = Color(0xFF8A8CA3);
  static const Color _danger = Color(0xFFD9534F);

  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  bool _isLoading = true;
  bool _isSubmitting = false;
  User? _user;

  // Form controllers
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _programController = TextEditingController();
  final _yearLevelController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyPersonController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _emergencyNumberController = TextEditingController();
  final _emergencyAddressController = TextEditingController();
  final _profilePictureReasonController = TextEditingController();

  // Profile picture state
  File? _selectedImage;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _birthdayController.dispose();
    _programController.dispose();
    _yearLevelController.dispose();
    _mobileNumberController.dispose();
    _addressController.dispose();
    _emergencyPersonController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyNumberController.dispose();
    _emergencyAddressController.dispose();
    _profilePictureReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getCurrentUser(refresh: true);
      if (!mounted) return;
      if (user != null) {
        setState(() {
          _user = user;
          _populateForm(user);
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.isUnauthenticated) {
        context.go('/login');
        return;
      }
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Unable to load profile data.');
    }
  }

  void _populateForm(User user) {
    _lastNameController.text = user.lastName ?? '';
    _firstNameController.text = user.firstName ?? '';
    _middleInitialController.text = user.middleInitial ?? '';
    _birthdayController.text = user.birthday ?? '';
    _programController.text = user.course ?? '';
    _yearLevelController.text = user.year ?? '';
    _mobileNumberController.text = user.mobileNumber ?? '';
    _addressController.text = user.address ?? '';
    _emergencyPersonController.text = user.emergencyPerson ?? '';
    _emergencyRelationshipController.text = user.emergencyRelationship ?? '';
    _emergencyNumberController.text = user.emergencyNumber ?? '';
    _emergencyAddressController.text = user.emergencyAddress ?? '';
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Failed to pick image.');
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _inkSoft,
              onPrimary: Colors.white,
              surface: _parchment,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _birthdayController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Build profile update payload
      final profileData = <String, dynamic>{
        'last_name': _lastNameController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'middle_initial': _middleInitialController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'course': _programController.text.trim(),
        'year': _yearLevelController.text.trim(),
        'mobile_number': _mobileNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'emergency_person': _emergencyPersonController.text.trim(),
        'emergency_relationship': _emergencyRelationshipController.text.trim(),
        'emergency_number': _emergencyNumberController.text.trim(),
        'emergency_address': _emergencyAddressController.text.trim(),
      };

      // Remove empty values
      profileData.removeWhere((key, value) => value.isEmpty);

      await _userService.updateProfile(profileData);

      // If profile picture was selected, upload it with reason
      if (_selectedImage != null) {
        final reason = _profilePictureReasonController.text.trim();
        await _userService.updateProfilePicture(
          _selectedImage!,
          reason.isNotEmpty ? reason : 'Profile picture update',
        );
      }

      if (!mounted) return;

      _showSnackBar('Profile updated successfully!');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Failed to update profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _paper,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: _gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _paper,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(),
              const SizedBox(height: 24),

              // Personal Information
              _buildSectionHeader('PERSONAL INFORMATION'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _middleInitialController,
                label: 'Middle Initial',
                icon: Icons.person_outline_rounded,
                maxLength: 2,
              ),
              _buildDateField(
                controller: _birthdayController,
                label: 'Birthday',
                icon: Icons.cake_rounded,
                onTap: _selectDate,
              ),
              _buildTextField(
                controller: _programController,
                label: 'Program / Course',
                icon: Icons.school_rounded,
              ),
              _buildTextField(
                controller: _yearLevelController,
                label: 'Year Level',
                icon: Icons.grade_rounded,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('CONTACT INFORMATION'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _mobileNumberController,
                label: 'Mobile Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home_rounded,
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('EMERGENCY CONTACT'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emergencyPersonController,
                label: 'Emergency Contact Person',
                icon: Icons.contact_emergency_rounded,
              ),
              _buildTextField(
                controller: _emergencyRelationshipController,
                label: 'Relationship',
                icon: Icons.people_outline_rounded,
              ),
              _buildTextField(
                controller: _emergencyNumberController,
                label: 'Emergency Number',
                icon: Icons.phone_in_talk_rounded,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _emergencyAddressController,
                label: 'Emergency Address',
                icon: Icons.location_on_rounded,
                maxLines: 2,
              ),

              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _parchment,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Edit Profile',
        style: GoogleFonts.fraunces(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProfilePictureSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardLine, width: 1),
      ),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _isPickingImage ? null : _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_goldSoft, _gold],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        color: _inkDeep,
                        shape: BoxShape.circle,
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Center(
                              child: Text(
                                _getInitials(),
                                style: GoogleFonts.fraunces(
                                  color: _gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _inkSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to change profile picture',
            style: GoogleFonts.publicSans(
              color: _slateSoft,
              fontSize: 12,
            ),
          ),

          // Reason for changing profile picture
          if (_selectedImage != null) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _profilePictureReasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason for changing profile picture',
                hintText: 'e.g., Updated my photo for a more professional look',
                hintStyle: GoogleFonts.publicSans(
                  color: _slateSoft,
                  fontSize: 13,
                ),
                labelStyle: GoogleFonts.publicSans(
                  color: _slate,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: _paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _cardLine),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _cardLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _gold, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.publicSans(
                color: _ink,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getInitials() {
    final name = _user?.name ?? 'User';
    return name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.publicSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: _slateSoft,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        style: GoogleFonts.publicSans(
          color: _ink,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.publicSans(
            color: _slate,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, size: 20, color: _slateSoft),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _cardLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _cardLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _gold, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _danger, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _danger, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: GoogleFonts.publicSans(
          color: _ink,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.publicSans(
            color: _slate,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, size: 20, color: _slateSoft),
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: _slateSoft,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _cardLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _cardLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _gold, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _inkSoft,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _slateSoft.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'Save Changes',
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}