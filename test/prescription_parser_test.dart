// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter_test/flutter_test.dart';
import 'package:medisure/services/prescription_parser.dart';
import 'package:medisure/models/medicine_model.dart';

/// Comprehensive tests for PrescriptionParser.
///
/// Covers:
///  - Empty / whitespace / garbage input
///  - Single medicine detection (generic + brand names)
///  - Multiple medicines in one prescription
///  - Dosage extraction (mg, ml, mcg)
///  - Timing extraction (OD, BD, TDS, 1-0-1 patterns)
///  - Duration extraction
///  - Tab./Cap. prefix stripping
///  - Skip-line filtering (doctor name, date, address, etc.)
///  - Duplicate medicine deduplication
///  - Case insensitivity
///  - Real-world Indian prescription samples
void main() {
  // ── HELPERS ──────────────────────────────────────────────────────────────

  /// Returns the first medicine name found, or null.
  String? firstName(String text) {
    final results = PrescriptionParser.parse(text);
    return results.isEmpty ? null : results.first.name;
  }

  /// Returns all medicine names found.
  List<String> allNames(String text) =>
      PrescriptionParser.parse(text).map((m) => m.name).toList();

  // ── GROUP 1: EMPTY & GARBAGE INPUT ───────────────────────────────────────

  group('Empty and garbage input', () {
    test('empty string returns empty list', () {
      expect(PrescriptionParser.parse(''), isEmpty);
    });

    test('whitespace-only string returns empty list', () {
      expect(PrescriptionParser.parse('   \n\n\t  '), isEmpty);
    });

    test('random numbers and symbols return empty list', () {
      expect(PrescriptionParser.parse('123 456 !@# \$\$\$'), isEmpty);
    });

    test('very short lines are skipped', () {
      expect(PrescriptionParser.parse('AB\nCD\nEF'), isEmpty);
    });

    test('prescription header lines are skipped', () {
      const header = '''
Dr. Sharma MD
Patient Name: Rahul
Date: 12/05/2024
Age: 35
Address: Mumbai
''';
      expect(PrescriptionParser.parse(header), isEmpty);
    });
  });

  // ── GROUP 2: SINGLE MEDICINE DETECTION ───────────────────────────────────

  group('Single medicine detection', () {
    test('detects paracetamol (generic name)', () {
      expect(firstName('Tab. Paracetamol 500mg'), equals('Paracetamol'));
    });

    test('detects ibuprofen (generic name)', () {
      expect(firstName('Ibuprofen 400mg twice daily'), equals('Ibuprofen'));
    });

    test('detects amoxicillin (antibiotic)', () {
      expect(firstName('Tab Amoxicillin 500mg TDS'), equals('Amoxicillin'));
    });

    test('detects azithromycin (antibiotic)', () {
      expect(firstName('Cap. Azithromycin 250mg OD'), equals('Azithromycin'));
    });

    test('detects metformin (diabetes)', () {
      expect(firstName('Tab. Metformin 500mg after meals'), equals('Metformin'));
    });

    test('detects atorvastatin (cholesterol)', () {
      expect(firstName('Atorvastatin 10mg at night'), equals('Atorvastatin'));
    });

    test('detects pantoprazole (acidity)', () {
      expect(firstName('Tab Pantoprazole 40mg before breakfast'), equals('Pantoprazole'));
    });

    test('detects cetirizine (antihistamine)', () {
      expect(firstName('Cetirizine 10mg at night'), equals('Cetirizine'));
    });

    test('detects amlodipine (BP)', () {
      expect(firstName('Tab. Amlodipine 5mg OD'), equals('Amlodipine'));
    });

    test('detects levothyroxine (thyroid)', () {
      expect(firstName('Levothyroxine 50mcg morning empty stomach'), equals('Levothyroxine'));
    });
  });

  // ── GROUP 3: BRAND NAME DETECTION ────────────────────────────────────────

  group('Brand name detection', () {
    test('detects Dolo (paracetamol brand)', () {
      expect(firstName('Tab Dolo 650mg'), equals('Dolo'));
    });

    test('detects Augmentin (amoxicillin brand)', () {
      expect(firstName('Tab Augmentin 625mg BD'), equals('Augmentin'));
    });

    test('detects Combiflam (ibuprofen+paracetamol brand)', () {
      expect(firstName('Combiflam TDS after food'), equals('Combiflam'));
    });

    test('detects Allegra (fexofenadine brand)', () {
      expect(firstName('Tab Allegra 120mg OD'), equals('Allegra'));
    });

    test('detects Montair (montelukast brand)', () {
      expect(firstName('Montair 10mg at night'), equals('Montair'));
    });

    test('detects Pan-40 (pantoprazole brand)', () {
      final results = PrescriptionParser.parse('Tab Pan-40 before breakfast');
      expect(results, isNotEmpty);
    });

    test('detects Glycomet (metformin brand)', () {
      expect(firstName('Tab Glycomet 500mg BD'), equals('Glycomet'));
    });

    test('detects Thyronorm (levothyroxine brand)', () {
      expect(firstName('Thyronorm 50mcg OD'), equals('Thyronorm'));
    });
  });

  // ── GROUP 4: DOSAGE EXTRACTION ────────────────────────────────────────────

  group('Dosage extraction', () {
    test('extracts mg dosage', () {
      final results = PrescriptionParser.parse('Tab Paracetamol 500mg TDS');
      expect(results, isNotEmpty);
      expect(results.first.dosage, equals('500 mg'));
    });

    test('extracts ml dosage', () {
      final results = PrescriptionParser.parse('Syrup Ambroxol 5ml BD');
      expect(results, isNotEmpty);
      expect(results.first.dosage, equals('5 ml'));
    });

    test('extracts mcg dosage', () {
      final results = PrescriptionParser.parse('Levothyroxine 50mcg OD');
      expect(results, isNotEmpty);
      expect(results.first.dosage, equals('50 mcg'));
    });

    test('extracts decimal dosage', () {
      final results = PrescriptionParser.parse('Tab Amlodipine 2.5mg OD');
      expect(results, isNotEmpty);
      expect(results.first.dosage, equals('2.5 mg'));
    });

    test('returns As prescribed when no dosage found', () {
      final results = PrescriptionParser.parse('Tab Paracetamol TDS');
      expect(results, isNotEmpty);
      expect(results.first.dosage, equals('As prescribed'));
    });
  });

  // ── GROUP 5: TIMING EXTRACTION ────────────────────────────────────────────

  group('Timing extraction', () {
    test('extracts morning timing', () {
      final results = PrescriptionParser.parse('Tab Metformin 500mg morning');
      expect(results, isNotEmpty);
      expect(results.first.timing.toLowerCase(), contains('morning'));
    });

    test('extracts after meals timing', () {
      final results = PrescriptionParser.parse('Tab Metformin 500mg after meals');
      expect(results, isNotEmpty);
      expect(results.first.timing.toLowerCase(), contains('after meals'));
    });

    test('extracts before meals timing', () {
      final results = PrescriptionParser.parse('Tab Pantoprazole 40mg before breakfast');
      expect(results, isNotEmpty);
      expect(results.first.timing.toLowerCase(), contains('before meals'));
    });

    test('extracts 1-0-1 dosing pattern (morning and night)', () {
      final results = PrescriptionParser.parse('Tab Paracetamol 500mg 1-0-1');
      expect(results, isNotEmpty);
      final timing = results.first.timing.toLowerCase();
      expect(timing, contains('morning'));
      expect(timing, contains('night'));
    });

    test('extracts 1-1-1 dosing pattern (morning, afternoon, night)', () {
      final results = PrescriptionParser.parse('Tab Amoxicillin 500mg 1-1-1');
      expect(results, isNotEmpty);
      final timing = results.first.timing.toLowerCase();
      expect(timing, contains('morning'));
      expect(timing, contains('afternoon'));
      expect(timing, contains('night'));
    });

    test('extracts OD timing', () {
      final results = PrescriptionParser.parse('Tab Amlodipine 5mg OD');
      expect(results, isNotEmpty);
      expect(results.first.timing.toLowerCase(), contains('od'));
    });

    test('extracts BD timing', () {
      final results = PrescriptionParser.parse('Tab Metformin 500mg BD');
      expect(results, isNotEmpty);
      expect(results.first.timing.toLowerCase(), contains('bd'));
    });

    test('extracts TDS timing', () {
      final results = PrescriptionParser.parse('Tab Amoxicillin 500mg TDS');
      expect(results, isNotEmpty);
      expect(results.first.timing.toLowerCase(), contains('tds'));
    });

    test('returns As directed when no timing found', () {
      final results = PrescriptionParser.parse('Tab Paracetamol 500mg');
      expect(results, isNotEmpty);
      expect(results.first.timing, equals('As directed'));
    });
  });

  // ── GROUP 6: MULTIPLE MEDICINES ───────────────────────────────────────────

  group('Multiple medicines in one prescription', () {
    test('detects two medicines', () {
      const text = '''
Tab Paracetamol 500mg TDS
Tab Amoxicillin 500mg BD
''';
      final names = allNames(text);
      expect(names, contains('Paracetamol'));
      expect(names, contains('Amoxicillin'));
    });

    test('detects three medicines', () {
      const text = '''
Tab Metformin 500mg BD after meals
Tab Atorvastatin 10mg at night
Tab Amlodipine 5mg OD
''';
      final names = allNames(text);
      expect(names, contains('Metformin'));
      expect(names, contains('Atorvastatin'));
      expect(names, contains('Amlodipine'));
    });

    test('detects five medicines in a complex prescription', () {
      const text = '''
Dr. Sharma
Patient: Rahul Kumar
Date: 12/05/2024

1. Tab Paracetamol 500mg TDS
2. Tab Azithromycin 500mg OD for 5 days
3. Tab Cetirizine 10mg at night
4. Tab Pantoprazole 40mg before breakfast
5. Tab Vitamin D3 60000 IU weekly
''';
      final names = allNames(text);
      expect(names.length, greaterThanOrEqualTo(4));
      expect(names, contains('Paracetamol'));
      expect(names, contains('Azithromycin'));
      expect(names, contains('Cetirizine'));
      expect(names, contains('Pantoprazole'));
    });
  });

  // ── GROUP 7: DEDUPLICATION ────────────────────────────────────────────────

  group('Duplicate medicine deduplication', () {
    test('same medicine mentioned twice is returned only once', () {
      const text = '''
Tab Paracetamol 500mg TDS
Paracetamol 500mg as needed
''';
      final names = allNames(text);
      final paracetamolCount = names.where(
        (n) => n.toLowerCase() == 'paracetamol',
      ).length;
      expect(paracetamolCount, equals(1));
    });
  });

  // ── GROUP 8: PREFIX STRIPPING ─────────────────────────────────────────────

  group('Prefix stripping', () {
    test('strips Tab. prefix', () {
      expect(firstName('Tab. Paracetamol 500mg'), equals('Paracetamol'));
    });

    test('strips Cap. prefix', () {
      expect(firstName('Cap. Amoxicillin 500mg'), equals('Amoxicillin'));
    });

    test('strips Syp. prefix', () {
      final results = PrescriptionParser.parse('Syp. Ambroxol 5ml BD');
      expect(results, isNotEmpty);
    });

    test('strips numbered prefix (1.)', () {
      expect(firstName('1. Paracetamol 500mg TDS'), equals('Paracetamol'));
    });

    test('strips Inj. prefix', () {
      final results = PrescriptionParser.parse('Inj. Amikacin 500mg IV');
      expect(results, isNotEmpty);
    });
  });

  // ── GROUP 9: SKIP LINE FILTERING ─────────────────────────────────────────

  group('Skip line filtering', () {
    test('skips doctor name line', () {
      expect(PrescriptionParser.parse('Dr. Sharma MBBS'), isEmpty);
    });

    test('skips date line', () {
      expect(PrescriptionParser.parse('Date: 12/05/2024'), isEmpty);
    });

    test('skips patient name line', () {
      expect(PrescriptionParser.parse('Patient Name: Rahul Kumar'), isEmpty);
    });

    test('skips address line', () {
      expect(PrescriptionParser.parse('Address: 123 Main Street Mumbai'), isEmpty);
    });

    test('skips diagnosis line', () {
      expect(PrescriptionParser.parse('Diagnosis: Viral fever'), isEmpty);
    });

    test('skips hospital name', () {
      expect(PrescriptionParser.parse('City Hospital and Research Centre'), isEmpty);
    });
  });

  // ── GROUP 10: CASE INSENSITIVITY ──────────────────────────────────────────

  group('Case insensitivity', () {
    test('detects PARACETAMOL in uppercase', () {
      expect(firstName('PARACETAMOL 500MG TDS'), equals('Paracetamol'));
    });

    test('detects paracetamol in lowercase', () {
      expect(firstName('paracetamol 500mg tds'), equals('Paracetamol'));
    });

    test('detects Metformin in mixed case', () {
      expect(firstName('mEtFoRmIn 500mg BD'), equals('Metformin'));
    });
  });

  // ── GROUP 11: CONFIDENCE SCORES ───────────────────────────────────────────

  group('Confidence scores', () {
    test('dictionary match has confidence >= 85', () {
      final results = PrescriptionParser.parse('Tab Paracetamol 500mg TDS');
      expect(results, isNotEmpty);
      expect(results.first.confidence, greaterThanOrEqualTo(85.0));
    });

    test('confidence level is High for dictionary match', () {
      final results = PrescriptionParser.parse('Tab Paracetamol 500mg TDS');
      expect(results, isNotEmpty);
      expect(results.first.confidenceLevel, equals('High'));
    });

    test('needsVerification is false for high confidence', () {
      final results = PrescriptionParser.parse('Tab Paracetamol 500mg TDS');
      expect(results, isNotEmpty);
      expect(results.first.needsVerification, isFalse);
    });
  });

  // ── GROUP 12: REAL-WORLD INDIAN PRESCRIPTION SAMPLES ─────────────────────

  group('Real-world Indian prescription samples', () {
    test('typical fever prescription', () {
      const text = '''
Tab Dolo 650mg TDS for 5 days
Tab Azithromycin 500mg OD for 3 days
Tab Cetirizine 10mg at night
''';
      final names = allNames(text);
      expect(names, contains('Dolo'));
      expect(names, contains('Azithromycin'));
      expect(names, contains('Cetirizine'));
    });

    test('typical diabetes prescription', () {
      const text = '''
Tab Metformin 500mg BD after meals
Tab Glimepiride 1mg before breakfast
Tab Atorvastatin 10mg at night
''';
      final names = allNames(text);
      expect(names, contains('Metformin'));
      expect(names, contains('Glimepiride'));
      expect(names, contains('Atorvastatin'));
    });

    test('typical hypertension prescription', () {
      const text = '''
Tab Amlodipine 5mg OD
Tab Telmisartan 40mg OD
Tab Atorvastatin 10mg at night
Tab Aspirin 75mg OD after breakfast
''';
      final names = allNames(text);
      expect(names, contains('Amlodipine'));
      expect(names, contains('Telmisartan'));
      expect(names, contains('Atorvastatin'));
      expect(names, contains('Aspirin'));
    });

    test('typical acidity prescription', () {
      const text = '''
Tab Pantoprazole 40mg before breakfast
Tab Domperidone 10mg before meals TDS
''';
      final names = allNames(text);
      expect(names, contains('Pantoprazole'));
      expect(names, contains('Domperidone'));
    });

    test('prescription with header and footer noise', () {
      const text = '''
ABC Clinic, Mumbai
Dr. Priya Sharma MBBS MD
Patient: Rahul Kumar  Age: 45
Date: 12/05/2024

Rx:
1. Tab Paracetamol 500mg TDS x 5 days
2. Tab Amoxicillin 500mg BD x 7 days
3. Tab Pantoprazole 40mg OD before breakfast

Advice: Rest, plenty of fluids
Please do not reissue
Signature: ___________
''';
      final names = allNames(text);
      expect(names, contains('Paracetamol'));
      expect(names, contains('Amoxicillin'));
      expect(names, contains('Pantoprazole'));
      // Header/footer lines should NOT appear as medicines
      expect(names, isNot(contains('Mumbai')));
      expect(names, isNot(contains('Rahul')));
    });

    test('prescription with 1-0-1 dosing pattern', () {
      const text = '''
Tab Metformin 500mg 1-0-1 after meals
Tab Amlodipine 5mg 1-0-0
''';
      final results = PrescriptionParser.parse(text);
      expect(results.length, greaterThanOrEqualTo(2));

      final metformin = results.firstWhere(
        (m) => m.name.toLowerCase() == 'metformin',
        orElse: () => MedicineModel(
          name: '', dosage: '', timing: '', confidence: 0,
        ),
      );
      expect(metformin.name, isNotEmpty);
      expect(metformin.timing.toLowerCase(), contains('morning'));
      expect(metformin.timing.toLowerCase(), contains('night'));
    });
  });

  // ── GROUP 13: MEDICINE MODEL SERIALIZATION ────────────────────────────────

  group('MedicineModel serialization', () {
    test('toMap and fromMap round-trip preserves all fields', () {
      final original = MedicineModel(
        name: 'Paracetamol',
        dosage: '500 mg',
        timing: 'TDS after meals',
        confidence: 85.0,
        notes: 'Pain reliever & fever reducer',
      );

      final map = original.toMap();
      final restored = MedicineModel.fromMap(map);

      expect(restored.name, equals(original.name));
      expect(restored.dosage, equals(original.dosage));
      expect(restored.timing, equals(original.timing));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.notes, equals(original.notes));
    });

    test('confidenceLevel returns High for confidence >= 80', () {
      final m = MedicineModel(
        name: 'Test', dosage: '', timing: '', confidence: 85.0,
      );
      expect(m.confidenceLevel, equals('High'));
    });

    test('confidenceLevel returns Medium for confidence 60-79', () {
      final m = MedicineModel(
        name: 'Test', dosage: '', timing: '', confidence: 70.0,
      );
      expect(m.confidenceLevel, equals('Medium'));
    });

    test('confidenceLevel returns Low for confidence < 60', () {
      final m = MedicineModel(
        name: 'Test', dosage: '', timing: '', confidence: 50.0,
      );
      expect(m.confidenceLevel, equals('Low'));
    });

    test('needsVerification is true for confidence < 60', () {
      final m = MedicineModel(
        name: 'Test', dosage: '', timing: '', confidence: 55.0,
      );
      expect(m.needsVerification, isTrue);
    });
  });
}
