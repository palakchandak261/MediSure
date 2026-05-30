import '../models/medicine_model.dart';
import 'package:flutter/material.dart';

/// Drug Interaction Service — checks for dangerous medicine combinations.
/// Database covers 50+ clinically significant interactions.
class DrugInteractionService {
  /// Map of drug name → list of interactions.
  /// Each interaction has: drug, severity (Critical/High/Medium/Low), warning.
  static const Map<String, List<Map<String, String>>> _interactions = {
    // ── NSAIDs & Analgesics ──────────────────────────────────────────────────
    'Aspirin': [
      {
        'drug': 'Ibuprofen',
        'severity': 'High',
        'warning':
            'Concurrent use increases risk of GI bleeding and reduces cardioprotective effect of aspirin.',
      },
      {
        'drug': 'Warfarin',
        'severity': 'Critical',
        'warning':
            'Severe bleeding risk. Aspirin inhibits platelet aggregation and warfarin inhibits clotting factors — combined effect is dangerous.',
      },
      {
        'drug': 'Clopidogrel',
        'severity': 'High',
        'warning':
            'Dual antiplatelet therapy increases bleeding risk significantly. Use only under cardiologist supervision.',
      },
      {
        'drug': 'Methotrexate',
        'severity': 'Critical',
        'warning':
            'Aspirin reduces methotrexate excretion, causing toxic accumulation. Can be fatal.',
      },
      {
        'drug': 'Heparin',
        'severity': 'Critical',
        'warning':
            'Combined anticoagulant and antiplatelet effect greatly increases hemorrhage risk.',
      },
    ],
    'Ibuprofen': [
      {
        'drug': 'Warfarin',
        'severity': 'Critical',
        'warning':
            'NSAIDs increase anticoagulant effect of warfarin and cause GI bleeding. Avoid combination.',
      },
      {
        'drug': 'Lithium',
        'severity': 'High',
        'warning':
            'NSAIDs reduce renal lithium clearance, increasing lithium toxicity risk.',
      },
      {
        'drug': 'ACE Inhibitors',
        'severity': 'High',
        'warning':
            'NSAIDs reduce antihypertensive effect and increase risk of acute kidney injury.',
      },
      {
        'drug': 'Methotrexate',
        'severity': 'Critical',
        'warning':
            'NSAIDs reduce methotrexate clearance, leading to severe toxicity.',
      },
      {
        'drug': 'Diuretics',
        'severity': 'Medium',
        'warning':
            'NSAIDs reduce diuretic efficacy and may cause fluid retention.',
      },
    ],
    'Paracetamol': [
      {
        'drug': 'Alcohol',
        'severity': 'High',
        'warning':
            'Chronic alcohol use with paracetamol causes severe hepatotoxicity. Limit alcohol strictly.',
      },
      {
        'drug': 'Warfarin',
        'severity': 'Medium',
        'warning':
            'Regular paracetamol use can enhance anticoagulant effect of warfarin. Monitor INR.',
      },
      {
        'drug': 'Isoniazid',
        'severity': 'High',
        'warning':
            'Isoniazid induces CYP2E1, increasing toxic paracetamol metabolite production.',
      },
      {
        'drug': 'Carbamazepine',
        'severity': 'Medium',
        'warning':
            'Carbamazepine induces paracetamol metabolism, increasing hepatotoxic metabolite.',
      },
    ],
    // ── Antibiotics ──────────────────────────────────────────────────────────
    'Amoxicillin': [
      {
        'drug': 'Warfarin',
        'severity': 'High',
        'warning':
            'Antibiotics alter gut flora, reducing vitamin K production and enhancing warfarin effect.',
      },
      {
        'drug': 'Methotrexate',
        'severity': 'High',
        'warning':
            'Amoxicillin reduces methotrexate renal excretion, increasing toxicity.',
      },
      {
        'drug': 'Oral Contraceptives',
        'severity': 'Medium',
        'warning':
            'May reduce contraceptive effectiveness. Use additional contraception during treatment.',
      },
    ],
    'Ciprofloxacin': [
      {
        'drug': 'Warfarin',
        'severity': 'High',
        'warning':
            'Ciprofloxacin inhibits warfarin metabolism, significantly increasing bleeding risk.',
      },
      {
        'drug': 'Theophylline',
        'severity': 'Critical',
        'warning':
            'Ciprofloxacin inhibits theophylline metabolism, causing toxicity (seizures, arrhythmia).',
      },
      {
        'drug': 'Antacids',
        'severity': 'Medium',
        'warning':
            'Antacids containing Mg/Al reduce ciprofloxacin absorption by up to 90%. Take 2 hours apart.',
      },
      {
        'drug': 'Tizanidine',
        'severity': 'Critical',
        'warning':
            'Ciprofloxacin dramatically increases tizanidine levels, causing severe hypotension.',
      },
    ],
    'Azithromycin': [
      {
        'drug': 'Warfarin',
        'severity': 'High',
        'warning':
            'Azithromycin can increase anticoagulant effect of warfarin. Monitor INR closely.',
      },
      {
        'drug': 'Amiodarone',
        'severity': 'Critical',
        'warning':
            'Both prolong QT interval — combined use risks fatal cardiac arrhythmia (Torsades de Pointes).',
      },
      {
        'drug': 'Digoxin',
        'severity': 'High',
        'warning':
            'Azithromycin increases digoxin absorption, risking digoxin toxicity.',
      },
    ],
    'Metronidazole': [
      {
        'drug': 'Alcohol',
        'severity': 'Critical',
        'warning':
            'Disulfiram-like reaction: severe nausea, vomiting, flushing, tachycardia. Avoid alcohol for 48h after last dose.',
      },
      {
        'drug': 'Warfarin',
        'severity': 'High',
        'warning':
            'Metronidazole inhibits warfarin metabolism, greatly increasing bleeding risk.',
      },
      {
        'drug': 'Lithium',
        'severity': 'High',
        'warning':
            'Metronidazole reduces lithium clearance, risking lithium toxicity.',
      },
    ],
    // ── Cardiovascular ───────────────────────────────────────────────────────
    'Warfarin': [
      {
        'drug': 'Vitamin K',
        'severity': 'High',
        'warning':
            'Vitamin K directly antagonizes warfarin. Sudden dietary changes can destabilize INR.',
      },
      {
        'drug': 'Fluconazole',
        'severity': 'Critical',
        'warning':
            'Fluconazole strongly inhibits warfarin metabolism, causing dangerous INR elevation.',
      },
      {
        'drug': 'Omeprazole',
        'severity': 'Medium',
        'warning':
            'Omeprazole may modestly increase warfarin effect. Monitor INR.',
      },
    ],
    'Atorvastatin': [
      {
        'drug': 'Clarithromycin',
        'severity': 'High',
        'warning':
            'Clarithromycin inhibits CYP3A4, increasing atorvastatin levels and myopathy risk.',
      },
      {
        'drug': 'Grapefruit',
        'severity': 'Medium',
        'warning':
            'Grapefruit inhibits CYP3A4, increasing statin blood levels. Avoid grapefruit juice.',
      },
      {
        'drug': 'Amiodarone',
        'severity': 'High',
        'warning':
            'Amiodarone increases statin levels, raising risk of myopathy and rhabdomyolysis.',
      },
      {
        'drug': 'Cyclosporine',
        'severity': 'Critical',
        'warning':
            'Cyclosporine dramatically increases atorvastatin levels, causing severe myopathy.',
      },
    ],
    'Amlodipine': [
      {
        'drug': 'Simvastatin',
        'severity': 'High',
        'warning':
            'Amlodipine inhibits simvastatin metabolism, increasing myopathy risk. Limit simvastatin to 20mg.',
      },
      {
        'drug': 'Cyclosporine',
        'severity': 'High',
        'warning':
            'Cyclosporine increases amlodipine levels, causing excessive blood pressure lowering.',
      },
    ],
    'Digoxin': [
      {
        'drug': 'Amiodarone',
        'severity': 'Critical',
        'warning':
            'Amiodarone increases digoxin levels by 50-100%. Risk of digoxin toxicity (bradycardia, arrhythmia).',
      },
      {
        'drug': 'Verapamil',
        'severity': 'Critical',
        'warning':
            'Verapamil increases digoxin levels and both slow AV conduction — risk of complete heart block.',
      },
      {
        'drug': 'Spironolactone',
        'severity': 'Medium',
        'warning':
            'Spironolactone may interfere with digoxin assay and increase digoxin levels.',
      },
    ],
    // ── Diabetes ─────────────────────────────────────────────────────────────
    'Metformin': [
      {
        'drug': 'Alcohol',
        'severity': 'High',
        'warning':
            'Alcohol increases risk of lactic acidosis with metformin. Avoid excessive alcohol.',
      },
      {
        'drug': 'Contrast Dye',
        'severity': 'High',
        'warning':
            'Iodinated contrast media with metformin risks acute kidney injury and lactic acidosis. Stop metformin before contrast procedures.',
      },
      {
        'drug': 'Cimetidine',
        'severity': 'Medium',
        'warning':
            'Cimetidine reduces metformin renal excretion, increasing plasma levels.',
      },
    ],
    'Glipizide': [
      {
        'drug': 'Fluconazole',
        'severity': 'High',
        'warning':
            'Fluconazole inhibits glipizide metabolism, causing severe hypoglycemia.',
      },
      {
        'drug': 'Alcohol',
        'severity': 'High',
        'warning':
            'Alcohol potentiates hypoglycemic effect and can cause disulfiram-like reaction.',
      },
      {
        'drug': 'Beta Blockers',
        'severity': 'Medium',
        'warning':
            'Beta blockers mask hypoglycemia symptoms (tachycardia) and may prolong hypoglycemic episodes.',
      },
    ],
    // ── Antihypertensives ────────────────────────────────────────────────────
    'Lisinopril': [
      {
        'drug': 'Potassium',
        'severity': 'High',
        'warning':
            'ACE inhibitors cause potassium retention. Potassium supplements risk dangerous hyperkalemia.',
      },
      {
        'drug': 'Spironolactone',
        'severity': 'High',
        'warning':
            'Both increase potassium levels — combined use risks life-threatening hyperkalemia.',
      },
      {
        'drug': 'NSAIDs',
        'severity': 'High',
        'warning':
            'NSAIDs reduce antihypertensive effect and increase risk of acute kidney injury.',
      },
    ],
    // ── Antihistamines ───────────────────────────────────────────────────────
    'Cetirizine': [
      {
        'drug': 'Alcohol',
        'severity': 'Medium',
        'warning':
            'Alcohol enhances CNS depression. Avoid driving or operating machinery.',
      },
      {
        'drug': 'Levocetirizine',
        'severity': 'High',
        'warning':
            'Duplicate therapy — both are cetirizine enantiomers. Do not take together.',
      },
      {
        'drug': 'Lorazepam',
        'severity': 'Medium',
        'warning':
            'Combined CNS depressant effect causes excessive sedation.',
      },
    ],
    // ── GI Medications ───────────────────────────────────────────────────────
    'Omeprazole': [
      {
        'drug': 'Clopidogrel',
        'severity': 'High',
        'warning':
            'Omeprazole inhibits CYP2C19, reducing clopidogrel activation and antiplatelet effect.',
      },
      {
        'drug': 'Methotrexate',
        'severity': 'High',
        'warning':
            'PPIs reduce methotrexate renal excretion, increasing toxicity risk.',
      },
      {
        'drug': 'Ketoconazole',
        'severity': 'Medium',
        'warning':
            'Omeprazole raises gastric pH, reducing ketoconazole absorption significantly.',
      },
    ],
    // ── Psychiatric ──────────────────────────────────────────────────────────
    'Sertraline': [
      {
        'drug': 'Tramadol',
        'severity': 'Critical',
        'warning':
            'Risk of serotonin syndrome (agitation, hyperthermia, seizures). Avoid combination.',
      },
      {
        'drug': 'MAO Inhibitors',
        'severity': 'Critical',
        'warning':
            'Potentially fatal serotonin syndrome. Do not use within 14 days of MAO inhibitor.',
      },
      {
        'drug': 'Warfarin',
        'severity': 'High',
        'warning':
            'SSRIs inhibit platelet aggregation and may enhance warfarin anticoagulation.',
      },
    ],
    'Alprazolam': [
      {
        'drug': 'Alcohol',
        'severity': 'Critical',
        'warning':
            'Combined CNS depression can cause respiratory failure. Potentially fatal.',
      },
      {
        'drug': 'Opioids',
        'severity': 'Critical',
        'warning':
            'Benzodiazepine + opioid combination is a leading cause of overdose death.',
      },
      {
        'drug': 'Ketoconazole',
        'severity': 'High',
        'warning':
            'Ketoconazole inhibits alprazolam metabolism, causing excessive sedation.',
      },
    ],
    // ── Thyroid ──────────────────────────────────────────────────────────────
    'Levothyroxine': [
      {
        'drug': 'Calcium',
        'severity': 'Medium',
        'warning':
            'Calcium reduces levothyroxine absorption. Take levothyroxine 4 hours before calcium supplements.',
      },
      {
        'drug': 'Iron',
        'severity': 'Medium',
        'warning':
            'Iron reduces levothyroxine absorption. Take 4 hours apart.',
      },
      {
        'drug': 'Antacids',
        'severity': 'Medium',
        'warning':
            'Antacids reduce levothyroxine absorption. Take 4 hours apart.',
      },
      {
        'drug': 'Warfarin',
        'severity': 'High',
        'warning':
            'Levothyroxine enhances warfarin anticoagulation. Monitor INR when thyroid dose changes.',
      },
    ],
  };

  /// Check for interactions between a list of medicines.
  List<Map<String, dynamic>> checkInteractions(List<MedicineModel> medicines) {
    final interactions = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (var i = 0; i < medicines.length; i++) {
      for (var j = i + 1; j < medicines.length; j++) {
        final med1 = medicines[i].name;
        final med2 = medicines[j].name;
        final key = '${med1}_$med2';

        if (seen.contains(key)) continue;
        seen.add(key);

        final interaction = _findInteraction(med1, med2);
        if (interaction != null) {
          interactions.add({
            'medicine1': med1,
            'medicine2': med2,
            'severity': interaction['severity'],
            'warning': interaction['warning'],
          });
        }
      }
    }

    // Sort by severity: Critical > High > Medium > Low
    interactions.sort((a, b) =>
        _severityOrder(b['severity']) - _severityOrder(a['severity']));

    return interactions;
  }

  /// Check interactions for a single medicine against a list.
  List<Map<String, dynamic>> checkSingleMedicine(
      String medicineName, List<String> otherMedicines) {
    final interactions = <Map<String, dynamic>>[];
    for (final other in otherMedicines) {
      final interaction = _findInteraction(medicineName, other);
      if (interaction != null) {
        interactions.add({
          'medicine1': medicineName,
          'medicine2': other,
          'severity': interaction['severity'],
          'warning': interaction['warning'],
        });
      }
    }
    return interactions;
  }

  Map<String, String>? _findInteraction(String med1, String med2) {
    for (final key in _interactions.keys) {
      if (_matches(med1, key)) {
        for (final interaction in _interactions[key]!) {
          if (_matches(med2, interaction['drug']!)) {
            return interaction;
          }
        }
      }
      if (_matches(med2, key)) {
        for (final interaction in _interactions[key]!) {
          if (_matches(med1, interaction['drug']!)) {
            return interaction;
          }
        }
      }
    }
    return null;
  }

  bool _matches(String medicine, String key) =>
      medicine.toLowerCase().contains(key.toLowerCase()) ||
      key.toLowerCase().contains(medicine.toLowerCase());

  int _severityOrder(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  /// Get severity color
  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB71C1C);
      case 'high':
        return const Color(0xFFE65100);
      case 'medium':
        return const Color(0xFFF9A825);
      case 'low':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  /// Get severity icon
  static IconData getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.dangerous_rounded;
      case 'high':
        return Icons.warning_rounded;
      case 'medium':
        return Icons.info_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  /// Total number of known interactions in the database
  int get totalInteractions =>
      _interactions.values.fold(0, (sum, list) => sum + list.length);
}
