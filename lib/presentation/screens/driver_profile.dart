import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../models/auth_models.dart';
import 'driver_home.dart';

class DriverProfile extends StatefulWidget {
  const DriverProfile({super.key});

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  bool _isEditMode = false;
  bool _isLoading = true;
  DriverProfileDetails? _driverProfile;
  final ImagePicker _imagePicker = ImagePicker();
  final AuthService _authService = AuthService();
  
  // Text controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _alternateNumberController = TextEditingController();
  final TextEditingController _vendorNameController = TextEditingController();
  final TextEditingController _vendorCodeController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _permanentAddressController = TextEditingController();
  final TextEditingController _panCardNumberController = TextEditingController();
  final TextEditingController _aadharCardNumberController = TextEditingController();
  final TextEditingController _drivingLicenseNumberController = TextEditingController();
  final TextEditingController _referCodeController = TextEditingController();
  final TextEditingController _referenceCodeController = TextEditingController();
  final TextEditingController _statusRemarkController = TextEditingController();
  
  // File pickers
  File? _profilePicture;
  File? _localAddressProof;
  File? _aadharFrontPhoto;
  File? _aadharBackPhoto;
  File? _drivingLicensePhoto;
  
  bool _sameAsLocalAddress = false;
  String _selectedHub = 'Vasai DC';
  String _selectedVehicle = 'MH02ED5487';
  String _vehicleType = 'Tempo';
  String _vehicleModel = 'Tata Ace Gold';
  String _status = 'Approved';
  
  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }
  
  Future<void> _loadDriverData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        final response = await _authService.getDriverProfile(token);
        if (response.success && response.data != null) {
          final profile = response.data;
          setState(() {
            _driverProfile = profile;
            _firstNameController.text = profile.firstName;
            _lastNameController.text = profile.lastName;
            _emailController.text = profile.email ?? '';
            _mobileNumberController.text = profile.mobileNumber ?? '';
            _alternateNumberController.text = profile.alternateNumber ?? '';
            _vendorNameController.text = profile.vendorName ?? '';
            _vendorCodeController.text = profile.vendorCode ?? '';
            _addressLine1Controller.text = profile.addressLine1 ?? '';
            _addressLine2Controller.text = profile.addressLine2 ?? '';
            _stateController.text = profile.state ?? '';
            _cityController.text = profile.city ?? '';
            _pincodeController.text = profile.pinCode ?? '';
            _permanentAddressController.text = profile.currentAddress ?? '';
            _panCardNumberController.text = profile.panCardNo ?? '';
            _aadharCardNumberController.text = profile.aadharNo ?? '';
            _drivingLicenseNumberController.text = profile.drivingLicenceNo ?? '';
            _referCodeController.text = profile.referralCode ?? '';
            _referenceCodeController.text = profile.referenceCode ?? 'N/A';
            _statusRemarkController.text = profile.statusRemark ?? '';
            _status = profile.status;
            
            // Format dates
            if (profile.createdAt.isNotEmpty) {
              try {
                final createdDate = DateTime.parse(profile.createdAt);
                // Format as needed
              } catch (e) {
                // Handle date parsing error
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading driver profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          switch (type) {
            case 'profile':
              _profilePicture = File(image.path);
              break;
            case 'localAddress':
              _localAddressProof = File(image.path);
              break;
            case 'aadharFront':
              _aadharFrontPhoto = File(image.path);
              break;
            case 'aadharBack':
              _aadharBackPhoto = File(image.path);
              break;
            case 'drivingLicense':
              _drivingLicensePhoto = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _alternateNumberController.dispose();
    _vendorNameController.dispose();
    _vendorCodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _permanentAddressController.dispose();
    _panCardNumberController.dispose();
    _aadharCardNumberController.dispose();
    _drivingLicenseNumberController.dispose();
    _referCodeController.dispose();
    _referenceCodeController.dispose();
    _statusRemarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                onPressed: () {
                  setState(() {
                    _isEditMode = true;
                  });
                },
                tooltip: 'Edit Profile',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Section
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Profile Picture
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1E3A8A),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _profilePicture != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _profilePicture!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _driverProfile?.profilePicture != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _driverProfile!.profilePicture!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(Icons.person, size: 60, color: Colors.grey),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF1E3A8A),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.person, size: 60, color: Colors.white),
                                          ),
                                        ),
                            ),
                            if (_isEditMode)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                    onPressed: () => _pickImage(ImageSource.gallery, 'profile'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_driverProfile?.firstName ?? ''} ${_driverProfile?.lastName ?? ''}'.trim().isEmpty
                              ? 'Driver Name'
                              : '${_driverProfile?.firstName ?? ''} ${_driverProfile?.lastName ?? ''}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _status == 'Approved' 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _driverProfile?.driverId ?? 'KBD1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _status == 'Approved' 
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                        if (_isEditMode) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery, 'profile'),
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text('Change Photo'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2196F3),
                            ),
                          ),
                          const Text(
                            'Max 5MB, will be compressed',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Personal Information Card
                  _buildCard(
                    title: 'Personal Information',
                    child: Column(
                      children: [
                        _buildReadOnlyField('Driver ID', _driverProfile?.driverId ?? 'KBD1'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('First Name *', _firstNameController, enabled: _isEditMode)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Last Name *', _lastNameController, enabled: _isEditMode)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Email', _emailController, enabled: false),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Mobile Number', _mobileNumberController, enabled: false)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Alternate Number', _alternateNumberController, enabled: _isEditMode)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Vendor Name', _vendorNameController, enabled: false),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Vendor Code', _vendorCodeController, enabled: false)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDropdownField('Assigned Hub', _selectedHub, enabled: false)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Assigned Hub, Vendor Code & Vendor Name will be assigned by admin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Local Address Information Card
                  _buildCard(
                    title: 'Local Address Information',
                    child: Column(
                      children: [
                        _buildTextField('Address Line 1 *', _addressLine1Controller, enabled: _isEditMode),
                        const SizedBox(height: 16),
                        _buildTextField('Address Line 2', _addressLine2Controller, enabled: _isEditMode),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('State *', _stateController, enabled: _isEditMode)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('City *', _cityController, enabled: _isEditMode)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Pincode *', _pincodeController, enabled: _isEditMode)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFileUploadField('Local Address Proof', _localAddressProof, 'localAddress'),
                      ],
                    ),
                  ),
                  
                  // Document Details Card
                  _buildCard(
                    title: 'Document Details',
                    child: Column(
                      children: [
                        _buildTextField('Permanent Address *', _permanentAddressController, enabled: _isEditMode),
                        if (_isEditMode) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: _sameAsLocalAddress,
                                onChanged: (value) {
                                  setState(() {
                                    _sameAsLocalAddress = value ?? false;
                                    if (_sameAsLocalAddress) {
                                      _permanentAddressController.text = _addressLine1Controller.text;
                                    }
                                  });
                                },
                                activeColor: const Color(0xFF2196F3),
                              ),
                              const Text(
                                'Same as Local Address',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('PAN Card Number', _panCardNumberController, enabled: _isEditMode)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Aadhar Card Number', _aadharCardNumberController, enabled: _isEditMode)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildFileUploadField('Aadhar Front Photo', _aadharFrontPhoto, 'aadharFront')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildFileUploadField('Aadhar Back Photo', _aadharBackPhoto, 'aadharBack')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Driving License Number', _drivingLicenseNumberController, enabled: _isEditMode),
                        const SizedBox(height: 16),
                        _buildFileUploadField('Driving License Photo', _drivingLicensePhoto, 'drivingLicense'),
                      ],
                    ),
                  ),
                  
                  // Additional Information Card
                  _buildCard(
                    title: 'Additional Information',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Refer Code', _referCodeController, enabled: false)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Reference Code', _referenceCodeController, enabled: false)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildReadOnlyField('Status', _status)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Status Remark', _statusRemarkController, enabled: false)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildReadOnlyField('Last Device Used', _driverProfile?.lastDeviceUsed ?? 'N/A')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildReadOnlyField('Current Device', _driverProfile?.currentDeviceUsing ?? 'N/A')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildReadOnlyField('Created Date', _formatDate(_driverProfile?.createdAt ?? ''))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildReadOnlyField('Last Updated', _formatDate(_driverProfile?.updatedAt ?? ''))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  if (_isEditMode)
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditMode = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E3A8A),
                                side: const BorderSide(color: Color(0xFF1E3A8A)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle save
                                setState(() {
                                  _isEditMode = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
  
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E3A8A),
      ),
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.black87 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(
            fontSize: 15,
            color: enabled ? Colors.black87 : Colors.grey[600],
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
  
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDropdownField(String label, String value, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.black87 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: enabled ? Colors.black87 : Colors.grey[600],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFileUploadField(String label, File? file, String type) {
    String? imageUrl;
    switch (type) {
      case 'localAddress':
        imageUrl = _driverProfile?.currentAddressProof;
        break;
      case 'aadharFront':
        imageUrl = _driverProfile?.aadharFrontPhoto;
        break;
      case 'aadharBack':
        imageUrl = _driverProfile?.aadharBackPhoto;
        break;
      case 'drivingLicense':
        imageUrl = _driverProfile?.drivingLicencePhoto;
        break;
    }
    
    final hasImage = file != null || (imageUrl != null && imageUrl.isNotEmpty);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasImage ? Colors.grey[300]! : Colors.grey[300]!,
              width: 1.5,
              style: hasImage ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              if (file != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 12),
              if (_isEditMode)
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery, type),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Upload Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                    side: const BorderSide(color: Color(0xFF2196F3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (_isEditMode) const SizedBox(height: 8),
              Text(
                'Max 5MB, will be compressed automatically',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day}/${date.month}/${date.year}, $hour:$minute $amPm';
    } catch (e) {
      return dateString;
    }
  }
}

