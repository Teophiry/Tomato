import 'package:flutter/material.dart';

class CaringActivity extends StatelessWidget {
  const CaringActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tomato Plantation Care',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.redAccent, Colors.red[700]!],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Image with Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/image 4.jpg'),
                  fit: BoxFit.cover,
                ),
                color: Colors.black.withOpacity(0.3), // Subtle overlay
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Caring for Your Tomatoes',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black54,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Text(
                'Follow these steps to ensure healthy tomato growth.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Sections
              Section(
                title: 'Stage of Plantation',
                icon: Icons.local_florist,
                description:
                    'Select small tomato seedlings (about pencil diameter) for planting. Avoid large seedlings with flowers or fruit, as they divert energy from root growth. Remove flowers/fruit at planting and harden off seedlings by gradually exposing them to outdoor conditions over a week.\n\n'
                    'Tomatoes can grow adventitious roots along their stems. Plant them horizontally in a shallow trench, removing all but the top 5-7 leaves. This encourages a stronger root system, leading to healthier plants.',
                backgroundColor: Colors.green[100]!.withOpacity(0.9),
              ),
              const SizedBox(height: 16),
              Section(
                title: 'Fertilizer',
                icon: Icons.spa,
                description:
                    'Fertilizing tomatoes requires balance. Refer to a soil test to check Nitrogen, Potassium, and Phosphorus levels. If adequate, minimal fertilization is needed. For low levels, apply a light feed at planting, up to 3 times every 2 weeks, and once more when tomatoes are half mature size.\n\n'
                    'Over-fertilization leads to lush foliage but no flowers, as the plant feels no need to reproduce. A slight stress level encourages fruit production.',
                backgroundColor: Colors.blue[100]!.withOpacity(0.9),
              ),
              const SizedBox(height: 16),
              Section(
                title: 'Harvest',
                icon: Icons.agriculture,
                description:
                    'Harvest tomatoes at the “breaker” stage, when the blossom end starts coloring. For non-red varieties (purple, green, yellow), look for their specific hue. Pink tomatoes can ripen off the vine, but vine-ripened ones taste better.\n\n'
                    'Use a sharp knife or scissors to cut tomatoes, avoiding vine damage. Harvest early or late in the day to avoid heat stress.',
                backgroundColor: Colors.yellow[100]!.withOpacity(0.9),
              ),
              const SizedBox(height: 16),
              Section(
                title: 'More Information',
                icon: Icons.info,
                description:
                    'Explore additional resources for advanced tomato care techniques.\n\n'
                    '• Visit local agricultural extensions for region-specific advice.\n'
                    '• Join online forums for tips from experienced growers.\n'
                    '• Check reputable websites for pest and disease management.',
                backgroundColor: Colors.orange[100]!.withOpacity(0.9),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening external resources...')),
          );
        },
        backgroundColor: Colors.redAccent,
        tooltip: 'Explore More Resources',
        child: const Icon(Icons.link),
      ),
    );
  }
}

class Section extends StatefulWidget {
  final String title;
  final IconData icon;
  final String description;
  final Color backgroundColor;

  const Section({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.backgroundColor,
  });

  @override
  _SectionState createState() => _SectionState();
}

class _SectionState extends State<Section> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.icon,
                  size: 28,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.redAccent,
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: -1.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



