import 'package:flutter/material.dart';

class SeedSelection extends StatefulWidget {
  const SeedSelection({super.key});

  @override
  State<SeedSelection> createState() => _SeedSelectionState();
}

class _SeedSelectionState extends State<SeedSelection> {
  String _selectedFilter = 'All'; // Default filter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tomato Seed Selection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[700],
        elevation: 0,
        actions: [
          // Filter Dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(
                  value: 'Beginner-Friendly', child: Text('Beginner-Friendly')),
              const PopupMenuItem(
                  value: 'Intermediate', child: Text('Intermediate')),
              const PopupMenuItem(value: 'Advanced', child: Text('Advanced')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/image 3.jpg'),
            fit: BoxFit.cover,
            opacity: 0.3, // Adjust opacity for mobile readability
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[100]!, Colors.red[400]!],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header Section
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Choose the Best Tomato Seeds',
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
              'Select seeds based on soil, weather, and your experience level.',
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

            // Seed Type Classifications
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Seed Type Classifications',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Determinate: Compact plants, produce fruit all at once, ideal for canning.\n'
                    '• Indeterminate: Vining plants, produce fruit continuously, great for fresh eating.\n'
                    '• Hybrid: Cross-bred for disease resistance and high yield, suited for commercial use.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Seed Cards
            if (_selectedFilter == 'All' ||
                _selectedFilter == 'Beginner-Friendly')
              _buildSeedCard(
                context,
                title: 'Cherry Tomato Seeds',
                type: 'Indeterminate',
                characteristics: [
                  'Soil: Well-drained, loamy (pH 6.0-6.8)',
                  'Weather: Warm, 20-30°C',
                  'Growth: Fast, 60-70 days to harvest',
                  'Disease Resistance: High (Fusarium, Verticillium)',
                  'Yield: High, small fruits',
                  'Best For: Small gardens, containers',
                ],
                suitability: 'Beginner-Friendly',
                suitabilityColor: Colors.green,
                onLearnMore: () {
                  _showSeedDetails(context, 'Cherry Tomato Seeds',
                      'Sweet and bite-sized, perfect for salads and snacking. Easy to grow in small spaces.');
                },
              ),
            if (_selectedFilter == 'All' ||
                _selectedFilter == 'Beginner-Friendly')
              const SizedBox(height: 16),
            if (_selectedFilter == 'All' || _selectedFilter == 'Intermediate')
              _buildSeedCard(
                context,
                title: 'Beefsteak Tomato Seeds',
                type: 'Determinate',
                characteristics: [
                  'Soil: Rich, fertile loam (pH 6.2-6.8)',
                  'Weather: Hot, 22-32°C',
                  'Growth: Slower, 80-90 days to harvest',
                  'Disease Resistance: Moderate',
                  'Yield: Moderate, large fruits',
                  'Best For: Large fruit production',
                ],
                suitability: 'Intermediate',
                suitabilityColor: Colors.orange,
                onLearnMore: () {
                  _showSeedDetails(context, 'Beefsteak Tomato Seeds',
                      'Large, juicy tomatoes ideal for sandwiches and slicing. Requires staking and pruning.');
                },
              ),
            if (_selectedFilter == 'All' || _selectedFilter == 'Intermediate')
              const SizedBox(height: 16),
            if (_selectedFilter == 'All' || _selectedFilter == 'Advanced')
              _buildSeedCard(
                context,
                title: 'Heirloom Tomato Seeds',
                type: 'Indeterminate',
                characteristics: [
                  'Soil: Sandy loam, well-drained (pH 6.0-7.0)',
                  'Weather: Moderate, 18-28°C',
                  'Growth: Variable, 70-85 days to harvest',
                  'Disease Resistance: Low',
                  'Yield: Variable, unique fruits',
                  'Best For: Unique flavors, organic farming',
                ],
                suitability: 'Advanced',
                suitabilityColor: Colors.red,
                onLearnMore: () {
                  _showSeedDetails(context, 'Heirloom Tomato Seeds',
                      'Offers diverse flavors and colors but requires careful management due to lower disease resistance.');
                },
              ),

            // Tips Section
            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                'Seed Selection Tips',
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
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Match seeds to your climate and soil type\n'
                    '• Choose disease-resistant varieties for easier care\n'
                    '• Start with beginner-friendly seeds if new to planting\n'
                    '• Purchase from trusted suppliers for quality assurance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
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

  Widget _buildSeedCard(
    BuildContext context, {
    required String title,
    required String type,
    required List<String> characteristics,
    required String suitability,
    required Color suitabilityColor,
    required VoidCallback onLearnMore,
  }) {
    return Card(
      elevation: 4,
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
                    color: Colors.red,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: suitabilityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    suitability,
                    style: TextStyle(
                      color: suitabilityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Type: $type',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: characteristics
                  .map((characteristic) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                characteristic,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onLearnMore,
                  child: const Text(
                    'Learn More',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: $title')),
                    );
                  },
                  child: const Text(
                    'Select Seed',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSeedDetails(
      BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
