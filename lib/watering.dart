import 'package:flutter/material.dart';

class WateringSchedule extends StatelessWidget {
  const WateringSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Watering Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE53935), // Tomato red
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image 3.jpg'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCE4EC), // Light pink
              Color(0xFFF1F8E9), // Light green
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tomato Watering Guide',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F), // Darker red
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem(
                          icon: Icons.water_drop,
                          text: 'Tomatoes need consistent moisture to thrive. '
                              'Water deeply to encourage strong root growth.',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          icon: Icons.schedule,
                          text:
                              'Water every 2-3 days, adjusting based on weather '
                              'and soil conditions.',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          icon: Icons.wb_sunny,
                          text:
                              'Water early in the morning to reduce evaporation '
                              'and prevent leaf diseases.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Watering Schedule',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                      },
                      children: [
                        _buildTableRow('Stage', 'Watering Frequency'),
                        _buildTableRow('Seedling', 'Daily, keep soil moist'),
                        _buildTableRow(
                            'Vegetative', 'Every 2-3 days, 1-2 inches'),
                        _buildTableRow(
                            'Flowering', 'Every 2 days, 1.5-2 inches'),
                        _buildTableRow('Fruiting', 'Every 2-3 days, 2 inches'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pro Tips',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTipItem('Use mulch to retain soil moisture.'),
                        _buildTipItem(
                            'Check soil moisture with your finger before watering.'),
                        _buildTipItem(
                            'Avoid overhead watering to prevent fungal diseases.'),
                        _buildTipItem(
                            'Ensure good drainage to prevent root rot.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Healthy watering, healthy tomatoes!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFE53935),
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF388E3C), // Green for tips
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String stage, String frequency) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            stage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            frequency,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
