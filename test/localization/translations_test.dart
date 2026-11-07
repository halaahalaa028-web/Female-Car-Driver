import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String lang) =>
    jsonDecode(File('assets/language/$lang.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final ar = _load('ar');
  final en = _load('en');

  test('Arabic has every key English has (no untranslated screens)', () {
    final missing = en.keys.where((k) => !ar.containsKey(k)).toList()..sort();
    expect(missing, isEmpty, reason: 'Missing in ar.json: $missing');
  });

  test('English has every key Arabic has', () {
    final missing = ar.keys.where((k) => !en.containsKey(k)).toList()..sort();
    expect(missing, isEmpty, reason: 'Missing in en.json: $missing');
  });

  test('time/distance unit keys used by DateConverter and home cards exist', () {
    for (final k in ['min', 'hr', 'km', 'day', 'week', 'month', 'year', 'hour', 'reject']) {
      expect(ar.containsKey(k), isTrue, reason: 'ar missing $k');
      expect(en.containsKey(k), isTrue, reason: 'en missing $k');
    }
  });

  test('new ride-request card keys exist in both languages', () {
    for (final k in ['view_both_locations', 'location_not_available', 'distance', 'min_away']) {
      expect((ar[k] as String?)?.isNotEmpty, isTrue, reason: 'ar $k');
      expect((en[k] as String?)?.isNotEmpty, isTrue, reason: 'en $k');
    }
  });

  test('no empty translation values', () {
    for (final entry in ar.entries) {
      expect((entry.value as String).trim().isNotEmpty, isTrue, reason: 'ar empty: ${entry.key}');
    }
  });
}
