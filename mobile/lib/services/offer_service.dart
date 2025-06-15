import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfferService {
  // Singleton pattern
  static final OfferService _instance = OfferService._internal();
  factory OfferService() => _instance;
  OfferService._internal();

  // Get all available offers
  List<Map<String, dynamic>> getOffers() {
    return [
      {
        'title': 'First Booking Discount',
        'code': 'FIRST50',
        'discount': '50% OFF',
        'discountType': 'percentage',
        'discountValue': 50,
        'maxDiscount': 200,
        'description': 'Get 50% off on your first booking. Maximum discount ₹200.',
        'validTill': 'June 30, 2025',
        'image': 'assets/images/offer1.png',
        'color': const Color(0xFF7C3AED),
        'conditions': {
          'isFirstBooking': true,
        }
      },
      {
        'title': 'Weekend Special',
        'code': 'WEEKEND25',
        'discount': '25% OFF',
        'discountType': 'percentage',
        'discountValue': 25,
        'maxDiscount': 150,
        'description': 'Get 25% off on all weekend bookings. Valid for Saturday and Sunday travel.',
        'validTill': 'July 15, 2025',
        'image': 'assets/images/offer2.png',
        'color': const Color(0xFF4C1D95),
        'conditions': {
          'isWeekendTravel': true,
        }
      },
      {
        'title': 'Senior Citizen Offer',
        'code': 'SENIOR15',
        'discount': '15% OFF',
        'discountType': 'percentage',
        'discountValue': 15,
        'maxDiscount': 100,
        'description': 'Additional 15% off for senior citizens. Can be combined with other offers.',
        'validTill': 'December 31, 2025',
        'image': 'assets/images/offer3.png',
        'color': const Color(0xFF5B21B6),
        'conditions': {
          'hasSeniorPassenger': true,
        }
      }
    ];
  }

  // Find offer by code
  Map<String, dynamic>? getOfferByCode(String code) {
    final offers = getOffers();
    try {
      return offers.firstWhere(
        (offer) => offer['code'] == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Check if offer is valid based on conditions
  bool isOfferValid(Map<String, dynamic> offer, Map<String, dynamic> bookingDetails) {
    // Check if offer is expired
    final validTill = offer['validTill'];
    final validTillDate = DateFormat('MMMM d, yyyy').parse(validTill);
    if (DateTime.now().isAfter(validTillDate)) {
      return false;
    }

    // Check specific conditions
    final conditions = offer['conditions'] as Map<String, dynamic>;
    
    // First booking check
    if (conditions['isFirstBooking'] == true && 
        bookingDetails['isFirstBooking'] != true) {
      return false;
    }
    
    // Weekend travel check
    if (conditions['isWeekendTravel'] == true) {
      final travelDate = bookingDetails['departureDate'] as DateTime;
      final isWeekend = travelDate.weekday == DateTime.saturday || 
                        travelDate.weekday == DateTime.sunday;
      if (!isWeekend) {
        return false;
      }
    }
    
    // Senior passenger check
    if (conditions['hasSeniorPassenger'] == true) {
      final passengers = bookingDetails['passengers'] as List<dynamic>;
      final hasSenior = passengers.any((p) => p['isSenior'] == true);
      if (!hasSenior) {
        return false;
      }
    }
    
    return true;
  }

  // Calculate discount amount
  double calculateDiscount(Map<String, dynamic> offer, double totalFare) {
    double discountAmount = 0;
    
    if (offer['discountType'] == 'percentage') {
      discountAmount = totalFare * (offer['discountValue'] / 100);
      
      // Apply maximum discount cap if exists
      if (offer.containsKey('maxDiscount')) {
        discountAmount = discountAmount > offer['maxDiscount'] 
            ? offer['maxDiscount'].toDouble() 
            : discountAmount;
      }
    } else if (offer['discountType'] == 'fixed') {
      discountAmount = offer['discountValue'].toDouble();
    }
    
    return discountAmount;
  }
}
