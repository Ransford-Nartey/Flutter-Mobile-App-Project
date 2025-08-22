import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/first_time_service.dart';
import '../../auth/screens/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Cycle Farms',
      subtitle: 'Order High Quality Fish feeds with ease',
      image: 'assets/images/onboarding1.jpg',
    ),
    OnboardingPage(
      title: 'Wide Range of Feeds',
      subtitle: 'Choose from trusted feed brands for your farm',
      image: 'assets/images/onboarding2.jpg',
    ),
    OnboardingPage(
      title: 'Secure Payments',
      subtitle: 'Pay safely through multiple payment options',
      image: 'assets/images/onboarding3.jpg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await FirstTimeService.markOnboardingComplete();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8), // Light green background
      body: Stack(
        children: [
          // Full-screen page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Skip button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Bottom white card overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.6,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 40.0),
              child: _buildBottomCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen background image
        Image.asset(
          page.image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Dark overlay for better text readability on the card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.5),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pagination dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pages.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
                             decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: _currentPage == index
                     ? AppTheme.primaryColor
                     : Colors.grey.withOpacity(0.3),
               ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          _pages[_currentPage].title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Subtitle
        Text(
          _pages[_currentPage].subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 60),

        // Next button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String image;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.image,
  });
}
