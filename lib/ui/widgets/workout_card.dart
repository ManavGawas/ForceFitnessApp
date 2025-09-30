import 'package:flutter/material.dart';

class WorkoutPreset {
  final String title;
  final String image;
  final String tag; // Beginner/Intermediate/Advanced
  final int minutes;
  final String category; // Chest/Back/Arms/etc
  final List<String> steps;

  const WorkoutPreset(
    this.title,
    this.image,
    this.tag,
    this.minutes,
    this.category, {
    this.steps = const [],
  });
}

class WorkoutCard extends StatelessWidget {
  final WorkoutPreset item;
  final VoidCallback? onTap;
  const WorkoutCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(item.image, fit: BoxFit.cover)),
            Positioned(
              left: 8, top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text('${item.tag} • ${item.category}'),
              ),
            ),
            Positioned(
              left: 8, right: 8, bottom: 8,
              child: Row(children: [
                Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Row(children: [const Icon(Icons.timer, size: 16), Text(' ${item.minutes} min')])
              ]),
            )
          ]),
        ),
      ),
    );
  }
}
