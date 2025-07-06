import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'firebase_options.dart';
import 'selection_buttons.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomato Plantation App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  final List<Map<String, String>> tips = [
    {
      'title': 'Soil Preparation',
      'description':
          'Use well-drained, loamy soil with pH 6.0-6.8 for optimal growth.'
    },
    {
      'title': 'Sunlight Needs',
      'description':
          'Ensure 6-8 hours of direct sunlight daily for healthy plants.'
    },
    {
      'title': 'Watering Tips',
      'description':
          'Water deeply but infrequently to encourage strong root growth.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _logScreenView();
  }

  // Log screen view event
  Future<void> _logScreenView() async {
    await _analytics.logScreenView(
      screenName: 'HomePage',
      screenClass: 'HomePage',
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade300,
              Colors.green.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Tomato Plantation',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black45,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Welcome to Your Tomato Journey\n'
                              'Learn expert tips to grow juicy, healthy tomatoes in any climate.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            CarouselSlider(
                              options: CarouselOptions(
                                height: 120.0,
                                autoPlay: true,
                                enlargeCenterPage: true,
                                aspectRatio: 16 / 9,
                                autoPlayInterval: const Duration(seconds: 3),
                                onPageChanged: (index, reason) {
                                  _analytics.logEvent(
                                    name: 'carousel_tip_viewed',
                                    parameters: {
                                      'tip_title': ?tips[index]['title'],
                                      'screen': 'HomePage',
                                    },
                                  );
                                },
                              ),
                              items: tips.map((tip) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromRGBO(0, 0, 0, 0.1),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              tip['title']!,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              tip['description']!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        _analytics.logEvent(
                          name: 'get_started_clicked',
                          parameters: {'screen': 'HomePage'},
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SelectionButtons(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text('Get Started'),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    _analytics.logEvent(
                      name: 'quick_care_guide_opened',
                      parameters: {'screen': 'HomePage'},
                    );
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Quick Care Guide'),
                        content: const Text(
                          '1. Soil: Well-drained, pH 6.0-6.8\n'
                          '2. Sunlight: 6-8 hours daily\n'
                          '3. Water: Deep, infrequent watering\n'
                          '4. Support: Use stakes or cages\n'
                          '5. Pruning: Remove suckers for better yield',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _analytics.logEvent(
                                name: 'quick_care_guide_closed',
                                parameters: {'screen': 'HomePage'},
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.info),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}