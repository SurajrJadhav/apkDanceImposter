import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class TutorialScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const TutorialScreen({
    super.key,
    this.isFirstLaunch = false,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to Dance Imposter',
      'description': 'The ultimate party game of dance, deception, and deduction!',
      'icon': 'music_note',
    },
    {
      'title': 'The Roles',
      'description': 'Most players hear a DANCE song and must dance to the beat.\n\nONE player is the IMPOSTER and hears a SAD song.',
      'icon': 'people',
    },
    {
      'title': 'The Goal',
      'description': 'The Imposter must blend in and pretend to dance.\n\nThe Dancers must find out who is out of sync!',
      'icon': 'search',
    },
  ];

  Future<void> _finishTutorial() async {
    if (widget.isFirstLaunch) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_tutorial', true);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity( 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(_pages[index]['icon']!),
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _pages[index]['title']!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _pages[index]['description']!,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  
                  // Next/Finish button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishTutorial();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? (widget.isFirstLaunch ? 'Get Started' : 'Close')
                          : 'Next',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'music_note':
        return Icons.music_note;
      case 'people':
        return Icons.people;
      case 'search':
        return Icons.search;
      default:
        return Icons.help;
    }
  }
}
