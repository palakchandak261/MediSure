import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

/// Loads and queries the Kaggle 11,000 medicine dataset.
///
/// CSV columns (from singhnavjot2062001/11000-medicine-details):
///   0: Medicine Name
///   1: Composition
///   2: Uses
///   3: Side_effects
///   4: Image URL
///   5: Manufacturer
///   6: Excellent Review %
///   7: Average Review %
///   8: Poor Review %
class MedicineDatasetService {
  static final MedicineDatasetService _instance =
      MedicineDatasetService._internal();
  static MedicineDatasetService get instance => _instance;
  MedicineDatasetService._internal();

  List<MedicineEntry> _medicines = [];
  // Fast lookup map: lowercase name → entry
  final Map<String, MedicineEntry> _nameIndex = {};
  // Composition index: lowercase generic name → list of entries
  final Map<String, List<MedicineEntry>> _compositionIndex = {};
  bool _loaded = false;

  // ── LOAD ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_loaded) return;
    try {
      final csv = await rootBundle.loadString('assets/pharmacy_dataset.csv');
      _parseCSV(csv);
      debugPrint('✅ Dataset loaded: ${_medicines.length} medicines');
    } catch (e) {
      debugPrint('ℹ️ CSV not found, using built-in fallback: $e');
      _medicines = _builtInMedicines();
      _buildIndexes();
    }
    _loaded = true;
  }

  void _parseCSV(String csv) {
    final lines = csv.split('\n');
    _medicines = [];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = _parseCsvLine(line);
      if (cols.length < 6) continue;

      final name = cols[0].trim();
      if (name.isEmpty) continue;

      final excellentPct = int.tryParse(cols.length > 6 ? cols[6].trim() : '') ?? 0;
      final averagePct   = int.tryParse(cols.length > 7 ? cols[7].trim() : '') ?? 0;
      final poorPct      = int.tryParse(cols.length > 8 ? cols[8].trim() : '') ?? 0;

      _medicines.add(MedicineEntry(
        name:         name,
        composition:  cols.length > 1 ? cols[1].trim() : '',
        uses:         cols.length > 2 ? cols[2].trim() : '',
        sideEffects:  cols.length > 3 ? cols[3].trim() : '',
        imageUrl:     cols.length > 4 ? cols[4].trim() : '',
        manufacturer: cols.length > 5 ? cols[5].trim() : '',
        excellentPct: excellentPct,
        averagePct:   averagePct,
        poorPct:      poorPct,
      ));
    }
    _buildIndexes();
  }

  void _buildIndexes() {
    _nameIndex.clear();
    _compositionIndex.clear();

    for (final m in _medicines) {
      _nameIndex[m.name.toLowerCase()] = m;

      // Index by each generic name in composition
      // e.g. "Amoxycillin (500mg) + Clavulanic Acid (125mg)"
      final generics = _extractGenerics(m.composition);
      for (final g in generics) {
        _compositionIndex.putIfAbsent(g, () => []).add(m);
      }
    }
  }

  /// Extract generic names from composition string.
  /// "Amoxycillin (500mg) + Clavulanic Acid (125mg)" → ["amoxycillin", "clavulanic acid"]
  List<String> _extractGenerics(String composition) {
    if (composition.isEmpty) return [];
    return composition
        .split(RegExp(r'\+|,'))
        .map((part) => part.replaceAll(RegExp(r'\(.*?\)'), '').trim().toLowerCase())
        .where((s) => s.length > 2)
        .toList();
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }

  // ── QUERY API ─────────────────────────────────────────────────────────────

  /// Find medicine by exact or partial name match.
  MedicineEntry? getByName(String name) {
    if (name.isEmpty) return null;
    final lower = name.toLowerCase();

    // 1. Exact match
    if (_nameIndex.containsKey(lower)) return _nameIndex[lower];

    // 2. Starts-with match
    for (final key in _nameIndex.keys) {
      if (key.startsWith(lower) || lower.startsWith(key)) {
        return _nameIndex[key];
      }
    }

    // 3. Contains match
    for (final key in _nameIndex.keys) {
      if (key.contains(lower) || lower.contains(key)) {
        return _nameIndex[key];
      }
    }

    // 4. Composition match
    for (final key in _compositionIndex.keys) {
      if (key.contains(lower) || lower.contains(key)) {
        final entries = _compositionIndex[key]!;
        if (entries.isNotEmpty) return entries.first;
      }
    }

    return null;
  }

  /// Search medicines by name or composition — returns up to [limit] results.
  List<MedicineEntry> search(String query, {int limit = 20}) {
    if (query.isEmpty) return [];
    final lower = query.toLowerCase();
    final results = <MedicineEntry>[];
    final seen = <String>{};

    for (final m in _medicines) {
      if (results.length >= limit) break;
      if (seen.contains(m.name)) continue;
      if (m.name.toLowerCase().contains(lower) ||
          m.composition.toLowerCase().contains(lower) ||
          m.uses.toLowerCase().contains(lower)) {
        results.add(m);
        seen.add(m.name);
      }
    }
    return results;
  }

  /// Get all medicine names for OCR matching.
  List<String> getAllMedicineNames() {
    return _medicines.map((m) => m.genericName).where((n) => n.length > 2).toSet().toList();
  }

  /// Get price range string for a medicine.
  /// Dataset has no price column — we estimate from composition complexity.
  String getPriceRange(String name) {
    final entry = getByName(name);
    if (entry == null) return 'Price varies';
    final price = _estimatePrice(entry);
    return '₹${price.toStringAsFixed(0)}';
  }

  double estimatePrice(String name) {
    final entry = getByName(name);
    if (entry == null) return 50.0;
    return _estimatePrice(entry);
  }

  double _estimatePrice(MedicineEntry entry) {
    // Base price from known generics in composition
    const knownPrices = {
      'paracetamol': 25.0,    'ibuprofen': 40.0,     'aspirin': 15.0,
      'amoxycillin': 85.0,    'amoxicillin': 85.0,   'azithromycin': 120.0,
      'ciprofloxacin': 90.0,  'metronidazole': 30.0, 'doxycycline': 65.0,
      'cetirizine': 20.0,     'loratadine': 25.0,    'fexofenadine': 55.0,
      'metformin': 35.0,      'glimepiride': 45.0,   'atorvastatin': 95.0,
      'rosuvastatin': 110.0,  'amlodipine': 45.0,    'telmisartan': 55.0,
      'pantoprazole': 55.0,   'omeprazole': 45.0,    'rabeprazole': 60.0,
      'levothyroxine': 60.0,  'prednisolone': 25.0,  'montelukast': 65.0,
      'clavulanic': 120.0,    'bevacizumab': 45000.0,'insulin': 350.0,
    };

    final comp = entry.composition.toLowerCase();
    for (final e in knownPrices.entries) {
      if (comp.contains(e.key)) return e.value;
    }

    // Fallback: estimate from name length + manufacturer tier
    final premiumManufacturers = ['roche', 'pfizer', 'novartis', 'abbott', 'glaxo'];
    final isPremium = premiumManufacturers.any(
      (m) => entry.manufacturer.toLowerCase().contains(m),
    );
    return isPremium ? 150.0 : 50.0 + (entry.name.length * 2.0);
  }

  /// Get alternatives — same composition, different brand.
  List<String> getAlternatives(String medicineName) {
    final entry = getByName(medicineName);
    if (entry == null) return [];

    final generics = _extractGenerics(entry.composition);
    if (generics.isEmpty) return [];

    final alternatives = <String>{};
    for (final g in generics) {
      final matches = _compositionIndex[g] ?? [];
      for (final m in matches) {
        if (m.name.toLowerCase() != medicineName.toLowerCase()) {
          alternatives.add(m.name);
          if (alternatives.length >= 5) break;
        }
      }
      if (alternatives.length >= 5) break;
    }
    return alternatives.toList();
  }

  /// Get drug interactions from the side effects / composition data.
  String getDrugInteractions(String medicineName) {
    final entry = getByName(medicineName);
    if (entry == null) return 'Consult your doctor';
    if (entry.sideEffects.isNotEmpty) {
      return 'Side effects: ${entry.sideEffects}';
    }
    return 'Consult your doctor';
  }

  /// Get medicines by use/condition.
  List<MedicineEntry> getByUse(String condition, {int limit = 10}) {
    final lower = condition.toLowerCase();
    return _medicines
        .where((m) => m.uses.toLowerCase().contains(lower))
        .take(limit)
        .toList();
  }

  /// Get top-rated medicines (by excellent review %).
  List<MedicineEntry> getTopRated({int limit = 10}) {
    final sorted = List<MedicineEntry>.from(_medicines)
      ..sort((a, b) => b.excellentPct.compareTo(a.excellentPct));
    return sorted.take(limit).toList();
  }

  bool get isLoaded => _loaded;
  int get count => _medicines.length;

  // ── BUILT-IN FALLBACK ─────────────────────────────────────────────────────

  List<MedicineEntry> _builtInMedicines() {
    const data = [
      ('Paracetamol 500mg Tablet', 'Paracetamol (500mg)',
          'Fever Pain relief Headache', 'Nausea Liver damage with overdose',
          '', 'Generic', 70, 20, 10),
      ('Ibuprofen 400mg Tablet', 'Ibuprofen (400mg)',
          'Pain relief Inflammation Fever', 'Stomach upset GI bleeding',
          '', 'Generic', 65, 25, 10),
      ('Amoxicillin 500mg Capsule', 'Amoxycillin (500mg)',
          'Treatment of Bacterial infections', 'Diarrhea Nausea Rash',
          '', 'Generic', 72, 20, 8),
      ('Azithromycin 500mg Tablet', 'Azithromycin (500mg)',
          'Treatment of Bacterial infections', 'Nausea Abdominal pain Diarrhea',
          '', 'Generic', 68, 22, 10),
      ('Cetirizine 10mg Tablet', 'Cetirizine (10mg)',
          'Allergy Hay fever Urticaria', 'Drowsiness Dry mouth Headache',
          '', 'Generic', 75, 18, 7),
      ('Metformin 500mg Tablet', 'Metformin (500mg)',
          'Type 2 Diabetes management', 'Nausea Diarrhea Lactic acidosis',
          '', 'Generic', 70, 22, 8),
      ('Atorvastatin 10mg Tablet', 'Atorvastatin (10mg)',
          'High cholesterol Cardiovascular risk reduction',
          'Muscle pain Liver enzyme elevation', '', 'Generic', 73, 20, 7),
      ('Pantoprazole 40mg Tablet', 'Pantoprazole (40mg)',
          'Acidity GERD Peptic ulcer', 'Headache Diarrhea Nausea',
          '', 'Generic', 74, 19, 7),
      ('Amlodipine 5mg Tablet', 'Amlodipine (5mg)',
          'High blood pressure Angina', 'Ankle swelling Flushing Dizziness',
          '', 'Generic', 71, 21, 8),
      ('Levothyroxine 50mcg Tablet', 'Levothyroxine (50mcg)',
          'Hypothyroidism Thyroid hormone replacement',
          'Palpitations Insomnia Weight loss', '', 'Generic', 76, 17, 7),
      ('Augmentin 625 Duo Tablet', 'Amoxycillin (500mg) + Clavulanic Acid (125mg)',
          'Treatment of Bacterial infections', 'Vomiting Nausea Diarrhea',
          '', 'Glaxo SmithKline', 47, 35, 18),
      ('Azithral 500 Tablet', 'Azithromycin (500mg)',
          'Treatment of Bacterial infections', 'Nausea Abdominal pain Diarrhea',
          '', 'Alembic Pharmaceuticals', 39, 40, 21),
      ('Dolo 650 Tablet', 'Paracetamol (650mg)',
          'Fever Pain relief', 'Nausea Liver damage with overdose',
          '', 'Micro Labs', 80, 15, 5),
      ('Combiflam Tablet', 'Ibuprofen (400mg) + Paracetamol (325mg)',
          'Pain relief Fever Inflammation', 'Stomach upset GI bleeding',
          '', 'Sanofi India', 72, 20, 8),
      ('Montair 10 Tablet', 'Montelukast (10mg)',
          'Asthma Allergic rhinitis', 'Headache Abdominal pain',
          '', 'Cipla', 68, 24, 8),
    ];

    return data.map((d) => MedicineEntry(
      name: d.$1, composition: d.$2, uses: d.$3,
      sideEffects: d.$4, imageUrl: d.$5, manufacturer: d.$6,
      excellentPct: d.$7, averagePct: d.$8, poorPct: d.$9,
    )).toList();
  }
}

// ── DATA MODEL ────────────────────────────────────────────────────────────────

class MedicineEntry {
  final String name;
  final String composition;
  final String uses;
  final String sideEffects;
  final String imageUrl;
  final String manufacturer;
  final int excellentPct;
  final int averagePct;
  final int poorPct;

  const MedicineEntry({
    required this.name,
    required this.composition,
    required this.uses,
    required this.sideEffects,
    required this.imageUrl,
    required this.manufacturer,
    required this.excellentPct,
    required this.averagePct,
    required this.poorPct,
  });

  /// Extract the generic name from the brand name.
  /// "Augmentin 625 Duo Tablet" → "Augmentin"
  String get genericName {
    return name
        .replaceAll(RegExp(r'\d+\.?\d*\s*(mg|ml|mcg|g|iu|%)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(tablet|capsule|syrup|injection|cream|gel|drops|suspension|forte|sr|xr|er|ds)\b', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .join(' ')
        .trim();
  }

  /// Rating score 0-100
  int get ratingScore => excellentPct;

  /// Formatted rating string
  String get ratingText {
    if (excellentPct >= 70) return '⭐ Highly Rated ($excellentPct% excellent)';
    if (excellentPct >= 50) return '👍 Good ($excellentPct% excellent)';
    return '📊 Mixed reviews ($excellentPct% excellent)';
  }

  /// Side effects as a list
  List<String> get sideEffectsList {
    if (sideEffects.isEmpty) return ['Consult doctor'];
    return sideEffects
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(6)
        .toList();
  }

  /// Uses as a list
  List<String> get usesList {
    if (uses.isEmpty) return ['As directed by doctor'];
    return uses
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(5)
        .toList();
  }

  // Legacy compatibility fields used by existing screens
  String get category => _inferCategory();
  double get price => 0.0; // use MedicineDatasetService.estimatePrice()
  String get packageSize => '10 tablets';
  int get stockQty => 100;
  String get expiryDate => '2026-12-31';
  String get description => uses.isNotEmpty ? uses : 'Medicine';
  bool get prescriptionNeeded => true;
  String get drugInteractions => sideEffects;

  String _inferCategory() {
    final lower = uses.toLowerCase() + composition.toLowerCase();
    if (lower.contains('cancer') || lower.contains('tumor')) return 'Oncology';
    if (lower.contains('bacteria') || lower.contains('infection')) return 'Antibiotic';
    if (lower.contains('diabetes') || lower.contains('insulin')) return 'Antidiabetic';
    if (lower.contains('blood pressure') || lower.contains('cardiac')) return 'Cardiovascular';
    if (lower.contains('pain') || lower.contains('fever')) return 'Analgesic';
    if (lower.contains('allergy') || lower.contains('antihistamine')) return 'Antihistamine';
    if (lower.contains('acid') || lower.contains('gastric') || lower.contains('ulcer')) return 'Gastrointestinal';
    if (lower.contains('thyroid')) return 'Thyroid';
    if (lower.contains('asthma') || lower.contains('respiratory')) return 'Respiratory';
    if (lower.contains('vitamin') || lower.contains('supplement')) return 'Supplement';
    return 'Medicine';
  }
}

// Legacy alias so existing code that imports MedicineDataEntry still compiles
typedef MedicineDataEntry = MedicineEntry;
