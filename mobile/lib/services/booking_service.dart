import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../screens/transaction_details_screen.dart';
import '../config/api_config.dart';

class BookingService {
  final String baseUrl = ApiConfig.baseUrl;

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
    required String email,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.bookingEndpoint}/'),
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
          'fare': fare.toString(), // Convert to string to avoid float type errors
          'booking_email': email,
          'booking_phone': phone,
          'passengers': passengers.map((passenger) => {
            'name': passenger.fullName.isNotEmpty ? passenger.fullName : 'Passenger',
            'age': passenger.age,
            'gender': passenger.gender,
            'id_type': passenger.idType.isNotEmpty ? passenger.idType : 'aadhar',
            'id_number': passenger.idNumber.isNotEmpty ? passenger.idNumber : 'XXXX-XXXX-XXXX',
            'seat': passenger.seat.isNotEmpty ? passenger.seat : 'B2-34',
            'status': 'confirmed',
            'is_senior': passenger.isSenior
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
        Uri.parse('$baseUrl${ApiConfig.paymentEndpoint}/'),
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
        Uri.parse('$baseUrl${ApiConfig.walletTransactionEndpoint}/'),
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
        Uri.parse('$baseUrl${ApiConfig.walletEndpoint}/user/$userId'),
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
  
  // Get wallet balance
  Future<double> getWalletBalance(String userId) async {
    try {
      final walletData = await getWalletByUserId(userId);
      // Parse the balance as a double
      final balance = double.tryParse(walletData['balance'].toString()) ?? 0.0;
      return balance;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting wallet balance: $e');
      }
      // Return a default balance of 0 in case of error
      return 0.0;
    }
  }
  
  // Get wallet transactions
  Future<List<dynamic>> getWalletTransactions(String walletId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.walletTransactionEndpoint}/wallet/$walletId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactions = jsonDecode(response.body);
        return transactions;
      } else {
        throw Exception('Failed to get wallet transactions: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting wallet transactions: $e');
      }
      // Return an empty list in case of error
      return [];
    }
  }
  
  // Get bookings by user ID
  Future<List<dynamic>> getBookingsByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.bookingEndpoint}/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> bookings = jsonDecode(response.body);
        return bookings;
      } else {
        throw Exception('Failed to get bookings: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bookings: $e');
      }
      // Return an empty list in case of error
      return [];
    }
  }
  
  // Get booking by ID
  Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.bookingEndpoint}/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Booking API Response Status: ${response.statusCode}');
        print('Booking API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> booking = jsonDecode(response.body);
        
        // Ensure booking_email and booking_phone are included
        if (booking['booking_email'] == null) {
          if (kDebugMode) {
            print('Warning: booking_email is null in the API response');
          }
        }
        if (booking['booking_phone'] == null) {
          if (kDebugMode) {
            print('Warning: booking_phone is null in the API response');
          }
        }
        
        return booking;
      } else {
        throw Exception('Failed to get booking: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting booking: $e');
      }
      throw Exception('Failed to get booking: $e');
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
    required String email,
    required String phone,
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
        email: email,
        phone: phone,
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
        Uri.parse('$baseUrl${ApiConfig.bookingEndpoint}/$bookingId'),
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
