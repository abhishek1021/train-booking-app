# Train Booking App - Manual Test Script

## Test Scenario: Book a train from SWV to MAO on May 28th

This script provides step-by-step instructions to manually test the train booking flow with predefined inputs.

### Prerequisites
- The Train Booking App should be running in Chrome or on a device
- You should have valid login credentials if required

### Test Steps

#### 1. Login (if required)
- Open the app
- If presented with a login screen:
  - Enter your test email and password
  - Tap the "Login" button
  - Verify you are redirected to the home/search screen

#### 2. Search for Trains
- On the home/search screen:
  - Tap the "From" field
  - Enter "SWV" 
  - Select "SWV" from the dropdown if it appears
  - Tap the "To" field
  - Enter "MAO"
  - Select "MAO" from the dropdown if it appears
  - Tap the date field
  - Select May 28th from the date picker
  - Tap "OK" or "CONFIRM" to confirm the date
  - Tap the "Search Trains" button
  - Verify you are redirected to the search results screen

#### 3. Select a Train
- On the search results screen:
  - Look for trains with "Available" seats
  - Tap the "Select" button for the first available train
  - Verify you are redirected to the passenger details screen

#### 4. Add Passenger Details
- On the passenger details screen:
  - If you have saved passengers, you can select one from the horizontal scroll view
  - Or add a new passenger by tapping the "Add Passenger" button
  - Fill in the required passenger details:
    - Name
    - Age
    - Gender
    - ID Type (Aadhar, PAN, or Driving License)
    - ID Number (following the validation rules for the selected ID type)
  - Verify that the ID validation works correctly:
    - Aadhar: Must be 12 digits
    - PAN: Must follow format of 5 letters + 4 numbers + 1 letter
    - Driving License: Must be between 13-16 characters
  - Fill in contact details (email and phone)
  - Tap the "Continue" button
  - Verify you are redirected to the review summary screen

#### 5. Review and Confirm
- On the review summary screen:
  - Verify that all details are correct:
    - Train details (number, name, time)
    - Journey details (from SWV to MAO on May 28th)
    - Passenger details
    - Contact details
  - Tap the "Confirm Booking" button (if available)
  - Verify the booking confirmation is shown

### Expected Results
- The app should successfully guide you through the entire booking flow
- All validations should work as expected
- The passenger details should be saved to the database when continuing to the review screen
- The UI should be responsive and follow the purple and white color scheme

### Test Data
- Origin: SWV
- Destination: MAO
- Date: May 28th, 2025
- Passenger Details:
  - Name: Test User
  - Age: 30
  - Gender: Male
  - ID Type: Aadhar
  - ID Number: 123456789012 (12 digits)
- Contact Details:
  - Email: test@example.com
  - Phone: 9876543210

### Notes
- If you encounter any issues during testing, note them down with the specific step and screen
- Pay attention to any error messages or unexpected behavior
- Check that the saved passenger functionality works correctly
