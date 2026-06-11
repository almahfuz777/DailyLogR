import 'package:flutter/material.dart';
import 'package:dailylogr/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Daily Logging',
      'description': 'Reflect on your journey with one entry a day. Look back over time and see how your life has evolved.',
      'icon': Icons.edit_document,
      'color': Colors.blue,
    },
    {
      'title': 'Track Your Mood',
      'description': 'Rate your days out of 5 stars and track your emotional trends over time.',
      'icon': Icons.insights,
      'color': Colors.purple,
    },
    {
      'title': 'Safe & Secure',
      'description': 'Local-first design. Your thoughts and journals stay securely stored on your device.',
      'icon': Icons.shield_outlined,
      'color': Colors.green,
    },
    {
      'title': 'Never lose your data',
      'description': 'Sign in to back up and sync your journal across your devices automatically when you\'re online.',
      'icon': Icons.cloud_sync_outlined,
      'color': Colors.teal,
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_onboarding', false);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _onboardingData.length - 1;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final scale = (screenHeight / 800.0).clamp(0.7, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                final data = _onboardingData[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0 * scale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        data['icon'],
                        size: 120 * scale,
                        color: data['color'],
                      ),
                      SizedBox(height: 48 * scale),
                      Text(
                        data['title'],
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: (Theme.of(context).textTheme.headlineMedium?.fontSize ?? 28.0) * scale,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24 * scale),
                      Text(
                        data['description'],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.5,
                              fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0) * scale,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.0 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (hidden on first page)
                  AnimatedOpacity(
                    opacity: _currentPage == 0 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _currentPage == 0 ? null : _previousPage,
                      child: const Text('Back'),
                    ),
                  ),

                  // Page Indicators
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: _currentPage == index ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started Button
                  FilledButton(
                    onPressed: _nextPage,
                    child: Text(isLastPage ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
