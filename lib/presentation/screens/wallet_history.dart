import 'package:flutter/material.dart';
import '../widgets/customer_sidebar.dart';
import '../../models/wallet_transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'customer_wallet.dart';

class WalletHistory extends StatefulWidget {
  const WalletHistory({super.key});

  @override
  State<WalletHistory> createState() => _WalletHistoryState();
}

class _WalletHistoryState extends State<WalletHistory> {
  List<WalletTransaction> _allTransactions = [];
  List<WalletTransaction> _filteredTransactions = [];
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadWalletHistory();
  }

  Future<void> _loadWalletHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      print('🔵 Fetching wallet history for customer: ${customer.id}');
      final response = await _authService.getWalletHistory(customer.id, token);

      if (mounted) {
        setState(() {
          _allTransactions = response.data;
          _filteredTransactions = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading wallet history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        if (_fromDate != null || _toDate != null) {
          try {
            final transactionDate = DateTime.parse(transaction.transactionDate);
            final fromMatch = _fromDate == null || 
                transactionDate.isAfter(_fromDate!.subtract(const Duration(days: 1)));
            final toMatch = _toDate == null || 
                transactionDate.isBefore(_toDate!.add(const Duration(days: 1)));
            return fromMatch && toMatch;
          } catch (e) {
            return true;
          }
        }
        return true;
      }).toList();
    });
  }

  Future<void> _selectFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'dd-mm-yyyy';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatTableDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String timeString) {
    return timeString;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Title
            const Text(
              'Wallet Transaction History',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 24),

            // Date Filters
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: InkWell(
                          onTap: _selectFromDate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(_fromDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _fromDate == null ? Colors.grey[400] : Colors.black87,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: InkWell(
                          onTap: _selectToDate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(_toDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _toDate == null ? Colors.grey[400] : Colors.black87,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Show'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Transaction Table
            Container(
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
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                        ),
                      ),
                    )
                  : _filteredTransactions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'No transactions found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(label: SizedBox(width: 80, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              DataColumn(label: SizedBox(width: 100, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              DataColumn(label: SizedBox(width: 120, child: Text('Transaction ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              DataColumn(label: SizedBox(width: 70, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              DataColumn(label: SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              DataColumn(label: SizedBox(width: 120, child: Text('Reference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              DataColumn(label: SizedBox(width: 100, child: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              DataColumn(label: SizedBox(width: 90, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              DataColumn(label: SizedBox(width: 100, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                            ],
                            rows: _filteredTransactions.map((transaction) {
                              final isCredit = transaction.creditDebit.toLowerCase() == 'credit';
                              return DataRow(
                                cells: [
                                  DataCell(SizedBox(width: 80, child: Text(_formatTableDate(transaction.transactionDate), style: const TextStyle(fontSize: 12)))),
                                  DataCell(SizedBox(width: 100, child: Text(_formatTime(transaction.transactionTime), style: const TextStyle(fontSize: 12)))),
                                  DataCell(SizedBox(width: 120, child: Text(transaction.transactionId, style: const TextStyle(fontSize: 12)))),
                                  DataCell(SizedBox(width: 70, child: Text(
                                    transaction.creditDebit,
                                    style: TextStyle(
                                      color: isCredit ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ))),
                                  DataCell(SizedBox(width: 80, child: Text(
                                    '${isCredit ? '+' : '-'}₹${transaction.amount}',
                                    style: TextStyle(
                                      color: isCredit ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ))),
                                  DataCell(SizedBox(width: 120, child: Text(
                                    transaction.portalTransactionRemarks1 ?? 'N/A',
                                    style: const TextStyle(fontSize: 12),
                                  ))),
                                  DataCell(SizedBox(width: 100, child: Text(transaction.paymentMethod, style: const TextStyle(fontSize: 12)))),
                                  DataCell(SizedBox(width: 90, child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Successful',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))),
                                  DataCell(SizedBox(width: 100, child: Text('₹${transaction.userWalletBalance}', style: const TextStyle(fontSize: 12)))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
            const SizedBox(height: 24),

            // Download Excel Report Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coming Soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Download Excel Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

