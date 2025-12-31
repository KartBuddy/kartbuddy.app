import 'package:flutter/material.dart';
import '../widgets/customer_sidebar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/banking_details_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'wallet_history.dart';

class ManualRecharge extends StatefulWidget {
  const ManualRecharge({super.key});

  @override
  State<ManualRecharge> createState() => _ManualRechargeState();
}

class _ManualRechargeState extends State<ManualRecharge> {
  List<BankingDetail> _bankingDetails = [];
  BankingDetail? _selectedBank;
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final TextEditingController _amountController = TextEditingController();
  File? _selectedFile;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBankingDetails();
  }

  Future<void> _loadBankingDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Fetching banking details...');
      final response = await _authService.getBankingDetails(token);

      if (mounted) {
        setState(() {
          _bankingDetails = response.data;
          // Select primary bank or first bank
          _selectedBank = response.data.firstWhere(
            (bank) => bank.primaryStatus,
            orElse: () => response.data.isNotEmpty ? response.data.first : throw Exception('No banks available'),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading banking details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showErrorDialog('Failed to pick image. Please try again.');
    }
  }

  Future<void> _handleSubmit() async {
    final amount = _amountController.text.trim();
    
    if (amount.isEmpty) {
      _showErrorDialog('Please enter the amount paid');
      return;
    }

    if (_selectedFile == null) {
      _showErrorDialog('Please upload a payment screenshot');
      return;
    }

    if (_selectedBank == null) {
      _showErrorDialog('Please select a bank');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Submitting recharge request...');
      final response = await _authService.submitRechargeRequest(
        amount,
        _selectedBank!.bankId,
        _selectedFile!,
        token,
      );

      print('✅ Recharge request submitted: ${response.data.requestId}');

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        _showSuccessDialog(
          'Recharge request submitted successfully!\nRequest ID: ${response.data.requestId}',
        );
      }
    } catch (e) {
      print('❌ Error submitting recharge request: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to wallet
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        centerTitle: true,
        title: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/Kartbuddy logo v.2.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      drawer: const CustomerSidebar(currentScreen: 'wallet'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            )
          : _bankingDetails.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('No banking details available'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Wallet Top-Up Request',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Payment Methods - Responsive Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            // Desktop/Tablet: Side by side
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildUPISection()),
                                const SizedBox(width: 24),
                                Expanded(child: _buildBankTransferSection()),
                              ],
                            );
                          } else {
                            // Mobile: Stacked
                            return Column(
                              children: [
                                _buildUPISection(),
                                const SizedBox(height: 24),
                                _buildBankTransferSection(),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Amount Paid Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amount Paid (₹)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter amount',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.normal,
                                ),
                                prefixIcon: const Icon(
                                  Icons.currency_rupee,
                                  color: Color(0xFF1E3A8A),
                                  size: 22,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1E3A8A),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Upload Payment Screenshot
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload Payment Screenshot',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.attach_file, size: 18),
                                  label: const Text('Choose File'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _selectedFile != null
                                        ? _selectedFile!.path.split('/').last
                                        : 'No file chosen',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedFile != null ? Colors.black87 : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Submit Request',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const WalletHistory()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'View History',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scan UPI QR Code to make payment:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _selectedBank != null && _selectedBank!.qrCodeImage.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _selectedBank!.qrCodeImage,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.qr_code, size: 64, color: Colors.grey),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                )
              : const Center(
                  child: Icon(Icons.qr_code, size: 64, color: Colors.grey),
                ),
        ),
        const SizedBox(height: 12),
        if (_selectedBank != null)
          Text(
            'UPI ID: ${_selectedBank!.upiId}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }

  Widget _buildBankTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Transfer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Bank Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BankingDetail>(
              value: _selectedBank,
              isExpanded: true,
              items: _bankingDetails.map<DropdownMenuItem<BankingDetail>>((BankingDetail bank) {
                return DropdownMenuItem<BankingDetail>(
                  value: bank,
                  child: Text(bank.bankName),
                );
              }).toList(),
              onChanged: (BankingDetail? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedBank = newValue;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedBank != null) ...[
          _buildBankDetailRow('Bank Name', _selectedBank!.bankName),
          const SizedBox(height: 8),
          _buildBankDetailRow('Account Name', _selectedBank!.accountName),
          const SizedBox(height: 8),
          _buildBankDetailRow('Account Number', _selectedBank!.accountNumber),
          const SizedBox(height: 8),
          _buildBankDetailRow('IFSC Code', _selectedBank!.ifscCode),
        ],
      ],
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

