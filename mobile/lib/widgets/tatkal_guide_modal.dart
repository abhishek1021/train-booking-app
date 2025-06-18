import 'package:flutter/material.dart';

class TatkalGuideModal extends StatefulWidget {
  final VoidCallback? onClose;
  const TatkalGuideModal({Key? key, this.onClose}) : super(key: key);

  @override
  State<TatkalGuideModal> createState() => _TatkalGuideModalState();
}

class _TatkalGuideModalState extends State<TatkalGuideModal> {
  int _currentPage = 0;
  late final PageController _pageController;

  final List<_GuideStep> steps = [
    _GuideStep(
      title: 'Journey Details',
      description:
          'Select your origin and destination stations, journey date, and preferred class. Make sure your journey details are accurate for a smooth booking experience.',
      icon: Icons.train,
    ),
    _GuideStep(
      title: 'Passenger Details',
      description:
          'Add all passengers with their name, age, gender, berth preference, and ID details. You can add up to 6 passengers. Use saved passengers for faster entry.',
      icon: Icons.people_alt,
    ),
    _GuideStep(
      title: 'Contact Details',
      description:
          'Enter your email and phone number. Optionally add GST details for business travel and opt for travel insurance.',
      icon: Icons.contact_mail,
    ),
    _GuideStep(
      title: 'Preferences',
      description:
          'Choose auto-upgrade, alternate date booking, and payment method. Add any special notes if needed.',
      icon: Icons.settings,
    ),
    _GuideStep(
      title: 'Train Selection',
      description:
          'Pick a preferred train or skip to let the system choose the best available option at booking time.',
      icon: Icons.directions_railway,
    ),
    _GuideStep(
      title: 'Review & Book',
      description:
          'Double-check all details. Tap Create Job to schedule your Tatkal booking. You can monitor job status from My Bookings.',
      icon: Icons.check_circle_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 0, right: 0, bottom: 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 26),
                        child: Column(
                          children: const [
                            Icon(Icons.flash_on, color: Colors.white, size: 38),
                            SizedBox(height: 8),
                            Text(
                              'How Tatkal Mode Works',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                fontFamily: 'ProductSans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: widget.onClose ?? () => Navigator.of(context).pop(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.close, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 24 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF7C3AED)
                            : Colors.deepPurple.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: steps.length,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        shadowColor: Colors.deepPurple.withOpacity(0.09),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 38,
                                backgroundColor: const Color(0xFFF0EAFB),
                                child: Icon(step.icon, size: 44, color: const Color(0xFF7C3AED)),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                step.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Color(0xFF7C3AED),
                                  fontFamily: 'ProductSans',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                step.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontFamily: 'ProductSans',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Navigation arrows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: _currentPage > 0 ? const Color(0xFF7C3AED) : Colors.grey[300],
                          size: 30),
                      onPressed: _currentPage > 0
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios,
                          color: _currentPage < steps.length - 1 ? const Color(0xFF7C3AED) : Colors.grey[300],
                          size: 30),
                      onPressed: _currentPage < steps.length - 1
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Automation info card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  shadowColor: Colors.deepPurple.withOpacity(0.10),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.auto_mode, color: Color(0xFF7C3AED), size: 28),
                            SizedBox(width: 10),
                            Text(
                              'Smart Automation',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Our automation software will securely read your booking data and, if you enable Auto Alternate Date, it will keep checking for train availability for up to 7 days. As soon as a seat opens up, your ticket will be booked automatically—no manual effort needed!\n\nUpcoming features: Auto upgrade to a higher class, auto break your journey for better chances, and auto-booking on alternate trains.\n\nSit back, relax, and let us work our magic. More smart features coming soon!',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontFamily: 'ProductSans',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.upgrade, color: Color(0xFF7C3AED), size: 22),
                            SizedBox(width: 10),
                            Icon(Icons.alt_route, color: Color(0xFF7C3AED), size: 22),
                            SizedBox(width: 10),
                            Icon(Icons.train, color: Color(0xFF7C3AED), size: 22),
                            SizedBox(width: 10),
                            Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 22),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Got it button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF7C3AED),
                    ),
                    child: const Text(
                      'Got it! Start Tatkal Mode',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}


class _GuideStep {
  final String title;
  final String description;
  final IconData icon;
  const _GuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
