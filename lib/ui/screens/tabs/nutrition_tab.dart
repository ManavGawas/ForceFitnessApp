import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/nutrition.dart';
import '../../../services/providers/auth_provider.dart';
import '../../../services/providers/selected_date_provider.dart';
import '../../../services/repositories.dart';
import '../../widgets/common.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../widgets/branded_scaffold.dart';
import '../../../services/nutrition_lookup_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/water.dart';
import '../../../models/sleep.dart';

class NutritionTab extends StatelessWidget {
  const NutritionTab({super.key});

  Future<void> _showAddDialog(BuildContext context, String uid, DateTime day) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final kcal = TextEditingController();
    final protein = TextEditingController();
    final carbs = TextEditingController();
    final fats = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Nutrition Entry'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name (optional)')),
              TextFormField(controller: kcal, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number, validator: (v) => (v==null||v.isEmpty)?'Required':null),
              Row(children: [
                Expanded(child: TextFormField(controller: protein, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: carbs, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: fats, decoration: const InputDecoration(labelText: 'Fats (g)'), keyboardType: TextInputType.number)),
              ]),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final entry = NutritionEntry(
                id: '',
                date: day,
                name: name.text.trim().isEmpty ? '' : name.text.trim(),
                calories: int.tryParse(kcal.text) ?? 0,
                protein: int.tryParse(protein.text) ?? 0,
                carbs: int.tryParse(carbs.text) ?? 0,
                fats: int.tryParse(fats.text) ?? 0,
              );
              await NutritionRepository().add(uid, entry);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    final day = context.watch<SelectedDateProvider>().day;
    final dateLabel = DateFormat('EEE, MMM d').format(day);
    return BrandedScaffold(
      appBar: AppBar(title: Text('Nutrition • $dateLabel')),
      body: uid == null
            ? const EmptyState('Sign-in required to load nutrition')
            : StreamBuilder<List<NutritionEntry>>(
                stream: NutritionRepository().byDay(uid, day),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entries = snapshot.data ?? [];
                  final totalKcal = entries.fold<int>(0, (s, e) => s + e.calories);
                  final totalP = entries.fold<int>(0, (s, e) => s + e.protein);
                  final totalC = entries.fold<int>(0, (s, e) => s + e.carbs);
                  final totalF = entries.fold<int>(0, (s, e) => s + e.fats);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    children: [
                      // Compact hydration + mini sleep summary
                      SizedBox(
                        height: 70,
                        child: Row(children: [
                          Expanded(child: _HydrationChip(uid: uid, day: day)),
                          const SizedBox(width: 8),
                          Expanded(child: _SleepMini(uid: uid, day: day)),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      // Totals as stat cards
                      LayoutBuilder(builder: (context, c) {
                        final narrow = c.maxWidth < 360;
                        final gap = SizedBox(width: narrow ? 6 : 8);
                        final children = [
                          Expanded(child: _StatCard(title: 'Calories', value: '$totalKcal', unit: 'kcal', color: Theme.of(context).colorScheme.error)),
                          gap,
                          Expanded(child: _StatCard(title: 'Protein', value: '$totalP', unit: 'g', color: Theme.of(context).colorScheme.primary)),
                          gap,
                          Expanded(child: _StatCard(title: 'Carbs', value: '$totalC', unit: 'g', color: Theme.of(context).colorScheme.tertiary)),
                        ];
                        return Row(children: children);
                      }),
                      const SizedBox(height: 8),
                      // Macro bars (relative to goals if available)
                      StreamBuilder<UserProfile>(
                        stream: uid == null ? const Stream.empty() : UserProfileRepository().stream(uid),
                        builder: (context, profSnap) {
                          final prof = profSnap.data;
                          final kcalGoal = prof?.dailyCaloriesGoal ?? 2000;
                          final pGoal = prof?.dailyProteinGoal ?? 150;
                          final cGoal = prof?.dailyCarbsGoal ?? 300;
                          final fGoal = prof?.dailyFatsGoal ?? 70;
                          return Column(children: [
                            _MacroBar(label: 'Calories', value: totalKcal.toDouble(), goal: kcalGoal.toDouble(), color: Theme.of(context).colorScheme.error),
                            const SizedBox(height: 6),
                            _MacroBar(label: 'Protein', value: totalP.toDouble(), goal: pGoal.toDouble(), color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 6),
                            _MacroBar(label: 'Carbs', value: totalC.toDouble(), goal: cGoal.toDouble(), color: Theme.of(context).colorScheme.tertiary),
                            const SizedBox(height: 6),
                            _MacroBar(label: 'Fats', value: totalF.toDouble(), goal: fGoal.toDouble(), color: Colors.amber.shade700),
                          ]);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (entries.isEmpty)
                        const EmptyState('No entries yet')
                      else
                        ...entries.map((e) => Card(
                              child: ListTile(
                                leading: CircleAvatar(child: const Icon(Icons.restaurant_rounded)),
                                title: Text(e.name.isEmpty ? 'Entry' : e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('P ${e.protein} • C ${e.carbs} • F ${e.fats}'),
                                trailing: Text('${e.calories} kcal'),
                              ),
                            )),
                    ],
                  );
                },
              ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final action = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  builder: (sheetCtx) => SafeArea(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(leading: const Icon(Icons.qr_code_scanner_rounded), title: const Text('Scan barcode'), onTap: () => Navigator.pop(sheetCtx, 'scan')),
                      ListTile(leading: const Icon(Icons.add_rounded), title: const Text('Add manually'), onTap: () => Navigator.pop(sheetCtx, 'manual')),
                    ]),
                  ),
                );
                if (action == 'manual') {
                  // Manual add
                  // ignore: use_build_context_synchronously
                  await _showAddDialog(context, uid, day);
                } else if (action == 'scan') {
                  // ignore: use_build_context_synchronously
                  final code = await Navigator.of(context).push<String>(
                    MaterialPageRoute(builder: (_) => const _BarcodeScanPage()),
                  );
                  if (code != null) {
                    // Try a real lookup first, then fall back
                    final item = await NutritionLookupService.byBarcode(code, uid: uid);
                    if (item != null) {
                      // Ask user: use serving, or grams from 100g base
                      final choice = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        builder: (ctx) => SafeArea(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            ListTile(
                              title: Text(item.name),
                              subtitle: Text(item.servingSize != null ? 'Serving: ${item.servingSize}' : 'per 100g data'),
                            ),
                            if (item.kcalServing != null)
                              ListTile(
                                leading: const Icon(Icons.restaurant_menu_rounded),
                                title: const Text('Add 1 serving'),
                                subtitle: Text('${item.kcalServing} kcal'),
                                onTap: () => Navigator.pop(ctx, 'serving'),
                              ),
                            ListTile(
                              leading: const Icon(Icons.scale_rounded),
                              title: const Text('Add by grams'),
                              subtitle: const Text('Use per 100g values'),
                              onTap: () => Navigator.pop(ctx, 'grams'),
                            ),
                          ]),
                        ),
                      );
                      int kcal = 0, p = 0, c = 0, f = 0;
                      if (choice == 'serving' && item.kcalServing != null) {
                        kcal = item.kcalServing ?? 0;
                        p = item.proteinServing ?? 0;
                        c = item.carbsServing ?? 0;
                        f = item.fatsServing ?? 0;
                      } else {
                        final gramsStr = await showDialog<String>(
                          context: context,
                          builder: (ctx) {
                            final gramsCtrl = TextEditingController(text: '100');
                            return AlertDialog(
                              title: const Text('Enter grams'),
                              content: TextField(
                                controller: gramsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Grams', hintText: 'e.g., 75'),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, gramsCtrl.text), child: const Text('Add')),
                              ],
                            );
                          },
                        );
                        final grams = int.tryParse(gramsStr ?? '') ?? 100;
                        double m = grams / 100.0;
                        kcal = ((item.kcal100 ?? 0) * m).round();
                        p = ((item.protein100 ?? 0) * m).round();
                        c = ((item.carbs100 ?? 0) * m).round();
                        f = ((item.fats100 ?? 0) * m).round();
                      }
                      final entry = NutritionEntry(
                        id: '',
                        date: day,
                        name: item.name,
                        calories: kcal,
                        protein: p,
                        carbs: c,
                        fats: f,
                      );
                      await NutritionRepository().add(uid, entry);
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${item.name}')),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.restaurant),
              label: const Text('Add Food'),
            ),
    );
  }
}

class _HydrationChip extends StatelessWidget {
  final String uid; final DateTime day;
  const _HydrationChip({required this.uid, required this.day});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WaterEntry>>(
      stream: WaterRepository().byDay(uid, day),
      builder: (context, snap) {
        final ml = (snap.data ?? const []).fold<int>(0, (s, e) => s + e.ml);
        final cups = (ml / 250).floor();
        return Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          const Icon(Icons.opacity_rounded), const SizedBox(width: 8),
          Expanded(child: Text('Water')),
          Text('$cups cups • ${ml}ml'),
        ])));
      },
    );
  }
}

class _SleepMini extends StatelessWidget {
  final String uid; final DateTime day;
  const _SleepMini({required this.uid, required this.day});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SleepEntry>>(
      stream: SleepRepository().byDay(uid, day),
      builder: (context, snap) {
        final mins = (snap.data ?? const []).fold<int>(0, (s, e) => s + e.minutes);
        final h = (mins / 60).toStringAsFixed(1);
        return Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          const Icon(Icons.night_shelter_rounded), const SizedBox(width: 8),
          Expanded(child: Text('Sleep')),
          Text('$h h')
        ])));
      },
    );
  }
}

class _BarcodeScanPage extends StatefulWidget {
  const _BarcodeScanPage();
  @override
  State<_BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<_BarcodeScanPage> {
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final codes = capture.barcodes;
          if (codes.isEmpty) return;
          _done = true;
          Navigator.pop(context, codes.first.rawValue ?? '');
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 10, backgroundColor: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
            ),
          ]),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Text(unit, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
            ]),
          )
        ]),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  const _MacroBar({required this.label, required this.value, required this.goal, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = (goal <= 0 ? 0 : (value / goal)).clamp(0, 1.25);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label), const Spacer(), Text('${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)}')
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(children: [
          Container(height: 10, color: Colors.white10),
          Container(height: 10, width: MediaQuery.of(context).size.width * pct, color: color.withOpacity(0.9)),
        ]),
      ),
    ]);
  }
}
