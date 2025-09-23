import 'package:flutter/material.dart';

class SetRowEditor extends StatelessWidget {
  final TextEditingController weightController;
  final TextEditingController repsController;
  final TextEditingController rpeController;
  final VoidCallback? onDelete;
  const SetRowEditor({super.key, required this.weightController, required this.repsController, required this.rpeController, this.onDelete});

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        );
    return Row(children: [
      Expanded(
        child: TextField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: inputDecoration('Weight'),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 80,
        child: TextField(
          controller: repsController,
          keyboardType: TextInputType.number,
          decoration: inputDecoration('Reps'),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 80,
        child: TextField(
          controller: rpeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: inputDecoration('RPE'),
        ),
      ),
      if (onDelete != null) ...[
        const SizedBox(width: 8),
        IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
      ]
    ]);
  }
}
