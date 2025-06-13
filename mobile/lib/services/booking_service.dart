import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/passenger.dart';
import '../config/api_config.dart';

class BookingService {
  final String baseUrl = ApiConfig.baseUrl;

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String trainId,
    required String trainName,
    required String trainNumber,
    required String journeyDate,
    required String originStationCode,
    required String destinationStationCode,
    required String travelClass,
    required double fare,
    required double tax,
    required double totalAmount,
    required Map<String, dynamic> priceDetails,
    required List<Passenger> passengers,
    required String email,
    required String phone,
    required String paymentMethod,
  }) async {
    try {
      // Get current date and time in IST format
      final now = DateTime.now();
      final bookingDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}"; 
      final bookingTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}"; 
      
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.bookingEndpoint}/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'train_id': trainId,
          'train_name': trainName,
          'train_number': trainNumber,
          'journey_date': journeyDate,
          'origin_station_code': originStationCode,
          'destination_station_code': destinationStationCode,
          'travel_class': travelClass,
          'fare': fare.toString(), // Convert to string to avoid float type errors
          'tax': tax.toString(),
          'total_amount': totalAmount.toString(),
          'booking_email': email,
          'booking_phone': phone,
          'booking_date': bookingDate,
          'booking_time': bookingTime,
          'booking_status': 'confirmed',
          'payment_status': 'paid',
          'payment_method': paymentMethod,
          'price_details': priceDetails,
          'passengers': passengers
              .map((passenger) => {
                    'name': passenger.fullName.isNotEmpty
                        ? passenger.fullName
                        : 'Passenger',
                    'age': passenger.age,
                    'gender': passenger.gender,
                    'id_type': passenger.idType.isNotEmpty
                        ? passenger.idType
                        : 'aadhar',
                    'id_number': passenger.idNumber.isNotEmpty
                        ? passenger.idNumber
                        : 'XXXX-XXXX-XXXX',
                    'seat':
                        passenger.seat.isNotEmpty ? passenger.seat : 'B2-34',
                    'status': 'confirmed',
                    'is_senior': passenger.isSenior
                  })
              .toList(),
        }),
      );

      final responseBody = jsonDecode(response.body);
      
      // Check if the response contains a booking_id and status:success, which indicates success
      if (response.statusCode == 201 || 
          (responseBody is Map && responseBody.containsKey('booking_id') && 
           responseBody.containsKey('status') && responseBody['status'] == 'success')) {
        return responseBody;
      } else {
        throw Exception('Failed to create booking: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating booking: $e');
      }
      
      // Check if the error message contains a successful booking response
      final String errorMsg = e.toString();
      if (errorMsg.contains('"booking_id"') && errorMsg.contains('"status":"success"')) {
        try {
          // Extract the JSON part from the error message
          final jsonStart = errorMsg.indexOf('{');
          final jsonEnd = errorMsg.lastIndexOf('}') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonStr = errorMsg.substring(jsonStart, jsonEnd);
            final Map<String, dynamic> bookingData = jsonDecode(jsonStr);
            if (bookingData.containsKey('booking_id') && bookingData.containsKey('status') && 
                bookingData['status'] == 'success') {
              return bookingData;
            }
          }
        } catch (jsonError) {
          // If parsing fails, continue with the original error
          if (kDebugMode) {
            print('Error parsing booking response from error: $jsonError');
          }
        }
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
        throw Exception(
            'Failed to create wallet transaction: ${response.body}');
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
      // Ensure userId is not empty
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      
      // Use path parameter as expected by the backend
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
      // Ensure walletId is not empty
      if (walletId.isEmpty) {
        throw Exception('Wallet ID cannot be empty');
      }
      
      // Use path parameter as expected by the backend
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
      // Ensure userId is not empty
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      
      // Use path parameter as expected by the backend
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

  // Get booking by PNR
  Future<Map<String, dynamic>> getBookingByPNR(String pnr) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.bookingEndpoint}/pnr/$pnr'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print('PNR Search API Response Status: ${response.statusCode}');
        print('PNR Search API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> booking = jsonDecode(response.body);
        return booking;
      } else if (response.statusCode == 404) {
        throw Exception('No booking found with PNR: $pnr');
      } else {
        throw Exception('Failed to search PNR: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error searching PNR: $e');
      }
      throw Exception('Failed to search PNR: $e');
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
  
  // Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.bookingEndpoint}/$bookingId/cancel'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Cancel Booking API Response Status: ${response.statusCode}');
        print('Cancel Booking API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to cancel booking: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling booking: $e');
      }
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Calculate price details including breakdown by passenger type
  Map<String, dynamic> _calculatePriceDetails(List<Passenger> passengers, double baseFare, double tax, double totalAmount) {
    // Count passengers by type
    int adultCount = 0;
    int seniorCount = 0;
    
    // Calculate fare by passenger type
    double adultFare = 0.0;
    double seniorFare = 0.0;
    
    // Process each passenger
    for (var passenger in passengers) {
      if (passenger.isSenior) {
        seniorCount++;
        // Apply 25% discount for seniors
        seniorFare += baseFare * 0.75;
      } else {
        adultCount++;
        adultFare += baseFare;
      }
    }
    
    // Calculate subtotal before tax
    double subtotal = adultFare + seniorFare;
    
    // Create price details object with string values for numeric fields to avoid float type errors
    return {
      'base_fare_per_adult': baseFare,
      'base_fare_per_senior': baseFare * 0.75,
      'adult_count': adultCount,
      'senior_count': seniorCount,
      'adult_fare_total': adultFare,
      'senior_fare_total': seniorFare,
      'subtotal': subtotal,
      'tax': tax,
      'total': totalAmount,
      'discount_applied': seniorCount > 0 ? 'Senior citizen discount (25%)' : null,
    };
  }

  // Process a complete booking with payment
  Future<Map<String, dynamic>> processBookingWithPayment({
    required String userId,
    required String trainId,
    required String trainName,
    required String trainNumber,
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
      // Use the provided train information directly
      // Ensure all train information is properly formatted
      String formattedTrainId = trainId.trim().toUpperCase();
      String formattedTrainName = trainName.trim();
      String formattedTrainNumber = trainNumber.trim().toUpperCase();
      
      if (kDebugMode) {
        print('Processing booking with train information:');
        print('Train ID: $formattedTrainId');
        print('Train Name: $formattedTrainName');
        print('Train Number: $formattedTrainNumber');
      }
      
      // Calculate price details including breakdown by passenger type
      Map<String, dynamic> priceDetails = _calculatePriceDetails(passengers, fare, tax, totalAmount);
      
      // Step 1: Create the booking
      final bookingResponse = await createBooking(
        userId: userId,
        trainId: formattedTrainId, // Use formatted train ID
        trainName: formattedTrainName,
        trainNumber: formattedTrainNumber,
        journeyDate: journeyDate,
        originStationCode: originStationCode,
        destinationStationCode: destinationStationCode,
        travelClass: travelClass,
        fare: fare,
        tax: tax,
        totalAmount: totalAmount,
        priceDetails: priceDetails,
        passengers: passengers,
        email: email,
        phone: phone,
        paymentMethod: paymentMethod,
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
          'payment_status': 'paid',
          'payment_method': paymentMethod,
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
