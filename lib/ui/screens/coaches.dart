import 'package:flutter/material.dart';

class CoachesScreen extends StatelessWidget {
  const CoachesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final coaches = const [
      _Coach('Ryan Bennett','Professional Coach','images/070ca691-20d2-4d45-8a63-f0a2d9e88565.jpeg',
        stats: ['180 Following','125K Followers','7+ Years']),
      _Coach('Regina Fly','Strength Coach','images/515 likes, 10 comments - evento_designs on January….jpeg',
        stats: ['120 Following','90K Followers','5+ Years']),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Coaches')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: coaches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _CoachCard(coach: coaches[i]),
      ),
    );
  }
}

class _Coach {
  final String name; final String title; final String image; final List<String> stats;
  const _Coach(this.name,this.title,this.image,{this.stats=const []});
}

class _CoachCard extends StatelessWidget {
  final _Coach coach;
  const _CoachCard({required this.coach});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundImage: AssetImage(coach.image), radius: 24),
        title: Text(coach.name),
        subtitle: Text(coach.title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CoachProfileScreen(coach: coach))),
      ),
    );
  }
}

class CoachProfileScreen extends StatelessWidget {
  final _Coach coach;
  const CoachProfileScreen({super.key, required this.coach});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: CircleAvatar(backgroundImage: AssetImage(coach.image), radius: 48)),
          const SizedBox(height: 12),
          Center(child: Text(coach.name, style: Theme.of(context).textTheme.titleLarge)),
          Center(child: Text(coach.title)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: coach.stats.map((s) => Chip(label: Text(s))).toList()),
          const SizedBox(height: 16),
          Text('Programs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(child: ListTile(leading: const Icon(Icons.play_arrow_rounded), title: const Text('Strength Starter'), subtitle: const Text('15 Minute'))),
          Card(child: ListTile(leading: const Icon(Icons.play_arrow_rounded), title: const Text('Endurance Builder'), subtitle: const Text('20 Minute'))),
          Card(child: ListTile(leading: const Icon(Icons.play_arrow_rounded), title: const Text('Power Squat'), subtitle: const Text('25 Minute'))),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: (){}, icon: const Icon(Icons.bolt_rounded), label: const Text('Train with Me!')),
        ],
      ),
    );
  }
}
