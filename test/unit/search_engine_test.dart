import 'package:flutter_test/flutter_test.dart';
import 'package:groceryhub/models/product_model.dart';
import 'package:groceryhub/utils/search_engine.dart';

void main() {
  group('SmartSearchEngine Tests', () {
    final List<ProductModel> sampleProducts = [
      ProductModel(
        id: 'p1',
        title: 'Fresh Red Tomato Hybrid',
        category: 'vegetables',
        subcategory: 'fresh_vegetables',
        price: 30.0,
        mrp: 40.0,
        unit: '1 kg',
        imageUrl: '',
        tags: ['tamatar', 'veg', 'fresh', 'farm'],
      ),
      ProductModel(
        id: 'p2',
        title: 'Madhur Pure Sugar',
        category: 'staples',
        subcategory: 'sugar_jaggery',
        price: 52.0,
        mrp: 60.0,
        unit: '1 kg',
        imageUrl: '',
        tags: ['cheeni', 'sweet', 'sugar'],
      ),
      ProductModel(
        id: 'p3',
        title: 'Amul Taaza Toned Milk',
        category: 'dairy',
        subcategory: 'milk',
        price: 27.0,
        mrp: 28.0,
        unit: '500 ml',
        imageUrl: '',
        tags: ['doodh', 'dairy', 'amul'],
      ),
      ProductModel(
        id: 'p4',
        title: 'Bisk Farm Rich Marie',
        category: 'bakery',
        subcategory: 'biscuits',
        price: 35.0,
        mrp: 35.0,
        unit: '280g',
        imageUrl: '',
        tags: ['biskut', 'biscuit', 'tea time'],
      ),
    ];

    test('Direct match finds correct product', () {
      final results = SmartSearchEngine.search(sampleProducts, 'Tomato');
      expect(results.length, 1);
      expect(results.first.id, 'p1');
    });

    test('Hindi / Hinglish query "tamatar" matches Tomato', () {
      final results = SmartSearchEngine.search(sampleProducts, 'tamatar');
      expect(results.length, 1);
      expect(results.first.title, contains('Tomato'));
    });

    test('Typo handling: "shugar" or "cheeni" matches Sugar', () {
      final results1 = SmartSearchEngine.search(sampleProducts, 'shugar');
      expect(results1.length, 1);
      expect(results1.first.id, 'p2');

      final results2 = SmartSearchEngine.search(sampleProducts, 'cheeni');
      expect(results2.length, 1);
      expect(results2.first.id, 'p2');
    });

    test('Typo handling: "doodh" matches Amul Milk', () {
      final results = SmartSearchEngine.search(sampleProducts, 'doodh');
      expect(results.length, 1);
      expect(results.first.id, 'p3');
    });

    test('Typo handling: "biskut" matches Bisk Farm Rich Marie', () {
      final results = SmartSearchEngine.search(sampleProducts, 'biskut');
      expect(results.length, 1);
      expect(results.first.id, 'p4');
    });

    test('Empty query returns all products', () {
      final results = SmartSearchEngine.search(sampleProducts, '  ');
      expect(results.length, sampleProducts.length);
    });
  });
}

