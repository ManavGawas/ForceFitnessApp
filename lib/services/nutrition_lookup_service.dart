import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gymmate/services/repositories.dart';

class NutritionItem {
  final String name;
  final String? brand;
  final String? servingSize; // e.g., "30 g"
  // per 100g/ml
  final int? kcal100;
  final int? protein100;
  final int? carbs100;
  final int? fats100;
  // per serving
  final int? kcalServing;
  final int? proteinServing;
  final int? carbsServing;
  final int? fatsServing;

  NutritionItem({
    required this.name,
    this.brand,
    this.servingSize,
    this.kcal100,
    this.protein100,
    this.carbs100,
    this.fats100,
    this.kcalServing,
    this.proteinServing,
    this.carbsServing,
    this.fatsServing,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'servingSize': servingSize,
        'kcal100': kcal100,
        'protein100': protein100,
        'carbs100': carbs100,
        'fats100': fats100,
        'kcalServing': kcalServing,
        'proteinServing': proteinServing,
        'carbsServing': carbsServing,
        'fatsServing': fatsServing,
      };
  static NutritionItem fromMap(Map<String, dynamic> m) => NutritionItem(
        name: m['name'] ?? 'Item',
        brand: m['brand'],
        servingSize: m['servingSize'],
        kcal100: (m['kcal100'] as num?)?.round(),
        protein100: (m['protein100'] as num?)?.round(),
        carbs100: (m['carbs100'] as num?)?.round(),
        fats100: (m['fats100'] as num?)?.round(),
        kcalServing: (m['kcalServing'] as num?)?.round(),
        proteinServing: (m['proteinServing'] as num?)?.round(),
        carbsServing: (m['carbsServing'] as num?)?.round(),
        fatsServing: (m['fatsServing'] as num?)?.round(),
      );
}

class NutritionLookupService {
  // Simple in-memory cache per barcode
  static final Map<String, NutritionItem> _cache = {};

  static Future<NutritionItem?> byBarcode(String code, {String? uid}) async {
    if (_cache.containsKey(code)) return _cache[code];
    // Try Firestore cache scoped to user
    if (uid != null) {
      try {
        final cached = await FoodCacheRepository().get(uid, code);
        if (cached != null) {
          final item = NutritionItem.fromMap(cached);
          _cache[code] = item;
          return item;
        }
      } catch (e) {
        debugPrint('Food cache get failed: $e');
      }
    }
    try {
      // Example public API shape; replace with a configured service if available
      // This endpoint is a placeholder; implement your chosen API here.
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$code.json');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final p = data['product'];
        if (p != null) {
          final n = p['nutriments'] ?? {};
          final item = NutritionItem(
            name: (p['product_name'] ?? '').toString().isEmpty ? 'Item' : p['product_name'],
            brand: p['brands'],
            servingSize: p['serving_size'],
            kcal100: (n['energy-kcal_100g'] as num?)?.round(),
            protein100: (n['proteins_100g'] as num?)?.round(),
            carbs100: (n['carbohydrates_100g'] as num?)?.round(),
            fats100: (n['fat_100g'] as num?)?.round(),
            kcalServing: (n['energy-kcal_serving'] as num?)?.round(),
            proteinServing: (n['proteins_serving'] as num?)?.round(),
            carbsServing: (n['carbohydrates_serving'] as num?)?.round(),
            fatsServing: (n['fat_serving'] as num?)?.round(),
          );
          _cache[code] = item;
          // Persist in user cache
          if (uid != null) {
            try {
              await FoodCacheRepository().upsert(uid, code, item.toMap());
            } catch (e) {
              debugPrint('Food cache upsert failed: $e');
            }
          }
          return item;
        }
      }
    } catch (e) {
      debugPrint('Nutrition lookup failed: $e');
    }
    return null;
  }
}
