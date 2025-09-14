// lib/widgets/social_connections.dart
import 'package:flutter/material.dart';
import 'connection_button.dart';
import 'progress_indicator.dart';
import '../models/connection_status.dart';
import '../constants/app_colors.dart';

class SocialConnectionsCard extends StatefulWidget {
  const SocialConnectionsCard({super.key});

  @override
  State<SocialConnectionsCard> createState() => _SocialConnectionsCardState();
}

class _SocialConnectionsCardState extends State<SocialConnectionsCard> {
  ConnectionStatus spotifyStatus = ConnectionStatus.idle;
  ConnectionStatus addFriendsStatus = ConnectionStatus.idle;
  ConnectionStatus inviteStatus = ConnectionStatus.idle;

  int get completedCount {
    int sum = 0;
    if (spotifyStatus == ConnectionStatus.success) sum++;
    if (addFriendsStatus == ConnectionStatus.success) sum++;
    if (inviteStatus == ConnectionStatus.success) sum++;
    return sum;
  }

  Future<bool> _connectSpotify() async {
    setState(() => spotifyStatus = ConnectionStatus.loading);
    await Future.delayed(const Duration(seconds: 2));
    final success = true; // simulate success
    setState(() => spotifyStatus = success ? ConnectionStatus.success : ConnectionStatus.error);
    return success;
  }

  Future<bool> _addFriends() async {
    setState(() => addFriendsStatus = ConnectionStatus.loading);
    await Future.delayed(const Duration(seconds: 1));
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _FindFriendsScreen()),
    );
    final success = result ?? false;
    setState(() => addFriendsStatus = success ? ConnectionStatus.success : ConnectionStatus.idle);
    return success;
  }

  Future<bool> _inviteFriends() async {
    setState(() => inviteStatus = ConnectionStatus.loading);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => inviteStatus = ConnectionStatus.success);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final spacing = 12.0;

          final spotifyButton = ConnectionButton(
            label: 'Connect with Spotify',
            leading: SizedBox(
              width: 22,
              height: 22,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  'https://storage.googleapis.com/pr-newsroom-wp/1/2018/11/Spotify_Logo_RGB_Green.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 20),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF1DB954),
            foregroundColor: Colors.white,
            onPressed: _connectSpotify,
          );

          final addFriendsButton = ConnectionButton(
            label: 'Add Friends',
            leading: const Icon(Icons.person_add, size: 20),
            onPressed: _addFriends,
          );

          final inviteFriendsButton = ConnectionButton(
            label: 'Invite Friends',
            leading: const Icon(Icons.share, size: 18),
            onPressed: _inviteFriends,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(Icons.people_alt, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Social Connections',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                  if (isWide)
                    Text('${completedCount}/3', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 12),

              // Progress
              ConnectionProgressIndicator(totalSteps: 3, completedSteps: completedCount),
              const SizedBox(height: 16),

              // Buttons (responsive)
              if (isWide)
                Row(
                  children: [
                    Expanded(child: spotifyButton),
                    SizedBox(width: spacing),
                    Expanded(child: addFriendsButton),
                    SizedBox(width: spacing),
                    Expanded(child: inviteFriendsButton),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    spotifyButton,
                    SizedBox(height: spacing),
                    addFriendsButton,
                    SizedBox(height: spacing),
                    inviteFriendsButton,
                  ],
                ),

              // Status message
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStatusMessage(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusMessage() {
    if (spotifyStatus == ConnectionStatus.error) {
      return _buildMessageRow(Icons.error_outline, 'Failed to connect Spotify. Try again.');
    }
    if (addFriendsStatus == ConnectionStatus.error) {
      return _buildMessageRow(Icons.error_outline, 'Could not find friends. Try again.');
    }
    if (inviteStatus == ConnectionStatus.error) {
      return _buildMessageRow(Icons.error_outline, 'Invite failed. Check permissions.');
    }

    if (completedCount == 3) {
      return _buildMessageRow(Icons.celebration, 'All connections complete. Enjoy SongBuddy!');
    }

    if (completedCount > 0) {
      return _buildMessageRow(Icons.check_circle_outline, '$completedCount step(s) completed.');
    }

    return const SizedBox.shrink();
  }

  Widget _buildMessageRow(IconData icon, String text) {
    return Row(
      key: ValueKey(text),
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

// Simple placeholder for finding friends
class _FindFriendsScreen extends StatelessWidget {
  const _FindFriendsScreen();

  @override
  Widget build(BuildContext context) {
    final list = List.generate(12, (i) => 'Friend ${i + 1}');
    return Scaffold(
      appBar: AppBar(title: const Text('Find Friends')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, i) => ListTile(
          leading: CircleAvatar(child: Text(list[i].split(' ').last)),
          title: Text(list[i]),
          trailing: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: list.length,
      ),
    );
  }
}
