import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/passenger.dart';
import '../services/offer_service.dart';
import 'select_payment_method_screen.dart';

/// A **CLEAN REWRITE** of the original `review_summary_screen.dart`.
///
/// This file keeps the user-facing design identical (purple/white colour
/// palette, rounded cards, ProductSans fonts, button gradients etc.) while
/// fixing the deeply nested / mismatched parenthesis that made the old file
/// hard to maintain.
///
/// Only the **Voucher / Offer** card (line ≈ 926 in the legacy file) and the
/// **Price details** card were re-implemented here – the remainder of the
/// route / passenger layout can be ported in later once the core structure is
/// stable.
class ReviewSummaryScreenFixed extends StatefulWidget {
  const ReviewSummaryScreenFixed({
    super.key,
    required this.train,
    required this.passengers,
    required this.originName,
    required this.destinationName,
    required this.depTime,
    required this.arrTime,
    required this.date,
    required this.selectedClass,
    required this.price,
    required this.tax,
    required this.coins,
    required this.email,
    required this.phone,
  });

  final Map<String, dynamic> train;
  final List<Map<String, dynamic>> passengers;
  final String originName;
  final String destinationName;
  final String depTime;
  final String arrTime;
  final String date;
  final String selectedClass;
  final int price;
  final int tax;
  final int coins;
  final String email;
  final String phone;

  @override
  State<ReviewSummaryScreenFixed> createState() => _ReviewSummaryScreenFixedState();
}

class _ReviewSummaryScreenFixedState extends State<ReviewSummaryScreenFixed> {
  final _voucherController = TextEditingController();
  final OfferService _offerService = OfferService();

  Map<String, dynamic>? _appliedOffer;
  String? _offerError;
  double _discountAmount = 0;
  bool _useCoins = false;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  /* -------------------------------------------------------------------------- */
  /*                                 VOUCHER                                   */
  /* -------------------------------------------------------------------------- */

  void _applyVoucher() {
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      setState(() => _offerError = 'Please enter a voucher code');
      return;
    }
    final offer = _offerService.getOfferByCode(code);
    if (offer == null) {
      setState(() => _offerError = 'Invalid voucher code');
      return;
    }

    final bookingDetails = {
      'departureDate': DateFormat('yyyy-MM-dd').parse(widget.date),
      'passengers': widget.passengers,
      // TODO – fetch real first-booking status from profile
      'isFirstBooking': false,
    };

    if (!_offerService.isOfferValid(offer, bookingDetails)) {
      setState(() => _offerError = 'Offer not applicable to this booking');
      return;
    }

    final baseAmount = _baseFare() * widget.passengers.length;
    _discountAmount = _offerService.calculateDiscount(offer, baseAmount);

    setState(() {
      _appliedOffer = offer;
      _offerError = null;
    });
  }

  void _removeVoucher() {
    setState(() {
      _appliedOffer = null;
      _discountAmount = 0;
      _voucherController.clear();
      _offerError = null;
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                              PRICE CALCULATIONS                            */
  /* -------------------------------------------------------------------------- */

  double _baseFare() {
    if (widget.train['class_prices'] is Map &&
        widget.train['class_prices'][widget.selectedClass] != null) {
      final raw = widget.train['class_prices'][widget.selectedClass];
      return raw is num ? raw.toDouble() : double.tryParse('$raw') ?? widget.price.toDouble();
    }
    return widget.price.toDouble();
  }

  double _totalPrice() {
    double total = _baseFare() * widget.passengers.length + widget.tax;
    if (_discountAmount > 0) total = max(0, total - _discountAmount);
    if (_useCoins) total = max(0, total - widget.coins);
    return total;
  }

  /* -------------------------------------------------------------------------- */
  /*                                    UI                                      */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Review Summary', style: TextStyle(fontFamily: 'ProductSans', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7C3AED),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _voucherCard(),
            const SizedBox(height: 16),
            _coinCard(),
            const SizedBox(height: 16),
            _priceDetailsCard(),
            const SizedBox(height: 24),
            _confirmButton(),
          ],
        ),
      ),
    );
  }

  /* ---------------------------- COMPONENTS ---------------------------- */

  Widget _voucherCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(icon: Icons.local_offer, title: 'Discount / Voucher'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  enabled: _appliedOffer == null,
                  decoration: InputDecoration(
                    hintText: 'Enter Code',
                    errorText: _offerError,
                    filled: true,
                    fillColor: _appliedOffer == null ? const Color(0xFFF7F7FA) : Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontFamily: 'ProductSans', fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _appliedOffer == null ? _applyVoucher : _removeVoucher,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor:
                        _appliedOffer == null ? const Color(0xFF7C3AED) : Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _appliedOffer == null ? 'Apply' : 'Remove',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _appliedOffer == null ? Colors.white : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_appliedOffer != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_appliedOffer!['title'] ?? 'Offer Applied',
                            style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green.shade800)),
                        const SizedBox(height: 2),
                        Text('You saved ₹${_discountAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontSize: 13,
                                color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _coinCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(icon: Icons.attach_money, title: 'Use Coins'),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('You have ${widget.coins} coins',
                  style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              Switch(
                value: _useCoins,
                onChanged: (v) => setState(() => _useCoins = v),
                activeColor: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Use coins for your payments. You will get 5 coins after this order.',
              style: TextStyle(fontFamily: 'ProductSans', fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _priceDetailsCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Price Details',
              style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF7C3AED))),
          const SizedBox(height: 18),
          _priceRow('Base Fare', _baseFare() * widget.passengers.length),
          _priceRow('Tax', widget.tax.toDouble()),
          if (_discountAmount > 0)
            _priceRow('Voucher Discount', -_discountAmount, color: Colors.green),
          if (_useCoins) _priceRow('Coin Discount', -widget.coins.toDouble(), color: Colors.green),
          const Divider(),
          _priceRow('Total Price', _totalPrice(), bold: true),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SelectPaymentMethodScreen(
                totalPrice: _totalPrice(),
                // TODO: supply remaining arguments
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text('Confirm Booking',
                style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }

  /* ---------------------------- SMALL HELPERS ---------------------------- */

  Widget _whiteCard({required Widget child}) => Card(
        color: Colors.white,
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      );

  Widget _cardHeader({required IconData icon, required String title}) => Row(
        children: [
          Icon(icon, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87)),
        ],
      );

  Widget _priceRow(String label, double value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 14,
                color: color ?? Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
          const Spacer(),
          Text('₹${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 14,
                color: color ?? Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}
