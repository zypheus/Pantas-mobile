import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search catalog...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/search');
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildQuickActionCard(
                  context,
                  icon: Icons.search,
                  label: 'Search\nCatalog',
                  onTap: () => Navigator.of(context).pushNamed('/search'),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.book,
                  label: 'My Borrowed\nBooks',
                  onTap: () => Navigator.of(context).pushNamed('/borrowed'),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.meeting_room,
                  label: 'Room\nReservation',
                  onTap: () => Navigator.of(context).pushNamed('/room_reservation'),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.feedback,
                  label: 'Feedback /\nSupport',
                  onTap: () => Navigator.of(context).pushNamed('/feedback'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reminders Section
            Text(
              'Reminders & Updates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildReminderCard(
              context,
              icon: Icons.warning,
              image: 'assets/defaultBook.png',
              title: 'No due date reminders',
              subtitle: 'Your borrowed items are all clear.',
              backgroundColor: Colors.blue.shade50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context, {
    required IconData icon,
    String? image,
    required String title,
    required String subtitle,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (image != null)
            Image.asset(
              image,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          else
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
