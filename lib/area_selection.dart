import 'package:flutter/material.dart';

class AreaSelection extends StatelessWidget {
  const AreaSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tomato Plantation Guide',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image 5.jpg'),
            fit: BoxFit.cover,
            opacity: 0.5, // Added opacity for clearer appearance
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header Section
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Choose the Best Area for Your Tomatoes',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
            ),
            const Text(
              'Select an area with the right conditions to ensure healthy tomato growth.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
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
            const SizedBox(height: 20),

            // Area Cards
            _buildAreaCard(
              context,
              title: 'Sunny Hillside',
              conditions: [
                'Soil: Well-drained, loamy',
                'Sunlight: 8+ hours daily',
                'Water: Moderate irrigation',
                'Temperature: 20-30°C',
              ],
              suitability: 'Excellent',
              suitabilityColor: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildAreaCard(
              context,
              title: 'Shaded Valley',
              conditions: [
                'Soil: Clay-heavy, retains water',
                'Sunlight: 4-6 hours daily',
                'Water: Natural rainfall',
                'Temperature: 15-25°C',
              ],
              suitability: 'Poor',
              suitabilityColor: Colors.red,
            ),
            const SizedBox(height: 16),
            _buildAreaCard(
              context,
              title: 'Flat Farmland',
              conditions: [
                'Soil: Sandy loam, fertile',
                'Sunlight: 6-8 hours daily',
                'Water: Easy irrigation access',
                'Temperature: 18-28°C',
              ],
              suitability: 'Good',
              suitabilityColor: Colors.orange,
            ),

            // Tips Section
            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                'Tips for Success',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // Full opacity for readability
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Test soil pH (ideal: 6.0-6.8)\n'
                    '• Ensure good drainage to prevent root rot\n'
                    '• Rotate crops to maintain soil health\n'
                    '• Monitor temperature to avoid blossom drop',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
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

  Widget _buildAreaCard(
    BuildContext context, {
    required String title,
    required List<String> conditions,
    required String suitability,
    required Color suitabilityColor,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: suitabilityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: suitabilityColor, width: 1),
                  ),
                  child: Text(
                    suitability,
                    style: TextStyle(
                      color: suitabilityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: conditions
                  .map((condition) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                condition,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected: $title')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Select Area',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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