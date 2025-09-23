import 'package:flutter/material.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          ListTile(leading: Icon(Icons.emoji_events_rounded), title: Text('Leaderboards'), subtitle: Text('Compare lifts and runs')),          
          Divider(height: 1),
          ListTile(leading: Icon(Icons.dynamic_feed_rounded), title: Text('Social Feed'), subtitle: Text('Coming soon')),          
          Divider(height: 1),
          ListTile(leading: Icon(Icons.share_rounded), title: Text('Shareables'), subtitle: Text('Create social-ready cards')),          
          Divider(height: 1),
          ListTile(leading: Icon(Icons.hub_rounded), title: Text('Strava Integration'), subtitle: Text('Connect to sync runs (planned)')),
        ],
      ),
    );
  }
}
