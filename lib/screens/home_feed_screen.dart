// lib/screens/home_feed_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/social_connections.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Feed'),
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 1000 : double.infinity),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    // Social connections card
                    // SocialConnectionsCard(),
                      
                    SizedBox(height: 12),

                    // Placeholder: feed content below
                   _FeedPlaceholder(),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
   //   bottomNavigationBar: const BottomNavBar(currentIndex: 0, onTap: null),
    );
  }
}

class _FeedPlaceholder extends StatelessWidget {
  const _FeedPlaceholder();

  @override
  Widget build(BuildContext context) {
    // A responsive placeholder "feed" — replace with real feed content
    return Column(
      children: List.generate(
        6,
        (i) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text('A${i + 1}')),
            title: Text('Shared track #${i + 1}'),
            subtitle: const Text('Artist • Album'),
            trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          ),
        ),
      ),
    );
  }
}
