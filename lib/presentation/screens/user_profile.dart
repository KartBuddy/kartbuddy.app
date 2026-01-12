import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../auth/login.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/tour_guide_service.dart';
import '../../models/customer_details_model.dart';
import '../../models/auth_models.dart';
import 'customer_home.dart';
import 'customer_wallet.dart';
import 'place_order.dart';
import 'my_orders.dart';
import 'track_order.dart';
import 'place_manager.dart';
import 'support.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String _userName = 'User';
  String _userInitial = 'U';
  String _userFullName = 'User';
  String _userEmail = '';
  
  CustomerDetails? _customerDetails;
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isUploadingPanCard = false;
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedProfileImage;
  File? _selectedPanCardImage;
  
  // Text controllers for editable fields
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _alternateNumberController = TextEditingController();
  final TextEditingController _firstLineAddressController = TextEditingController();
  final TextEditingController _secondLineAddressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _gstNoController = TextEditingController();
  final TextEditingController _panCardNoController = TextEditingController();
  final TextEditingController _adharNoController = TextEditingController();
  
  // Password change controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    // Keep username in sync with first + last name while editing
    _firstNameController.addListener(_updateUserNameFromNames);
    _lastNameController.addListener(_updateUserNameFromNames);
    _loadUserData();
    _loadCustomerDetails();
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_updateUserNameFromNames);
    _lastNameController.removeListener(_updateUserNameFromNames);
    _userNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _alternateNumberController.dispose();
    _firstLineAddressController.dispose();
    _secondLineAddressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _gstNoController.dispose();
    _panCardNoController.dispose();
    _adharNoController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateUserNameFromNames() {
    // Only auto-update when in edit mode so we don't affect initial view state
    if (!_isEditMode) return;
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final combined = [first, last].where((p) => p.isNotEmpty).join(' ');
    _userNameController.text = combined;
  }

  Future<void> _loadUserData() async {
    final displayName = await UserService.getUserDisplayName();
    final fullName = await UserService.getUserFullName();
    final email = await UserService.getUserEmail();
    final initial = await UserService.getUserInitial();
    
    if (mounted) {
      setState(() {
        _userName = displayName;
        _userFullName = fullName;
        _userEmail = email;
        _userInitial = initial;
      });
    }
  }

  Future<void> _loadCustomerDetails() async {
    try {
      final token = await UserService.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      print('🔵 Fetching customer details...');
      final response = await _authService.getCustomerDetails(token);
      
      if (mounted) {
        setState(() {
          _customerDetails = response.data;
          _isLoading = false;
          // Initialize controllers with current values
          _initializeControllers();
        });
      }
    } catch (e) {
      print('❌ Error loading customer details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeControllers() {
    if (_customerDetails != null) {
      _userNameController.text = _customerDetails!.fullName;
      _firstNameController.text = _customerDetails!.firstName;
      _lastNameController.text = _customerDetails!.lastName;
      _companyNameController.text = _customerDetails!.companyName ?? '';
      _alternateNumberController.text = _customerDetails!.alternateNumber ?? '';
      _firstLineAddressController.text = _customerDetails!.firstLineAddress ?? '';
      _secondLineAddressController.text = _customerDetails!.secondLineAddress ?? '';
      _stateController.text = _customerDetails!.state ?? '';
      _cityController.text = _customerDetails!.city ?? '';
      _pinCodeController.text = _customerDetails!.pinCode ?? '';
      _gstNoController.text = _customerDetails!.gstNo ?? '';
      _panCardNoController.text = _customerDetails!.panCardNo ?? '';
      _adharNoController.text = _customerDetails!.adharNo ?? '';
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Reset controllers to original values when canceling edit
        _initializeControllers();
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_customerDetails == null) return;

    // Validate required fields
    if (_userNameController.text.trim().isEmpty) {
      _showSnackBar('User Name is required', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        _showSnackBar('Authentication token not found', isError: true);
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Determine first and last name
      // If User Name is edited, split it; otherwise use individual fields
      String firstName;
      String lastName;
      
      final userName = _userNameController.text.trim();
      final firstNameField = _firstNameController.text.trim();
      final lastNameField = _lastNameController.text.trim();
      
      // Check if User Name was changed from the original full name
      final originalFullName = _customerDetails!.fullName;
      if (userName != originalFullName && userName.isNotEmpty) {
        // User edited the full name, split it
        final userNameParts = userName.split(' ');
        firstName = userNameParts.isNotEmpty ? userNameParts[0] : firstNameField;
        lastName = userNameParts.length > 1 ? userNameParts.sublist(1).join(' ') : (userNameParts.length == 1 ? '' : lastNameField);
      } else {
        // Use individual first/last name fields
        firstName = firstNameField.isNotEmpty ? firstNameField : '';
        lastName = lastNameField;
      }

      // Validate first name
      if (firstName.isEmpty) {
        _showSnackBar('First Name is required', isError: true);
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final request = CustomerUpdateRequest(
        firstName: firstName,
        lastName: lastName,
        companyName: _companyNameController.text.trim().isNotEmpty ? _companyNameController.text.trim() : null,
        panCardNo: _panCardNoController.text.trim().isNotEmpty ? _panCardNoController.text.trim() : null,
        referenceCode: _customerDetails!.referenceCode,
        alternateNumber: _alternateNumberController.text.trim().isNotEmpty ? _alternateNumberController.text.trim() : null,
        firstLineAddress: _firstLineAddressController.text.trim().isNotEmpty ? _firstLineAddressController.text.trim() : null,
        secondLineAddress: _secondLineAddressController.text.trim().isNotEmpty ? _secondLineAddressController.text.trim() : null,
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        pinCode: _pinCodeController.text.trim().isNotEmpty ? _pinCodeController.text.trim() : null,
        gstNo: _gstNoController.text.trim().isNotEmpty ? _gstNoController.text.trim() : null,
        adharNo: _adharNoController.text.trim().isNotEmpty ? _adharNoController.text.trim() : null,
      );

      print('🔵 Updating customer profile...');
      final response = await _authService.updateCustomer(_customerDetails!.customerId, request, token);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditMode = false;
          _customerDetails = response.data;
        });
        _showSnackBar('Profile updated successfully!', isError: false);
        // Update user data in UserService
        final currentCustomer = await UserService.getCustomer();
        final currentToken = await UserService.getToken();
        if (currentCustomer != null && currentToken != null) {
          final updatedCustomer = Customer(
            id: currentCustomer.id,
            email: response.data.email,
            mobileNumber: response.data.mobileNumber,
            fullName: response.data.fullName,
            appRole: currentCustomer.appRole,
          );
          await UserService.saveUserData(updatedCustomer, currentToken);
        }
        _loadUserData();
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showSnackBar('Failed to update profile: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      // Show option to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _selectedProfileImage = File(image.path);
        });
        // Automatically upload the image
        await _uploadProfileImage();
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showSnackBar('Failed to pick image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedProfileImage == null || _customerDetails == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        _showSnackBar('Authentication token not found', isError: true);
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      print('🔵 Uploading profile image...');
      final response = await _authService.uploadProfilePicture(
        _customerDetails!.customerId,
        _selectedProfileImage!,
        token,
      );

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _selectedProfileImage = null;
        });
        _showSnackBar('Profile picture updated successfully!', isError: false);
        // Reload customer details to get updated profile picture
        _loadCustomerDetails();
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        _showSnackBar('Failed to upload image: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  Future<void> _pickPanCardImage() async {
    try {
      // Show option to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _selectedPanCardImage = File(image.path);
        });
        // Automatically upload the image
        await _uploadPanCardImage();
      }
    } catch (e) {
      print('❌ Error picking PAN card image: $e');
      _showSnackBar('Failed to pick image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _uploadPanCardImage() async {
    if (_selectedPanCardImage == null || _customerDetails == null) return;

    setState(() {
      _isUploadingPanCard = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        _showSnackBar('Authentication token not found', isError: true);
        setState(() {
          _isUploadingPanCard = false;
        });
        return;
      }

      print('🔵 Uploading PAN card image...');
      final response = await _authService.uploadPanCardPhoto(
        _customerDetails!.customerId,
        _selectedPanCardImage!,
        token,
      );

      if (mounted) {
        setState(() {
          _isUploadingPanCard = false;
          _selectedPanCardImage = null;
        });
        _showSnackBar('PAN card photo updated successfully!', isError: false);
        // Reload customer details to get updated PAN card photo
        _loadCustomerDetails();
      }
    } catch (e) {
      print('❌ Error uploading PAN card image: $e');
      if (mounted) {
        setState(() {
          _isUploadingPanCard = false;
        });
        _showSnackBar('Failed to upload image: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  void _showChangePasswordDialog() {
    // Reset controllers
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _showCurrentPassword = false;
    _showNewPassword = false;
    _showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Local state for dialog
        bool showCurrentPassword = false;
        bool showNewPassword = false;
        bool showConfirmPassword = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Password
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: !showCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        hintText: 'Enter current password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              showCurrentPassword = !showCurrentPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // New Password
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !showNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNewPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              showNewPassword = !showNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Confirm New Password
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: 'Confirm new password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              showConfirmPassword = !showConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: _isChangingPassword
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isChangingPassword ? null : _changePassword,
                  icon: _isChangingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_isChangingPassword ? 'Changing...' : 'Save Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty) {
      _showSnackBar('Please enter current password', isError: true);
      return;
    }

    if (newPassword.isEmpty) {
      _showSnackBar('Please enter new password', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('New password must be at least 6 characters', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    if (currentPassword == newPassword) {
      _showSnackBar('New password must be different from current password', isError: true);
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        _showSnackBar('Authentication token not found', isError: true);
        setState(() {
          _isChangingPassword = false;
        });
        return;
      }

      print('🔵 Changing password...');
      final response = await _authService.changePassword(
        currentPassword,
        newPassword,
        token,
      );

      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
        Navigator.of(context).pop(); // Close dialog
        _showSnackBar('Password changed successfully!', isError: false);
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      print('❌ Error changing password: $e');
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
        _showSnackBar('Failed to change password: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _restartTour() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Restart App Tour?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          content: const Text(
            'This will show you the guided tour again when you return to the home screen. Would you like to continue?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Restart Tour'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Reset all tour states
      await TourGuideService.resetAllTours();
      
      if (mounted) {
        _showSnackBar('All tours reset! You will see guided tours on each page again.', isError: false);
        
        // Navigate back to home screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const CustomerHome()),
              (route) => false,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        centerTitle: true,
        title: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/Kartbuddy logo v.2.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  'Hi, $_userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userFullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.black87),
                          SizedBox(width: 12),
                          Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Sign out',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) async {
                    if (value == 'profile') {
                      // Already on profile page
                    } else if (value == 'signout') {
                      await UserService.clearUserData();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                ),
              )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title
            const Text(
              'User Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),

            // Profile Photo and Action Buttons Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo with Upload Button
                Stack(
                  children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                        child: _isUploadingImage
                            ? Container(
                                color: const Color(0xFF3B82F6),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              )
                            : _selectedProfileImage != null
                                ? Image.file(
                                    _selectedProfileImage!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : _customerDetails?.profilePicture != null && _customerDetails!.profilePicture!.isNotEmpty
                        ? Image.network(
                            'https://api.kartbuddy.in/${_customerDetails!.profilePicture}',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF3B82F6),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFF3B82F6),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                  ),
                    ),
                    // Upload Button Overlay - Only show in edit mode
                    if (_isEditMode)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickProfileImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Action Buttons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : (_isEditMode ? _saveProfile : _toggleEditMode),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(_isEditMode ? Icons.save : Icons.edit, size: 18),
                          label: Text(_isSaving ? 'Saving...' : (_isEditMode ? 'Save' : 'Edit')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditMode ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _isChangingPassword ? null : _showChangePasswordDialog,
                          icon: const Icon(Icons.lock, size: 18),
                          label: const Text('Change Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: _restartTour,
                          icon: const Icon(Icons.help_outline, size: 18),
                          label: const Text('Restart App Tour'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E88E5),
                            side: const BorderSide(color: Color(0xFF1E88E5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // User Details Section
            _buildSectionTitle('User Details'),
            const SizedBox(height: 16),
            _buildEditableInfoCard('User Name', _userNameController, isReadOnly: true),
            const SizedBox(height: 12),
            _buildInfoCard('Customer ID', _customerDetails?.customerId ?? 'Not provided', isReadOnly: true),
            const SizedBox(height: 12),
            _buildEditableInfoCard('First Name', _firstNameController, required: true),
            const SizedBox(height: 12),
            _buildEditableInfoCard('Last Name', _lastNameController),
            const SizedBox(height: 12),
            _buildInfoCard('App Role', _customerDetails?.appRole ?? 'Not provided', isReadOnly: true),
            const SizedBox(height: 12),
            _buildInfoCard('Mobile Number', _customerDetails?.mobileNumber ?? 'Not provided', isReadOnly: true),
            const SizedBox(height: 12),
            _buildEditableInfoCard('Alternate Mobile Number', _alternateNumberController, isPhoneNumber: true),
            const SizedBox(height: 12),
            _buildInfoCard('Email ID', _customerDetails?.email ?? 'Not provided', isReadOnly: true),
            const SizedBox(height: 12),
            _buildEditableInfoCard('Company Name', _companyNameController),
            const SizedBox(height: 32),

            // Address Information Section
            _buildSectionTitle('Address Information'),
            const SizedBox(height: 16),
            _buildEditableInfoCard('First Line Address', _firstLineAddressController),
            const SizedBox(height: 12),
            _buildEditableInfoCard('Second Line Address', _secondLineAddressController),
            const SizedBox(height: 12),
            _buildEditableInfoCard('State', _stateController),
            const SizedBox(height: 12),
            _buildEditableInfoCard('City', _cityController),
            const SizedBox(height: 12),
            _buildEditableInfoCard('Pincode', _pinCodeController),
            const SizedBox(height: 12),
            _buildEditableInfoCard('GST No.', _gstNoController),
            const SizedBox(height: 32),

            // PAN Card Information Section
            _buildSectionTitle('PAN Card Information'),
            const SizedBox(height: 16),
            _buildEditableInfoCard('PAN Card No.', _panCardNoController),
            const SizedBox(height: 12),
            _buildEditableInfoCard('Aadhar No.', _adharNoController),
            const SizedBox(height: 12),
            // PAN Card Photo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PAN Card Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: _isUploadingPanCard
                            ? Container(
                                color: Colors.grey[100],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                                  ),
                                ),
                              )
                            : _selectedPanCardImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedPanCardImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _customerDetails?.panCardPhoto != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          'https://api.kartbuddy.in/${_customerDetails!.panCardPhoto}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image,
                                                  size: 48,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Failed to load image',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'PAN Card Preview',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                      ),
                      // Upload Button Overlay - Only show in edit mode
                      if (_isEditMode)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _isUploadingPanCard ? null : _pickPanCardImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _customerDetails?.panCardPhoto != null
                              ? Icons.check_circle
                              : Icons.upload,
                          color: _customerDetails?.panCardPhoto != null
                              ? Colors.green[700]
                              : Colors.orange[700],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _customerDetails?.panCardPhoto != null
                              ? 'Uploaded'
                              : 'Not Uploaded',
                          style: TextStyle(
                            fontSize: 14,
                            color: _customerDetails?.panCardPhoto != null
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Financial and Registration Details Section
            _buildSectionTitle('Financial and Registration Details'),
            const SizedBox(height: 16),
            _buildInfoCard('Wallet Balance', '₹${_customerDetails?.walletBalance ?? '0.00'}', isReadOnly: true),
            const SizedBox(height: 12),
            _buildInfoCard('Registration Date', _customerDetails != null ? _customerDetails!.formatDate(_customerDetails!.createdAt) : 'Not provided', isReadOnly: true),
            const SizedBox(height: 12),
            _buildInfoCard('Status', _customerDetails?.status ?? 'Not provided', isReadOnly: true),
            const SizedBox(height: 12),
            _buildInfoCard('Last Updated', _customerDetails != null ? _customerDetails!.formatDateTime(_customerDetails!.updatedAt) : 'Not provided', isReadOnly: true),
            const SizedBox(height: 12),
            _buildInfoCard('Status Remark', _customerDetails?.statusRemarks ?? 'Not provided', isReadOnly: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, {bool required = false, bool isReadOnly = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (required)
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value == 'Not provided' ? Colors.grey[400] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool isPhoneNumber = false,
    bool isReadOnly = false,
  }) {
    final value = controller.text.isEmpty ? 'Not provided' : controller.text;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isEditMode
              ? TextField(
                  controller: controller,
                  readOnly: isReadOnly,
                  keyboardType: isPhoneNumber ? TextInputType.number : TextInputType.text,
                  maxLength: isPhoneNumber ? 10 : null,
                  inputFormatters: isPhoneNumber
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : null,
                  decoration: InputDecoration(
                    hintText: isPhoneNumber ? 'Enter 10-digit mobile number' : 'Enter your details',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isReadOnly ? Colors.grey[300]! : Colors.amber,
                        width: isReadOnly ? 1 : 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isReadOnly ? Colors.grey[300]! : Colors.amber,
                        width: isReadOnly ? 1 : 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isReadOnly ? Colors.grey[300]! : Colors.amber,
                        width: isReadOnly ? 1 : 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    counterText: '', // Hide character counter
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value == 'Not provided' ? Colors.grey[400] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E3A8A),
      child: SafeArea(
        child: Column(
          children: [
            // Collapse button
            Container(
              margin: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Navigation Items
            _buildDrawerItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const CustomerHome()),
                  (route) => false,
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.account_balance_wallet,
              label: 'Wallet',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomerWallet(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.add_circle_outline,
              label: 'Place Order',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PlaceOrder(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.refresh,
              label: 'My Orders',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyOrders(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.location_on,
              label: 'Track Order',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TrackOrder(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.store,
              label: 'Place Manager',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PlaceManager(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.support_agent,
              label: 'Support',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Support(),
                  ),
                );
              },
            ),

            const Spacer(),

            // Copyright
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Kartbuddy © 2025 All Right Reserved\nwith Perennial Global Consultancy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.amber : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

