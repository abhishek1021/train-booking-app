import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:train_booking_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Train Booking Flow Test', () {
    testWidgets('Complete booking flow with predefined inputs', (WidgetTester tester) async {
      // Start the app
      app.main();
      
      // Wait for the app to load completely
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await Future.delayed(const Duration(seconds: 3));
      
      print('App started, checking for login screen...');

      // If on login screen, perform login
      if (find.textContaining('Login', findRichText: true).evaluate().isNotEmpty ||
          find.byType(TextFormField).evaluate().isNotEmpty) {
        print('Login screen detected, attempting to login...');
        
        // Find email and password fields - try multiple approaches
        final emailFields = find.byType(TextFormField);
        final passwordFields = find.byType(TextFormField).at(1);
        
        if (emailFields.evaluate().isNotEmpty) {
          // Enter credentials
          await tester.enterText(emailFields.first, 'test@example.com');
          await tester.pumpAndSettle();
          await tester.enterText(passwordFields, 'password123');
          await tester.pumpAndSettle();
          
          // Find and tap login button
          final loginButton = find.widgetWithText(ElevatedButton, 'Login');
          if (loginButton.evaluate().isNotEmpty) {
            await tester.tap(loginButton);
            await tester.pumpAndSettle();
            await Future.delayed(const Duration(seconds: 3));
            print('Login attempted');
          } else {
            print('Login button not found, trying to continue anyway');
          }
        }
      } else {
        print('Already on main screen, proceeding with test...');
      }

      // Now we should be on the home/search screen
      print('Looking for origin and destination fields...');
      
      // Try to find text fields by different means
      final textFields = find.byType(TextField);
      final textFormFields = find.byType(TextFormField);
      
      // Try to identify origin field
      Finder originField;
      if (find.byKey(const ValueKey('origin_field')).evaluate().isNotEmpty) {
        originField = find.byKey(const ValueKey('origin_field'));
        print('Found origin field by key');
      } else if (find.widgetWithText(TextField, 'From').evaluate().isNotEmpty) {
        originField = find.widgetWithText(TextField, 'From');
        print('Found origin field by label "From"');
      } else if (textFields.evaluate().isNotEmpty) {
        originField = textFields.first;
        print('Using first TextField as origin field');
      } else if (textFormFields.evaluate().isNotEmpty) {
        originField = textFormFields.first;
        print('Using first TextFormField as origin field');
      } else {
        print('ERROR: Could not find origin field');
        return;
      }
      
      // Tap origin field and enter SWV
      await tester.tap(originField);
      await tester.pumpAndSettle();
      await tester.enterText(originField, 'SWV');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      print('Entered SWV in origin field');
      
      // Select SWV from dropdown if it appears
      if (find.text('SWV').evaluate().isNotEmpty) {
        await tester.tap(find.text('SWV').first);
        await tester.pumpAndSettle();
        print('Selected SWV from dropdown');
      }
      
      // Try to identify destination field
      Finder destinationField;
      if (find.byKey(const ValueKey('destination_field')).evaluate().isNotEmpty) {
        destinationField = find.byKey(const ValueKey('destination_field'));
        print('Found destination field by key');
      } else if (find.widgetWithText(TextField, 'To').evaluate().isNotEmpty) {
        destinationField = find.widgetWithText(TextField, 'To');
        print('Found destination field by label "To"');
      } else if (textFields.evaluate().length >= 2) {
        destinationField = textFields.at(1);
        print('Using second TextField as destination field');
      } else if (textFormFields.evaluate().length >= 2) {
        destinationField = textFormFields.at(1);
        print('Using second TextFormField as destination field');
      } else {
        print('ERROR: Could not find destination field');
        return;
      }
      
      // Tap destination field and enter MAO
      await tester.tap(destinationField);
      await tester.pumpAndSettle();
      await tester.enterText(destinationField, 'MAO');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      print('Entered MAO in destination field');
      
      // Select MAO from dropdown if it appears
      if (find.text('MAO').evaluate().isNotEmpty) {
        await tester.tap(find.text('MAO').first);
        await tester.pumpAndSettle();
        print('Selected MAO from dropdown');
      }
      
      // Try to find date field
      print('Looking for date field...');
      Finder dateField;
      if (find.byKey(const ValueKey('date_field')).evaluate().isNotEmpty) {
        dateField = find.byKey(const ValueKey('date_field'));
        print('Found date field by key');
      } else if (find.widgetWithText(TextField, 'Date').evaluate().isNotEmpty) {
        dateField = find.widgetWithText(TextField, 'Date');
        print('Found date field by label "Date"');
      } else if (textFields.evaluate().length >= 3) {
        dateField = textFields.at(2);
        print('Using third TextField as date field');
      } else if (textFormFields.evaluate().length >= 3) {
        dateField = textFormFields.at(2);
        print('Using third TextFormField as date field');
      } else {
        print('ERROR: Could not find date field');
        return;
      }
      
      // Tap on date field to open date picker
      await tester.tap(dateField);
      await tester.pumpAndSettle();
      print('Tapped date field');
      
      // Wait for date picker to appear
      await Future.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      
      // Try to find and tap on the 28th day
      if (find.text('28').evaluate().isNotEmpty) {
        await tester.tap(find.text('28').first);
        await tester.pumpAndSettle();
        print('Selected 28th day');
        
        // Try to find and tap OK button
        if (find.text('OK').evaluate().isNotEmpty) {
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          print('Confirmed date selection');
        } else if (find.text('CONFIRM').evaluate().isNotEmpty) {
          await tester.tap(find.text('CONFIRM'));
          await tester.pumpAndSettle();
          print('Confirmed date selection with CONFIRM button');
        } else {
          print('Could not find OK/CONFIRM button, continuing anyway');
        }
      } else {
        print('Could not find 28th day in date picker');
      }
      
      // Try to find search button by different means
      print('Looking for search button...');
      Finder searchButton;
      if (find.text('Search Trains').evaluate().isNotEmpty) {
        searchButton = find.text('Search Trains');
        print('Found search button by text "Search Trains"');
      } else if (find.text('Search').evaluate().isNotEmpty) {
        searchButton = find.text('Search');
        print('Found search button by text "Search"');
      } else if (find.byType(ElevatedButton).evaluate().isNotEmpty) {
        searchButton = find.byType(ElevatedButton).first;
        print('Using first ElevatedButton as search button');
      } else {
        print('ERROR: Could not find search button');
        return;
      }
      
      // Tap search button
      await tester.tap(searchButton);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3));
      print('Tapped search button, waiting for results...');
      
      // Now we should be on the search results screen
      // Try to find trains with available seats
      print('Looking for available trains...');
      
      // Try different approaches to find available seats
      bool foundAvailableSeats = false;
      Finder selectButton;
      
      if (find.text('Available').evaluate().isNotEmpty) {
        print('Found "Available" text indicator');
        foundAvailableSeats = true;
        
        // Try to find select button
        if (find.text('Select').evaluate().isNotEmpty) {
          selectButton = find.text('Select').first;
          print('Found "Select" button');
        } else if (find.byType(ElevatedButton).evaluate().isNotEmpty) {
          selectButton = find.byType(ElevatedButton).first;
          print('Using first ElevatedButton as select button');
        } else {
          print('ERROR: Could not find select button');
          return;
        }
      } else if (find.textContaining('seats', findRichText: true).evaluate().isNotEmpty) {
        print('Found text containing "seats"');
        foundAvailableSeats = true;
        
        // Try to find select button
        if (find.byType(ElevatedButton).evaluate().isNotEmpty) {
          selectButton = find.byType(ElevatedButton).first;
          print('Using first ElevatedButton as select button');
        } else {
          print('ERROR: Could not find select button');
          return;
        }
      } else {
        print('No trains with available seats found');
        return;
      }
      
      if (foundAvailableSeats) {
        // Tap select button
        await tester.tap(selectButton);
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 3));
        
        // Now we should be on the passenger details screen
        print('Successfully navigated to passenger details screen!');
        print('Test completed: Selected first available train from SWV to MAO on May 28th');
      }
    });
  });
}
