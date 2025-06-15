import 'package:flutter/material.dart';
import 'transaction_details_screen.dart';
import '../services/booking_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/passenger.dart';

class SelectPaymentMethodScreen extends StatefulWidget {
  final double walletBalance;
  final String bookingId;
  final String trainName;
  final String trainNumber; // Add train number parameter
  final String trainClass;
  final String departureStation;
  final String arrivalStation;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final String duration;
  final double price;
  final double tax;
  final double totalPrice;
  final String status;
  final String transactionId;
  final String merchantId;
  final String paymentMethod;
  final List<Passenger> passengers;
  final String email;
  final String phone;
  const SelectPaymentMethodScreen({
    Key? key,
    required this.walletBalance,
    required this.bookingId,
    required this.trainName,
    required this.trainNumber, // Add train number parameter
    required this.trainClass,
    required this.departureStation,
    required this.arrivalStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.duration,
    required this.price,
    required this.tax,
    required this.totalPrice,
    required this.status,
    required this.transactionId,
    required this.merchantId,
    required this.paymentMethod,
    required this.passengers,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  State<SelectPaymentMethodScreen> createState() =>
      _SelectPaymentMethodScreenState();
}

class _SelectPaymentMethodScreenState extends State<SelectPaymentMethodScreen> {
  int _selectedIndex = 0; // Only wallet is selectable
  bool _isProcessing = false;
  final BookingService _bookingService = BookingService();
  String _userId = ''; // Will be loaded from SharedPreferences
  late SharedPreferences _prefs;
  double _actualWalletBalance = 0.0; // Actual wallet balance from API
  bool _isLoadingWallet = true; // Flag to track wallet balance loading state

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingWallet = true;
    });

    _prefs = await SharedPreferences.getInstance();
    final userProfileJson = _prefs.getString('user_profile');

    if (userProfileJson != null && userProfileJson.isNotEmpty) {
      try {
        final userProfile = jsonDecode(userProfileJson);
        final userId = userProfile['UserID'] ?? '';
        setState(() {
          _userId = userId;
        });

        if (userId.isNotEmpty) {
          // Fetch wallet balance
          await _fetchWalletBalance(userId);
        }
      } catch (e) {
        print('Error parsing user profile: $e');
        setState(() {
          _isLoadingWallet = false;
        });
      }
    } else {
      setState(() {
        _isLoadingWallet = false;
      });
    }
  }

  // Fetch wallet balance from API
  Future<void> _fetchWalletBalance(String userId) async {
    try {
      final balance = await _bookingService.getWalletBalance(userId);
      setState(() {
        _actualWalletBalance = balance;
        _isLoadingWallet = false;
      });
    } catch (e) {
      print('Error fetching wallet balance: $e');
      setState(() {
        _actualWalletBalance = 0.0;
        _isLoadingWallet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Select Payment Method',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 28),
                ),
                title: Text(
                  'My Wallet',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                subtitle: null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isLoadingWallet
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF7C3AED)),
                            ),
                          )
                        : Text(
                            '\u20B9${_actualWalletBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                              fontSize: 16,
                            ),
                          ),
                    const SizedBox(width: 12),
                    Radio<int>(
                      value: 0,
                      groupValue: _selectedIndex,
                      onChanged: (val) {}, // Only wallet is selectable
                      activeColor: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        setState(() {
                          _isProcessing = true;
                        });

                        try {
                          // Check if user ID is available
                          if (_userId.isEmpty) {
                            // Try to load user ID again
                            final userProfileJson =
                                _prefs.getString('user_profile');
                            if (userProfileJson != null &&
                                userProfileJson.isNotEmpty) {
                              try {
                                final userProfile = jsonDecode(userProfileJson);
                                _userId = userProfile['UserID'] ?? '';
                              } catch (e) {
                                print('Error parsing user profile: $e');
                              }
                            }

                            // If still empty, show error
                            if (_userId.isEmpty) {
                              throw Exception(
                                  'User ID not found. Please log in again.');
                            }
                          }

                          // Process the booking with payment
                          // Extract and format train information properly
                          // Create a standardized train number from the train name
                          String trainName = widget.trainName.trim();
                          String trainNumber = '';

                          // Use the trainNumber passed from the review summary screen
                          // If it's empty, extract it from the train name as a fallback
                          trainNumber = widget.trainNumber;

                          if (trainNumber.isEmpty) {
                            // Extract train number from train name if it's in the format "Train Name (12345)"
                            final match =
                                RegExp(r'\(([0-9]+)\)').firstMatch(trainName);
                            if (match != null) {
                              trainNumber = match.group(1) ?? '';
                            } else {
                              // If no parentheses, check if the train name has a format like "MAO-SWV PASS"
                              // and convert it to a standard format without spaces or special characters
                              trainNumber = trainName.replaceAll(
                                  RegExp(r'[^A-Za-z0-9]'), '');
                            }
                          }

                          // Ensure train number is uppercase for consistency
                          trainNumber = trainNumber.toUpperCase();

                          // For debugging
                          print('Train ID: $trainNumber');
                          print('Train Name: $trainName');
                          print('Train Number: $trainNumber');

                          final result =
                              await _bookingService.processBookingWithPayment(
                            userId: _userId,
                            trainId: trainNumber,
                            trainName: trainName,
                            trainNumber: trainNumber,
                            journeyDate: widget.departureDate,
                            originStationCode: widget.departureStation,
                            destinationStationCode: widget.arrivalStation,
                            travelClass: widget.trainClass,
                            fare: widget.price,
                            tax: widget.tax,
                            totalAmount: widget.totalPrice,
                            passengers: widget.passengers,
                            paymentMethod: 'wallet',
                            email: widget.email,
                            phone: widget.phone,
                          );

                          // Get the booking and payment details
                          final bookingDetails = result['booking'];
                          final paymentDetails = result['payment'];
                          final transactionDetails = result['transaction'];

                          // Update state and show success dialog
                          setState(() {
                            _isProcessing = false;
                          });

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => TicketSuccessDialog(
                              onViewTransaction: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionDetailsScreen(
                                      bookingId: bookingDetails['booking_id'],
                                      barcodeData:
                                          '', // Not used, QR is generated from all fields
                                      trainName: widget.trainName,
                                      trainClass: widget.trainClass,
                                      departureStation: widget.departureStation,
                                      arrivalStation: widget.arrivalStation,
                                      departureTime: widget.departureTime,
                                      arrivalTime: widget.arrivalTime,
                                      departureDate: widget.departureDate,
                                      arrivalDate: widget.arrivalDate,
                                      duration: widget.duration,
                                      price: widget.price,
                                      tax: widget.tax,
                                      totalPrice: widget.totalPrice,
                                      status: 'confirmed',
                                      transactionId:
                                          paymentDetails['payment_id'],
                                      merchantId: transactionDetails['txn_id'],
                                      paymentMethod: 'wallet',
                                      passengers: widget.passengers,
                                    ),
                                  ),
                                );
                              },
                              onBackToHome: () {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                            ),
                          );
                        } catch (e) {
                          // Show error dialog on failure
                          setState(() {
                            _isProcessing = false;
                          });

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => TicketFailureDialog(
                              onRetry: () {
                                Navigator.of(context).pop();
                              },
                              onBackToHome: () {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ).copyWith(
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    return Colors.transparent;
                  }),
                  elevation: MaterialStateProperty.all(0),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                ),
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // TextButton(
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       barrierDismissible: false,
            //       builder: (context) => TicketFailureDialog(
            //         onRetry: () {
            //           Navigator.of(context).pop();
            //         },
            //         onBackToHome: () {
            //           Navigator.of(context).popUntil((route) => route.isFirst);
            //         },
            //       ),
            //     );
            //   },
            //   child: const Text(
            //     'Simulate Failure Popup',
            //     style: TextStyle(
            //       color: Color(0xFFB91C1C),
            //       decoration: TextDecoration.underline,
            //       fontFamily: 'ProductSans',
            //       fontSize: 14,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class TicketFailureDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBackToHome;
  const TicketFailureDialog({
    Key? key,
    required this.onRetry,
    required this.onBackToHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB91C1C),
              ),
              child: Center(
                child: Icon(Icons.close, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Payment Failed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Your payment could not be processed. Please check your details or try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.normal,
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ).copyWith(
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    return const Color(0xFFB91C1C);
                  }),
                  elevation: MaterialStateProperty.all(0),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: onBackToHome,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFB91C1C),
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

class TicketSuccessDialog extends StatelessWidget {
  final VoidCallback onViewTransaction;
  final VoidCallback onBackToHome;
  const TicketSuccessDialog({
    Key? key,
    required this.onViewTransaction,
    required this.onBackToHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7C3AED),
              ),
              child: Center(
                child: Icon(Icons.check, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Ticket Booking\nSuccessful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'You have successfully made a\npayment transaction and booked a ticket. You can access tickets through the My Ticket menu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.normal,
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onViewTransaction,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ).copyWith(
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    return Colors.transparent;
                  }),
                  elevation: MaterialStateProperty.all(0),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                ),
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'View Transaction',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: onBackToHome,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF7C3AED),
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
