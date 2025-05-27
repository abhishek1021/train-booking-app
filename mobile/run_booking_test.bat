@echo off
echo Running Train Booking Flow Integration Test on Chrome
echo ==========================================
cd /d %~dp0
flutter test integration_test/train_booking_flow_test.dart -d chrome
pause
