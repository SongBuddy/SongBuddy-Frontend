import 'package:flutter/material.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyPosts = [
      {
        "username": "Amin",
        "avatarUrl": "https://i.pravatar.cc/150?img=1",
        "trackTitle": "Blinding Lights",
        "artist": "The Weeknd",
        "coverUrl": "https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2",
        "description": "This track always gives me a boost of energy 🚀🔥",
      },
      {
        "username": "Sara",
        "avatarUrl": "https://i.pravatar.cc/150?img=2",
        "trackTitle": "Levitating",
        "artist": "Dua Lipa",
        "coverUrl": "https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2",
        "description": "",
      },
      {
        "username": "John",
        "avatarUrl": "https://i.pravatar.cc/150?img=3",
        "trackTitle": "As It Was",
        "artist": "Harry Styles",
        "coverUrl": "https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2",
        "description": "Makes me feel nostalgic ✨",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SongBuddy", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          )
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search users or songs...",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // Feed
          Expanded(
            child: ListView.builder(
              itemCount: dummyPosts.length,
              itemBuilder: (context, index) {
                final post = dummyPosts[index];
                return _MusicPostCard(
                  username: post["username"]!,
                  avatarUrl: post["avatarUrl"]!,
                  trackTitle: post["trackTitle"]!,
                  artist: post["artist"]!,
                  coverUrl: post["coverUrl"]!,
                  description: post["description"]!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicPostCard extends StatefulWidget {
  final String username;
  final String avatarUrl;
  final String trackTitle;
  final String artist;
  final String coverUrl;
  final String description;

  const _MusicPostCard({
    required this.username,
    required this.avatarUrl,
    required this.trackTitle,
    required this.artist,
    required this.coverUrl,
    required this.description,
  });

  @override
  State<_MusicPostCard> createState() => _MusicPostCardState();
}

class _MusicPostCardState extends State<_MusicPostCard>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  int likeCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(widget.avatarUrl),
            ),
            title: Text(widget.username,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: TextButton(
              onPressed: () {},
              child: const Text("Follow", style: TextStyle(color: Colors.green)),
            ),
          ),

          // Track cover with gradient overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 240, 
                ),
              ),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.trackTitle,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text(widget.artist,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              )
            ],
          ),

          // Description
          if (widget.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                widget.description,
                style: const TextStyle(
                    fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic),
              ),
            ),

          // Interaction bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      isLiked = !isLiked;
                      likeCount += isLiked ? 1 : -1;
                    });
                  },
                ),
                Text("$likeCount",
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.white70),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white70),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
