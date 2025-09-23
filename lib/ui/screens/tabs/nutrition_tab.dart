import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/nutrition.dart';
import '../../../services/providers/auth_provider.dart';
import '../../../services/providers/selected_date_provider.dart';
import '../../../services/repositories.dart';
import '../../widgets/common.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text('Nutrition • $dateLabel')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: uid == null
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
                    children: [
                      SectionCard(
                        title: 'Totals',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Calories: $totalKcal'),
                            Text('P $totalP • C $totalC • F $totalF'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        const EmptyState('No entries yet')
                      else
                        ...entries.map((e) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.restaurant),
                                title: Text(e.name.isEmpty ? 'Entry' : e.name),
                                subtitle: Text('P ${e.protein} • C ${e.carbs} • F ${e.fats}'),
                                trailing: Text('${e.calories} kcal'),
                              ),
                            )),
                    ],
                  );
                },
              ),
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
                    // Placeholder: treat scanned code as a 200kcal snack
                    final entry = NutritionEntry(
                      id: '', date: day, name: 'Scanned $code', calories: 200, protein: 5, carbs: 30, fats: 5,
                    );
                    await NutritionRepository().add(uid, entry);
                  }
                }
              },
              icon: const Icon(Icons.restaurant),
              label: const Text('Add Food'),
            ),
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
