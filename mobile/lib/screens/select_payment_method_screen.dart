import 'package:flutter/material.dart';
import 'transaction_details_screen.dart';

class SelectPaymentMethodScreen extends StatefulWidget {
  final double walletBalance;
  final String bookingId;
  final String trainName;
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
  const SelectPaymentMethodScreen({
    Key? key,
    required this.walletBalance,
    required this.bookingId,
    required this.trainName,
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
  }) : super(key: key);

  @override
  State<SelectPaymentMethodScreen> createState() => _SelectPaymentMethodScreenState();
}

class _SelectPaymentMethodScreenState extends State<SelectPaymentMethodScreen> {
  int _selectedIndex = 0; // Only wallet for now

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
            fontFamily: 'Lato',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                ),
                title: Text(
                  'My Wallet',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                subtitle: null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\u20B9${widget.walletBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Lato',
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
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => TicketSuccessDialog(
                      onViewTransaction: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionDetailsScreen(
                              bookingId: widget.bookingId,
                              barcodeData: '', // Not used, QR is generated from all fields
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
                              status: widget.status,
                              transactionId: widget.transactionId,
                              merchantId: widget.merchantId,
                              paymentMethod: widget.paymentMethod,
                              passengers: widget.passengers,
                            ),
                          ),
                        );
                      },
                      onBackToHome: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
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
                      'Continue',
                      style: TextStyle(
                        fontFamily: 'Lato',
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
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => TicketFailureDialog(
                    onRetry: () {
                      Navigator.of(context).pop();
                    },
                    onBackToHome: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                );
              },
              child: const Text(
                'Simulate Failure Popup',
                style: TextStyle(
                  color: Color(0xFFB91C1C),
                  decoration: TextDecoration.underline,
                  fontFamily: 'Lato',
                  fontSize: 14,
                ),
              ),
            ),
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
                fontFamily: 'Lato',
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
                fontFamily: 'Lato',
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
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
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
                      fontFamily: 'Lato',
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
                    fontFamily: 'Lato',
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
                fontFamily: 'Lato',
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
                fontFamily: 'Lato',
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
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
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
                        fontFamily: 'Lato',
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
                    fontFamily: 'Lato',
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