import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../screens/transaction_details_screen.dart';
import '../api_constants.dart';

class BookingService {
  final String baseUrl = ApiConstants.baseUrl;

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String trainId,
    required String journeyDate,
    required String originStationCode,
    required String destinationStationCode,
    required String travelClass,
    required double fare,
    required List<Passenger> passengers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'train_id': trainId,
          'journey_date': journeyDate,
          'origin_station_code': originStationCode,
          'destination_station_code': destinationStationCode,
          'travel_class': travelClass,
          'fare': fare,
          'passengers': passengers.map((passenger) => {
            'name': passenger.fullName,
            'id_type': passenger.idType,
            'id_number': passenger.idNumber,
            'passenger_type': passenger.passengerType,
            'seat': passenger.seat,
          }).toList(),
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create booking: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating booking: $e');
      }
      throw Exception('Failed to create booking: $e');
    }
  }

  // Create a payment for a booking
  Future<Map<String, dynamic>> createPayment({
    required String userId,
    required String bookingId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'booking_id': bookingId,
          'amount': amount,
          'payment_method': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating payment: $e');
      }
      throw Exception('Failed to create payment: $e');
    }
  }

  // Create a wallet transaction
  Future<Map<String, dynamic>> createWalletTransaction({
    required String walletId,
    required String userId,
    required String type,
    required double amount,
    required String source,
    required String referenceId,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet-transactions/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'wallet_id': walletId,
          'user_id': userId,
          'type': type,
          'amount': amount,
          'source': source,
          'reference_id': referenceId,
          'notes': notes ?? 'Payment for booking',
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create wallet transaction: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating wallet transaction: $e');
      }
      throw Exception('Failed to create wallet transaction: $e');
    }
  }

  // Get wallet by user ID
  Future<Map<String, dynamic>> getWalletByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get wallet: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting wallet: $e');
      }
      throw Exception('Failed to get wallet: $e');
    }
  }

  // Process a complete booking with payment
  Future<Map<String, dynamic>> processBookingWithPayment({
    required String userId,
    required String trainId,
    required String trainName,
    required String journeyDate,
    required String originStationCode,
    required String destinationStationCode,
    required String travelClass,
    required double fare,
    required double tax,
    required double totalAmount,
    required List<Passenger> passengers,
    required String paymentMethod,
  }) async {
    try {
      // Step 1: Create the booking
      final bookingResponse = await createBooking(
        userId: userId,
        trainId: trainId,
        journeyDate: journeyDate,
        originStationCode: originStationCode,
        destinationStationCode: destinationStationCode,
        travelClass: travelClass,
        fare: fare,
        passengers: passengers,
      );

      final String bookingId = bookingResponse['booking_id'];
      final String pnr = bookingResponse['pnr'];

      // Step 2: Get the user's wallet
      final walletResponse = await getWalletByUserId(userId);
      final String walletId = walletResponse['wallet_id'];
      
      // Step 3: Create the payment
      final paymentResponse = await createPayment(
        userId: userId,
        bookingId: bookingId,
        amount: totalAmount,
        paymentMethod: paymentMethod,
      );

      final String paymentId = paymentResponse['payment_id'];
      
      // Step 4: Create wallet transaction (debit)
      final transactionResponse = await createWalletTransaction(
        walletId: walletId,
        userId: userId,
        type: 'debit',
        amount: totalAmount,
        source: 'booking',
        referenceId: bookingId,
        notes: 'Payment for booking $pnr on $trainName',
      );

      // Step 5: Update booking with payment ID
      await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'payment_id': paymentId,
          'booking_status': 'confirmed',
        }),
      );

      // Return combined response
      return {
        'booking': bookingResponse,
        'payment': paymentResponse,
        'transaction': transactionResponse,
        'status': 'success',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error processing booking with payment: $e');
      }
      throw Exception('Failed to process booking with payment: $e');
    }
  }
}
