import 'package:flutter/material.dart';
import 'dart:math';
import '../services/booking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  bool _isLoadingTransactions = true;
  double _walletBalance = 0.0;
  String _userId = '';
  String _walletId = '';
  List<Map<String, dynamic>> _transactions = [];
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _isLoadingTransactions = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileJson = prefs.getString('user_profile');

      if (userProfileJson != null && userProfileJson.isNotEmpty) {
        final userProfile = jsonDecode(userProfileJson);
        final userId = userProfile['UserID'] ?? '';

        setState(() {
          _userId = userId;
        });

        if (userId.isNotEmpty) {
          await _fetchWalletData(userId);
          await _fetchTransactions();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch wallet data
  Future<void> _fetchWalletData(String userId) async {
    try {
      final walletData = await _bookingService.getWalletByUserId(userId);
      setState(() {
        _walletBalance = double.tryParse(walletData['balance'].toString()) ?? 0.0;
        _walletId = walletData['wallet_id'] ?? '';
      });
    } catch (e) {
      print('Error fetching wallet data: $e');
      setState(() {
        _walletBalance = 0.0;
      });
    }
  }

  // Fetch wallet transactions
  Future<void> _fetchTransactions() async {
    try {
      if (_walletId.isEmpty) return;

      final transactionsData = await _bookingService.getWalletTransactions(_walletId);
      List<Map<String, dynamic>> transactions = [];

      for (var txn in transactionsData) {
        transactions.add({
          'txn_id': txn['txn_id'] ?? '',
          'amount': double.tryParse(txn['amount'].toString()) ?? 0.0,
          'type': txn['type'] ?? 'debit',
          'source': txn['source'] ?? 'unknown',
          'status': txn['status'] ?? 'pending',
          'created_at': txn['created_at'] ?? DateTime.now().toIso8601String(),
          'notes': txn['notes'] ?? '',
        });
      }

      // Sort transactions by date (newest first)
      transactions.sort((a, b) {
        DateTime dateA = DateTime.parse(a['created_at']);
        DateTime dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        _transactions = [];
        _isLoadingTransactions = false;
      });
    }
  }

  // Top up wallet
  Future<void> _topUpWallet() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await _bookingService.createWalletTransaction(
        walletId: _walletId,
        userId: _userId,
        type: 'credit',
        amount: amount,
        source: 'topup',
        referenceId: 'TOPUP${DateTime.now().millisecondsSinceEpoch}',
        notes: 'Wallet top-up',
      );

      // Refresh wallet data and transactions
      await _fetchWalletData(_userId);
      await _fetchTransactions();

      // Clear the amount field
      _amountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet topped up successfully')),
      );
    } catch (e) {
      print('Error topping up wallet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to top up wallet: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Get transaction icon based on type and source
  IconData _getTransactionIcon(String type, String source) {
    if (type == 'credit') {
      if (source == 'topup') return Icons.add_circle_outline;
      if (source == 'refund') return Icons.replay;
      return Icons.arrow_downward;
    } else {
      if (source == 'booking') return Icons.train;
      return Icons.arrow_upward;
    }
  }

  // Get transaction color based on type
  Color _getTransactionColor(String type) {
    return type == 'credit' ? const Color(0xFF059669) : const Color(0xFFB91C1C);
  }

  // Get transaction title based on source
  String _getTransactionTitle(String type, String source, String notes) {
    if (notes.isNotEmpty) return notes;
    
    if (type == 'credit') {
      if (source == 'topup') return 'Wallet Top-up';
      if (source == 'refund') return 'Refund';
      return 'Money Added';
    } else {
      if (source == 'booking') return 'Train Booking';
      if (source == 'withdrawal') return 'Withdrawal';
      return 'Money Deducted';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Wallet',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadUserData(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Card
                  _buildWalletCard(),
                  const SizedBox(height: 24),

                  // Top-up Section
                  _buildTopUpSection(),
                  const SizedBox(height: 24),

                  // Recent Transactions
                  _buildTransactionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Card pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'TatkalPro Wallet',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Current Balance',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '₹${_walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Wallet ID: ${_walletId.substring(0, min(10, _walletId.length))}...',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Up Wallet',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount',
              prefixText: '₹ ',
              prefixStyle: const TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.black87,
                fontSize: 16,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickAmountButton(100),
              const SizedBox(width: 8),
              _buildQuickAmountButton(500),
              const SizedBox(width: 8),
              _buildQuickAmountButton(1000),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _topUpWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Add Money',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _amountController.text = amount.toString();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EAFB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '₹${amount.toInt()}',
              style: const TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C3AED),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C3AED),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingTransactions
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              )
            : _transactions.isEmpty
                ? _buildEmptyTransactions()
                : Column(
                    children: _transactions
                        .take(10) // Show only the 10 most recent transactions
                        .map((txn) => _buildTransactionItem(txn))
                        .toList(),
                  ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'debit';
    final source = transaction['source'] ?? 'unknown';
    final notes = transaction['notes'] ?? '';
    final amount = transaction['amount'] ?? 0.0;
    final date = transaction['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTransactionColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTransactionIcon(type, source),
              color: _getTransactionColor(type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionTitle(type, source, notes),
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${type == 'credit' ? '+' : '-'} ₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              color: _getTransactionColor(type),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
