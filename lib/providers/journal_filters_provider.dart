// lib/providers/journal_filters_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedMoodProvider = StateProvider<String?>((ref) => null);
final selectedRatingProvider = StateProvider<int?>((ref) => null);
final showFiltersProvider = StateProvider<bool>((ref) => false);
