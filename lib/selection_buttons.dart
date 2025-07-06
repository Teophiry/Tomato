import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'area_selection.dart';
import 'caring.dart';
import 'disease_control.dart';
import 'seed_selection.dart';
import 'contact.dart';
import 'watering.dart';

class SelectionButtons extends StatefulWidget {
  const SelectionButtons({super.key});

  @override
  State<SelectionButtons> createState() => _SelectionButtonsState();
}

class _SelectionButtonsState extends State<SelectionButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Button data
  final List<Map<String, dynamic>> buttons = [
    {
      'title': 'Seed Selection',
      'icon': Icons.grass,
      'route': const SeedSelection(),
      'tooltip': 'Choose the best tomato seeds',
      'gradient': [Colors.green.shade400, Colors.green.shade700],
    },
    {
      'title': 'Area Selection',
      'icon': Icons.landscape,
      'route': const AreaSelection(),
      'tooltip': 'Find the perfect planting spot',
      'gradient': [Colors.green.shade400, Colors.green.shade700],
    },
    {
      'title': 'Caring Activity',
      'icon': Icons.local_florist,
      'route': const CaringActivity(),
      'tooltip': 'Nurture your tomato plants',
      'gradient': [Colors.green.shade400, Colors.green.shade700],
    },
    {
      'title': 'Disease Control',
      'icon': Icons.bug_report,
      'route': const DiseaseControlPage(),
      'tooltip': 'Protect plants from diseases',
      'gradient': [Colors.green.shade400, Colors.green.shade700],
    },
  ];

  // Reusable button widget
  Widget _buildButton(Map<String, dynamic> button) {
    return Tooltip(
      message: button['tooltip'],
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => button['route']),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: button['gradient'],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(button['icon'], color: Colors.white, size: 50),
              const SizedBox(height: 10),
              Text(
                button['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/image 5.jpg', height: 30, width: 30),
            const SizedBox(width: 8),
            const Text(
              'Tomato Plantation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 4,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/image 5.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.5, // Adjusted for clarity
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.green.shade700, width: 2),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white38,
                    child: Icon(
                      Icons.local_florist,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tomato Plantation',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.white70,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cultivate Your Passion',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.white70,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFFE53935)),
              title: const Text(
                'Home',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail, color: Color(0xFFE53935)),
              title: const Text(
                'Contact Us',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactUsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Color(0xFFE53935)),
              title: const Text(
                'Watering Schedule',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WateringSchedule(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFFE53935)),
              title: const Text(
                'About',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Tomato Plantation App',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 Tomato Plantation',
                  children: [
                    const Text(
                      'Grow healthy tomatoes with expert tips and tools.',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image 4.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Welcome Banner
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, // Full opacity for readability
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.green.shade700.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_florist,
                              color: Colors.red.shade800,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Grow Your Tomatoes with Passion',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.white70,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unlock the secrets to thriving tomato plants!',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Grid of Buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: buttons.length,
                    itemBuilder: (context, index) {
                      return Transform.scale(
                        scale: 1.0,
                        child: _buildButton(buttons[index]),
                      );
                    },
                  ),
                ),
                // Animated Divider
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Footer with Explanation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, // Full opacity for readability
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.green.shade700.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.local_florist,
                          color: Colors.green,
                          size: 30,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Why Grow Tomatoes?',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.white70,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tomato planting is a rewarding journey that connects you with nature. Enjoy fresh, homegrown tomatoes packed with flavor and nutrients. Our app guides you through every step—from selecting the best seeds to protecting your plants from diseases. Start today and cultivate a bountiful harvest with expert tips on soil, watering, and care',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          '"Plant today, harvest tomorrow"',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: const Text(
                'Tomato Growing Guide',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              content: const SingleChildScrollView(
                child: Text(
                  'Get started with your tomato plantation:\n'
                  '• Seed Selection: Choose high-quality seeds for better yield.\n'
                  '• Area Selection: Pick a sunny, well-drained spot.\n'
                  '• Caring Activity: Learn watering and pruning tips.\n'
                  '• Disease Control: Prevent and treat common issues.\n'
                  'Use the drawer for more resources or contact us for help',
                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        backgroundColor: const Color(0xFFE53935),
        elevation: 6,
        tooltip: 'Quick Guide',
        child: const Icon(Icons.help_outline, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}