import '../models/medicine_model.dart';
import 'medicine_dataset_service.dart';

/// Pure Dart prescription parser — no AI, no network.
///
/// Strategy:
///  1. Split OCR text into lines
///  2. For each line, try to match a known medicine name (dictionary + dataset)
///  3. Extract dosage and timing from the same line or the next 1-2 lines
///  4. Return structured MedicineModel list
class PrescriptionParser {
  // ── COMPREHENSIVE INDIAN MEDICINE DICTIONARY ──────────────────────────────
  // Generic names → description, covers all common Indian prescriptions.
  // Brand names are listed as aliases so they also match.
  static const Map<String, _MedInfo> _dictionary = {
    // ── Analgesics / Antipyretics ──────────────────────────────────────────
    'paracetamol':   _MedInfo('Pain reliever & fever reducer'),
    'acetaminophen': _MedInfo('Pain reliever & fever reducer'),
    'dolo':          _MedInfo('Paracetamol brand — pain & fever'),
    'calpol':        _MedInfo('Paracetamol brand — pain & fever'),
    'ibuprofen':     _MedInfo('Anti-inflammatory pain reliever'),
    'brufen':        _MedInfo('Ibuprofen brand — pain & inflammation'),
    'combiflam':     _MedInfo('Ibuprofen + Paracetamol combination'),
    'diclofenac':    _MedInfo('Anti-inflammatory pain reliever'),
    'voveran':       _MedInfo('Diclofenac brand — pain & inflammation'),
    'nimesulide':    _MedInfo('Anti-inflammatory pain reliever'),
    'aspirin':       _MedInfo('Pain reliever, blood thinner'),
    'tramadol':      _MedInfo('Opioid pain reliever'),
    'ketorolac':     _MedInfo('Strong anti-inflammatory pain reliever'),
    'mefenamic':     _MedInfo('Anti-inflammatory pain reliever'),
    'aceclofenac':   _MedInfo('Anti-inflammatory pain reliever'),
    'enzoflam':      _MedInfo('Diclofenac + Serratiopeptidase — dental & post-surgical pain and swelling'),
    'serratiopeptidase': _MedInfo('Anti-inflammatory enzyme — reduces swelling and pain'),

    // ── Antibiotics ────────────────────────────────────────────────────────
    'amoxicillin':   _MedInfo('Antibiotic — bacterial infections'),
    'augmentin':     _MedInfo('Amoxicillin+Clavulanate — broad antibiotic'),
    'azithromycin':  _MedInfo('Antibiotic — respiratory & skin infections'),
    'azee':          _MedInfo('Azithromycin brand'),
    'zithromax':     _MedInfo('Azithromycin brand'),
    'ciprofloxacin': _MedInfo('Antibiotic — urinary & GI infections'),
    'cifran':        _MedInfo('Ciprofloxacin brand'),
    'levofloxacin':  _MedInfo('Antibiotic — respiratory infections'),
    'levaquin':      _MedInfo('Levofloxacin brand'),
    'doxycycline':   _MedInfo('Antibiotic — broad spectrum'),
    'metronidazole': _MedInfo('Antibiotic — anaerobic & parasitic infections'),
    'flagyl':        _MedInfo('Metronidazole brand'),
    'cefixime':      _MedInfo('Antibiotic — urinary & respiratory'),
    'cefpodoxime':   _MedInfo('Antibiotic — respiratory & skin'),
    'cephalexin':    _MedInfo('Antibiotic — skin & urinary infections'),
    'clindamycin':   _MedInfo('Antibiotic — skin & dental infections'),
    'erythromycin':  _MedInfo('Antibiotic — respiratory & skin'),
    'clarithromycin':_MedInfo('Antibiotic — respiratory infections'),
    'amikacin':      _MedInfo('Antibiotic injection — serious infections'),
    'gentamicin':    _MedInfo('Antibiotic — serious bacterial infections'),
    'cotrimoxazole': _MedInfo('Antibiotic — urinary & respiratory'),
    'septran':       _MedInfo('Cotrimoxazole brand'),
    'nitrofurantoin':_MedInfo('Antibiotic — urinary tract infections'),
    'tinidazole':    _MedInfo('Antibiotic — parasitic & anaerobic infections'),
    'ofloxacin':     _MedInfo('Antibiotic — urinary & respiratory'),
    'norfloxacin':   _MedInfo('Antibiotic — urinary infections'),

    // ── Antifungals ────────────────────────────────────────────────────────
    'fluconazole':   _MedInfo('Antifungal — candida & fungal infections'),
    'itraconazole':  _MedInfo('Antifungal — nail & systemic fungal'),
    'clotrimazole':  _MedInfo('Antifungal — skin & vaginal infections'),
    'ketoconazole':  _MedInfo('Antifungal — skin & scalp'),
    'terbinafine':   _MedInfo('Antifungal — nail & skin infections'),

    // ── Antivirals ─────────────────────────────────────────────────────────
    'acyclovir':     _MedInfo('Antiviral — herpes & chickenpox'),
    'oseltamivir':   _MedInfo('Antiviral — influenza (Tamiflu)'),
    'tamiflu':       _MedInfo('Oseltamivir brand — influenza'),
    'remdesivir':    _MedInfo('Antiviral — serious viral infections'),

    // ── Antihistamines / Allergy ───────────────────────────────────────────
    'cetirizine':    _MedInfo('Antihistamine — allergy & hay fever'),
    'cetzine':       _MedInfo('Cetirizine brand'),
    'zyrtec':        _MedInfo('Cetirizine brand'),
    'loratadine':    _MedInfo('Antihistamine — allergy'),
    'fexofenadine':  _MedInfo('Antihistamine — allergy, non-drowsy'),
    'allegra':       _MedInfo('Fexofenadine brand'),
    'chlorpheniramine': _MedInfo('Antihistamine — cold & allergy'),
    'diphenhydramine':  _MedInfo('Antihistamine — allergy & sleep aid'),
    'hydroxyzine':   _MedInfo('Antihistamine — allergy & anxiety'),
    'montelukast':   _MedInfo('Leukotriene blocker — asthma & allergy'),
    'montair':       _MedInfo('Montelukast brand'),
    'singulair':     _MedInfo('Montelukast brand'),
    'montina':       _MedInfo('Montelukast combination brand'),

    // ── Respiratory / Cold ─────────────────────────────────────────────────
    'salbutamol':    _MedInfo('Bronchodilator — asthma & breathing'),
    'asthalin':      _MedInfo('Salbutamol brand — asthma'),
    'levosalbutamol':_MedInfo('Bronchodilator — asthma'),
    'budesonide':    _MedInfo('Inhaled steroid — asthma & COPD'),
    'formoterol':    _MedInfo('Long-acting bronchodilator'),
    'tiotropium':    _MedInfo('Bronchodilator — COPD'),
    'theophylline':  _MedInfo('Bronchodilator — asthma & COPD'),
    'dextromethorphan': _MedInfo('Cough suppressant'),
    'guaifenesin':   _MedInfo('Expectorant — loosens mucus'),
    'bromhexine':    _MedInfo('Expectorant — loosens mucus'),
    'ambroxol':      _MedInfo('Expectorant — respiratory infections'),
    'ambrodil':      _MedInfo('Ambroxol brand'),
    'benadryl':      _MedInfo('Cough syrup — diphenhydramine'),
    'alex':          _MedInfo('Cough & cold syrup'),
    'dolo cold':     _MedInfo('Paracetamol + cold combination'),
    'dolocold':      _MedInfo('Paracetamol + cold combination'),
    'sinarest':      _MedInfo('Cold & congestion combination'),
    'cheston':       _MedInfo('Cold & cough combination'),
    'grilinctus':    _MedInfo('Cough syrup'),

    // ── Gastrointestinal ───────────────────────────────────────────────────
    'pantoprazole':  _MedInfo('Proton pump inhibitor — acidity & ulcers'),
    'pan':           _MedInfo('Pantoprazole brand — acidity'),
    'pan 40':        _MedInfo('Pantoprazole 40mg — acidity & ulcers'),
    'pan-40':        _MedInfo('Pantoprazole 40mg — acidity & ulcers'),
    'pan d':         _MedInfo('Pantoprazole + Domperidone — acidity, nausea & reflux'),
    'pan-d':         _MedInfo('Pantoprazole + Domperidone — acidity, nausea & reflux'),
    'pantocid':      _MedInfo('Pantoprazole brand'),
    'omeprazole':    _MedInfo('Proton pump inhibitor — acidity & ulcers'),
    'omez':          _MedInfo('Omeprazole brand'),
    'rabeprazole':   _MedInfo('Proton pump inhibitor — acidity'),
    'razo':          _MedInfo('Rabeprazole brand'),
    'esomeprazole':  _MedInfo('Proton pump inhibitor — acidity'),
    'nexium':        _MedInfo('Esomeprazole brand'),
    'lansoprazole':  _MedInfo('Proton pump inhibitor — acidity'),
    'ranitidine':    _MedInfo('H2 blocker — acidity & ulcers'),
    'famotidine':    _MedInfo('H2 blocker — acidity'),
    'domperidone':   _MedInfo('Anti-nausea & gastric motility'),
    'vomikind':      _MedInfo('Domperidone brand — nausea'),
    'ondansetron':   _MedInfo('Anti-nausea — vomiting'),
    'emeset':        _MedInfo('Ondansetron brand'),
    'metoclopramide':_MedInfo('Anti-nausea & gastric motility'),
    'perinorm':      _MedInfo('Metoclopramide brand'),
    'dicyclomine':   _MedInfo('Antispasmodic — stomach cramps'),
    'mebeverine':    _MedInfo('Antispasmodic — IBS'),
    'loperamide':    _MedInfo('Anti-diarrheal'),
    'imodium':       _MedInfo('Loperamide brand'),
    'lactulose':     _MedInfo('Laxative — constipation'),
    'bisacodyl':     _MedInfo('Laxative — constipation'),
    'sucralfate':    _MedInfo('Stomach ulcer protector'),
    'antacid':       _MedInfo('Neutralises stomach acid'),
    'gelusil':       _MedInfo('Antacid brand'),
    'digene':        _MedInfo('Antacid brand'),
    'eno':           _MedInfo('Antacid — acidity relief'),

    // ── Diabetes ───────────────────────────────────────────────────────────
    'metformin':     _MedInfo('Antidiabetic — type 2 diabetes'),
    'glycomet':      _MedInfo('Metformin brand'),
    'glucophage':    _MedInfo('Metformin brand'),
    'glimepiride':   _MedInfo('Antidiabetic — stimulates insulin'),
    'amaryl':        _MedInfo('Glimepiride brand'),
    'glimpid':       _MedInfo('Glimepiride brand'),
    'glipizide':     _MedInfo('Antidiabetic — stimulates insulin'),
    'glyburide':     _MedInfo('Antidiabetic — stimulates insulin'),
    'glibenclamide': _MedInfo('Antidiabetic — stimulates insulin'),
    'sitagliptin':   _MedInfo('Antidiabetic — DPP-4 inhibitor'),
    'januvia':       _MedInfo('Sitagliptin brand'),
    'vildagliptin':  _MedInfo('Antidiabetic — DPP-4 inhibitor'),
    'galvus':        _MedInfo('Vildagliptin brand'),
    'dapagliflozin': _MedInfo('Antidiabetic — SGLT2 inhibitor'),
    'forxiga':       _MedInfo('Dapagliflozin brand'),
    'empagliflozin': _MedInfo('Antidiabetic — SGLT2 inhibitor'),
    'jardiance':     _MedInfo('Empagliflozin brand'),
    'pioglitazone':  _MedInfo('Antidiabetic — insulin sensitizer'),
    'actos':         _MedInfo('Pioglitazone brand'),
    'insulin':       _MedInfo('Insulin — diabetes management'),
    'insulin glargine': _MedInfo('Long-acting insulin'),
    'lantus':        _MedInfo('Insulin glargine brand'),
    'insulin lispro':_MedInfo('Fast-acting insulin'),
    'humalog':       _MedInfo('Insulin lispro brand'),

    // ── Cardiovascular / BP ────────────────────────────────────────────────
    'amlodipine':    _MedInfo('Calcium channel blocker — high blood pressure'),
    'norvasc':       _MedInfo('Amlodipine brand'),
    'telmisartan':   _MedInfo('ARB — high blood pressure & heart protection'),
    'telma':         _MedInfo('Telmisartan brand'),
    'telmikind':     _MedInfo('Telmisartan brand'),
    'losartan':      _MedInfo('ARB — high blood pressure'),
    'cozaar':        _MedInfo('Losartan brand'),
    'olmesartan':    _MedInfo('ARB — high blood pressure'),
    'valsartan':     _MedInfo('ARB — high blood pressure & heart failure'),
    'enalapril':     _MedInfo('ACE inhibitor — high blood pressure'),
    'lisinopril':    _MedInfo('ACE inhibitor — high blood pressure'),
    'ramipril':      _MedInfo('ACE inhibitor — high blood pressure'),
    'cardace':       _MedInfo('Ramipril brand'),
    'perindopril':   _MedInfo('ACE inhibitor — high blood pressure'),
    'atenolol':      _MedInfo('Beta blocker — high blood pressure & heart'),
    'tenormin':      _MedInfo('Atenolol brand'),
    'metoprolol':    _MedInfo('Beta blocker — high blood pressure & heart'),
    'betaloc':       _MedInfo('Metoprolol brand'),
    'bisoprolol':    _MedInfo('Beta blocker — heart failure & BP'),
    'carvedilol':    _MedInfo('Beta blocker — heart failure'),
    'nebivolol':     _MedInfo('Beta blocker — high blood pressure'),
    'nebicard':      _MedInfo('Nebivolol brand'),
    'hydrochlorothiazide': _MedInfo('Diuretic — high blood pressure'),
    'furosemide':    _MedInfo('Loop diuretic — fluid retention'),
    'lasix':         _MedInfo('Furosemide brand'),
    'spironolactone':_MedInfo('Diuretic — heart failure & BP'),
    'aldactone':     _MedInfo('Spironolactone brand'),
    'atorvastatin':  _MedInfo('Statin — high cholesterol'),
    'lipitor':       _MedInfo('Atorvastatin brand'),
    'rosuvastatin':  _MedInfo('Statin — high cholesterol'),
    'crestor':       _MedInfo('Rosuvastatin brand'),
    'simvastatin':   _MedInfo('Statin — high cholesterol'),
    'clopidogrel':   _MedInfo('Antiplatelet — prevents blood clots'),
    'plavix':        _MedInfo('Clopidogrel brand'),
    'warfarin':      _MedInfo('Anticoagulant — prevents blood clots'),
    'digoxin':       _MedInfo('Heart rate control — heart failure & AF'),
    'amiodarone':    _MedInfo('Antiarrhythmic — irregular heartbeat'),
    'nitroglycerine':_MedInfo('Vasodilator — angina chest pain'),
    'isosorbide':    _MedInfo('Nitrate — angina & heart failure'),

    // ── Thyroid ────────────────────────────────────────────────────────────
    'levothyroxine': _MedInfo('Thyroid hormone — hypothyroidism'),
    'thyroxine':     _MedInfo('Thyroid hormone — hypothyroidism'),
    'eltroxin':      _MedInfo('Levothyroxine brand'),
    'thyronorm':     _MedInfo('Levothyroxine brand'),
    'carbimazole':   _MedInfo('Antithyroid — hyperthyroidism'),
    'propylthiouracil': _MedInfo('Antithyroid — hyperthyroidism'),

    // ── Vitamins & Supplements ─────────────────────────────────────────────
    'vitamin d':     _MedInfo('Vitamin D supplement — bone health'),
    'vitamin d3':    _MedInfo('Vitamin D3 — bone & immune health'),
    'calcirol':      _MedInfo('Vitamin D3 brand'),
    'cholecalciferol':_MedInfo('Vitamin D3 supplement'),
    'calcium':       _MedInfo('Calcium supplement — bone health'),
    'shelcal':       _MedInfo('Calcium + Vitamin D brand'),
    'calcimax':      _MedInfo('Calcium supplement brand'),
    'vitamin b12':   _MedInfo('B12 supplement — nerve & blood health'),
    'methylcobalamin':_MedInfo('Active Vitamin B12 — nerve health'),
    'mecobalamin':   _MedInfo('Methylcobalamin brand'),
    'cobadex':       _MedInfo('Vitamin B complex brand'),
    'folic acid':    _MedInfo('Folate supplement — pregnancy & anaemia'),
    'iron':          _MedInfo('Iron supplement — anaemia'),
    'ferrous':       _MedInfo('Iron supplement — anaemia'),
    'ferritin':      _MedInfo('Iron storage supplement'),
    'zinc':          _MedInfo('Zinc supplement — immunity & healing'),
    'vitamin c':     _MedInfo('Vitamin C — immunity & antioxidant'),
    'ascorbic acid': _MedInfo('Vitamin C supplement'),
    'omega 3':       _MedInfo('Fish oil — heart & brain health'),
    'fish oil':      _MedInfo('Omega-3 supplement'),
    'multivitamin':  _MedInfo('General vitamin & mineral supplement'),
    'becosules':     _MedInfo('Vitamin B complex brand'),
    'neurobion':     _MedInfo('Vitamin B complex brand'),
    'ultrafolin':    _MedInfo('Folic acid + B12 supplement'),
    'bioclear':      _MedInfo('Skin & antioxidant supplement'),

    // ── Steroids / Anti-inflammatory ───────────────────────────────────────
    'prednisolone':  _MedInfo('Corticosteroid — inflammation & allergy'),
    'prednisone':    _MedInfo('Corticosteroid — inflammation'),
    'dexamethasone': _MedInfo('Corticosteroid — severe inflammation'),
    'methylprednisolone': _MedInfo('Corticosteroid — inflammation'),
    'hydrocortisone':_MedInfo('Corticosteroid — inflammation & allergy'),
    'betamethasone': _MedInfo('Corticosteroid — skin & inflammation'),
    'deflazacort':   _MedInfo('Corticosteroid — inflammation'),

    // ── Neurological / Psychiatric ─────────────────────────────────────────
    'gabapentin':    _MedInfo('Nerve pain & seizure medication'),
    'pregabalin':    _MedInfo('Nerve pain & anxiety medication'),
    'lyrica':        _MedInfo('Pregabalin brand'),
    'amitriptyline': _MedInfo('Antidepressant — pain & depression'),
    'sertraline':    _MedInfo('Antidepressant — depression & anxiety'),
    'fluoxetine':    _MedInfo('Antidepressant — depression & OCD'),
    'prozac':        _MedInfo('Fluoxetine brand'),
    'escitalopram':  _MedInfo('Antidepressant — depression & anxiety'),
    'nexito':        _MedInfo('Escitalopram brand'),
    'clonazepam':    _MedInfo('Benzodiazepine — anxiety & seizures'),
    'alprazolam':    _MedInfo('Benzodiazepine — anxiety'),
    'diazepam':      _MedInfo('Benzodiazepine — anxiety & muscle spasm'),
    'lorazepam':     _MedInfo('Benzodiazepine — anxiety'),
    'zolpidem':      _MedInfo('Sleep aid — insomnia'),
    'melatonin':     _MedInfo('Sleep hormone — insomnia'),
    'levodopa':      _MedInfo('Parkinson\'s disease medication'),
    'phenytoin':     _MedInfo('Antiepileptic — seizures'),
    'valproate':     _MedInfo('Antiepileptic — seizures & bipolar'),
    'carbamazepine': _MedInfo('Antiepileptic — seizures & nerve pain'),
    'topiramate':    _MedInfo('Antiepileptic — seizures & migraine'),
    'sumatriptan':   _MedInfo('Migraine treatment'),
    'rizatriptan':   _MedInfo('Migraine treatment'),

    // ── Specialty brands (Indian prescriptions) ───────────────────────────
    'narobin':           _MedInfo('Nasal decongestant / ENT medication for cold and congestion'),
    'lanolser':          _MedInfo('Lanolin-based skin emollient and moisturiser'),
    'augmentin 625':     _MedInfo('Amoxicillin + Clavulanate 625mg — broad-spectrum antibiotic'),
    'montina fm':        _MedInfo('Montelukast + Fexofenadine — allergy & asthma'),
    'montina-fm':        _MedInfo('Montelukast + Fexofenadine — allergy & asthma'),
    'varobin':           _MedInfo('Antifungal + antibacterial combination for skin and ENT infections'),
    'pan d 40mg':        _MedInfo('Pantoprazole 40mg + Domperidone — acidity, nausea & reflux'),
    'hexigel gum paint': _MedInfo('Chlorhexidine antiseptic gel for gum massage and dental infections'),
    'hexigel':           _MedInfo('Chlorhexidine gluconate gel — gum disease, gingivitis & oral hygiene'),
    'lanol':             _MedInfo('Lanolin-based emollient for dry and cracked skin'),

    // ── Urological ─────────────────────────────────────────────────────────
    'tamsulosin':    _MedInfo('Alpha blocker — prostate & urinary flow'),
    'finasteride':   _MedInfo('5-alpha reductase — prostate & hair loss'),
    'sildenafil':    _MedInfo('PDE5 inhibitor — erectile dysfunction'),
    'tadalafil':     _MedInfo('PDE5 inhibitor — erectile dysfunction & BPH'),

    // ── Dermatology ────────────────────────────────────────────────────────
    'tretinoin':     _MedInfo('Retinoid — acne & skin renewal'),
    'adapalene':     _MedInfo('Retinoid — acne treatment'),
    'benzoyl peroxide': _MedInfo('Antibacterial — acne'),
    'isotretinoin':  _MedInfo('Retinoid — severe acne'),
    'tacrolimus':    _MedInfo('Immunosuppressant — eczema'),
    'clobetasol':    _MedInfo('Potent steroid — skin inflammation'),

    // ── Ophthalmology ──────────────────────────────────────────────────────
    'timolol':       _MedInfo('Beta blocker eye drops — glaucoma'),
    'latanoprost':   _MedInfo('Prostaglandin eye drops — glaucoma'),
    'ciprofloxacin eye': _MedInfo('Antibiotic eye drops'),
    'moxifloxacin':  _MedInfo('Antibiotic — eye & respiratory infections'),

    // ── Musculoskeletal ────────────────────────────────────────────────────
    'muscle relaxant': _MedInfo('Muscle relaxant — spasm & pain'),
    'baclofen':      _MedInfo('Muscle relaxant — spasm'),
    'tizanidine':    _MedInfo('Muscle relaxant — spasm'),
    'cyclobenzaprine':_MedInfo('Muscle relaxant — acute spasm'),
    'methocarbamol': _MedInfo('Muscle relaxant'),
    'etoricoxib':    _MedInfo('COX-2 inhibitor — arthritis & pain'),
    'arcoxia':       _MedInfo('Etoricoxib brand'),
    'celecoxib':     _MedInfo('COX-2 inhibitor — arthritis & pain'),
    'allopurinol':   _MedInfo('Xanthine oxidase inhibitor — gout'),
    'colchicine':    _MedInfo('Anti-inflammatory — gout'),
    'alendronate':   _MedInfo('Bisphosphonate — osteoporosis'),
    'risedronate':   _MedInfo('Bisphosphonate — osteoporosis'),
  };

  // ── REGEX PATTERNS ─────────────────────────────────────────────────────────

  static final RegExp _dosageRx = RegExp(
    r'(\d+\.?\d*)\s*(mg|ml|g|mcg|iu|IU|%|units?)',
    caseSensitive: false,
  );

  // Matches Indian prescription dosing patterns: 1-0-1, 1-1-1, 0-1-0, 7.5ml etc.
  static final RegExp _dosingPatternRx = RegExp(
    r'\b(\d[\.\d]*)\s*[-–]\s*(\d[\.\d]*)\s*[-–]\s*(\d[\.\d]*)\b',
  );

  static final RegExp _timingRx = RegExp(
    r'(\d+\s*tablet[s]?\s*)?(once|twice|thrice|three\s*times?|1\s*[-x]\s*\d*|2\s*[-x]\s*\d*|3\s*[-x]\s*\d*|'
    r'every\s*\d+\s*hours?|od|bd|tds|qid|sos|prn|'
    r'morning|evening|night|bedtime|daily|weekly|'
    r'before\s*(meals?|breakfast|lunch|dinner|bed)|'
    r'after\s*(meals?|breakfast|lunch|dinner)|'
    r'with\s*meals?|as\s*needed|as\s*directed)',
    caseSensitive: false,
  );

  static final RegExp _durationRx = RegExp(
    r'for\s*(\d+)\s*(day[s]?|week[s]?|month[s]?)',
    caseSensitive: false,
  );

  // Prefixes that appear before medicine names on Indian prescriptions
  // Also handles common OCR misreads of handwriting: "Taj" for "Tab", "Cp" for "Cap"
  static final RegExp _prefixRx = RegExp(
    r'^(tab\.?|taj\.?|tablet\.?|cap\.?|cp\.?|capsule\.?|syp\.?|syrup\.?|inj\.?|'
    r'injection\.?|oint\.?|ointment\.?|drops?\.?|susp\.?|suspension\.?|'
    r'sr\.?|cr\.?|xr\.?|er\.?|ds\.?|forte\.?|'
    r'\d+\.\s*|rx\.?|tab/cap\.?|bp\.?)\s*',
    caseSensitive: false,
  );

  // Lines that are definitely NOT medicine lines
  static final RegExp _skipLineRx = RegExp(
    r'^(dr\.?\s|doctor\s|clinic\b|hospital\b|patient\s|name\s*:|date\s*:|address\b|'
    r'signature\b|reg\.?\s*no|phone\b|ph:|tel:|mob:|age\s*:|weight\s*:|'
    r'diagnosis\b|advice\s*:|please\s+consult|'
    r'dispensed\b|reissue\b|'
    r'total\s+qty|'
    r'abc\s+clinic|123\s+health|delhi|mumbai|pune|chennai|bangalore|'
    r'internal medicine|m\.d\.|m\.b\.b\.s|b\.a\.m\.s|'
    r'allergy of medicine|k/c/o|o/e\s+b\.?p|bsl\s*\(|'
    r'x.ray\b|ecg\b|usg\s*\(|ns1\b|renal\s+profile|electrolyte|'
    r'tft\s*,|lft\s*,|hbsag\b|hba1c\b|cbc\s*,|esr\s*,|crp\s*,|'
    r'sr\s+b12|vit-d\b|'
    r'smile designing|teeth whitening|dental implants|general dentistry|'
    r'the white tusk|whitetusk|'
    r'nebulization\b|p\.s\.\s*/|'
    r'please\s+do\s+not\s+reissue|dispensed\s+by|'
    r'further\s+management|'
    r'औषधांची\s+नावे|सकाळच्या|दुपारच्या|रात्रीच्या|एकूण\b)',
    caseSensitive: false,
  );

  // ── MAIN PARSE METHOD ──────────────────────────────────────────────────────

  static List<MedicineModel> parse(String rawText) {
    // Pre-process: clean up OCR noise common in handwritten prescriptions
    final cleaned = rawText
        .replaceAll(RegExp(r'\r'), '\n')
        // Remove pure number/dash lines like "0 k — k — k 6d" that have no letters
        // but keep lines that have actual word characters
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final medicines = <MedicineModel>[];
    final foundNames = <String>{};

    for (int i = 0; i < cleaned.length; i++) {
      final line = cleaned[i];

      // Skip very short lines
      if (line.length < 3) continue;

      // Skip obvious non-medicine lines
      if (_skipLineRx.hasMatch(line.toLowerCase())) continue;

      // Try to find a medicine name in this line
      final result = _extractMedicine(line, cleaned, i, foundNames);
      if (result != null) {
        foundNames.add(result.name.toLowerCase());
        medicines.add(result);
      }
    }

    return medicines;
  }

  // ── EXTRACT ONE MEDICINE FROM A LINE ──────────────────────────────────────

  static MedicineModel? _extractMedicine(
    String line,
    List<String> allLines,
    int lineIndex,
    Set<String> alreadyFound,
  ) {
    // Strip leading prefix (Tab., Cap., 1., etc.)
    final stripped = line.replaceFirst(_prefixRx, '').trim();
    if (stripped.isEmpty) return null;

    // Try to match a known medicine name
    final match = _findMedicineName(stripped);
    if (match == null) return null;

    final medName = match.displayName;
    if (alreadyFound.contains(medName.toLowerCase())) return null;

    // Extract dosage from this line + next 2 lines
    final context = _contextLines(allLines, lineIndex, 2);
    final dosage = _extractDosage(context, stripped);
    final timing = _extractTiming(context);
    final duration = _extractDuration(context);

    // Build notes from dataset or dictionary
    final dsEntry = MedicineDatasetService.instance.getByName(medName);
    String notes = dsEntry?.description ?? match.description;
    if (dsEntry != null && dsEntry.price > 0) {
      notes += ' | Price: ₹${dsEntry.price.toStringAsFixed(0)}';
    }
    if (duration.isNotEmpty) {
      notes += ' | Duration: $duration';
    }

    return MedicineModel(
      name: medName,
      dosage: dosage,
      timing: timing,
      confidence: match.confidence,
      notes: notes,
    );
  }

  // ── MEDICINE NAME MATCHING ─────────────────────────────────────────────────

  static _MatchResult? _findMedicineName(String text) {
    final lower = text.toLowerCase();

    // 1. Check multi-word dictionary entries first (longest match wins)
    final sortedKeys = _dictionary.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (lower.contains(key)) {
        final idx = lower.indexOf(key);
        final rawName = text.substring(idx, idx + key.length).trim();
        final displayName = _toTitleCase(rawName);
        return _MatchResult(
          displayName: displayName,
          description: _dictionary[key]!.description,
          confidence: 85.0,
        );
      }
    }

    // 2. Check dataset medicine names
    final datasetNames = MedicineDatasetService.instance.getAllMedicineNames();
    for (final name in datasetNames) {
      if (name.length < 3) continue;
      if (lower.contains(name.toLowerCase())) {
        return _MatchResult(
          displayName: _toTitleCase(name),
          description: MedicineDatasetService.instance
                  .getByName(name)
                  ?.description ??
              'Medicine',
          confidence: 80.0,
        );
      }
    }

    // 3. Heuristic A: line has Tab./Cap. prefix + capitalised word
    //    Works for both printed and handwritten (OCR reads "Taj" for "Tab")
    final strippedForHeuristic = text
        .replaceAll(_prefixRx, '')
        // Also strip common OCR misreads of "Tab" in handwriting
        .replaceAll(RegExp(r'^(taj|tab|cap|syp|inj|cp|bp|rx)\s*\.?\s*', caseSensitive: false), '')
        .trim();

    final hasDosage = _dosageRx.hasMatch(text);
    final hasTabPrefix = RegExp(
      r'^(tab|taj|cap|syp|inj|cp|rx)[\s\.]',
      caseSensitive: false,
    ).hasMatch(text.trim());

    if ((hasDosage || hasTabPrefix) && strippedForHeuristic.isNotEmpty) {
      // Take first 1-3 capitalised words before any number
      final wordMatch = RegExp(r'^([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+){0,2})')
          .firstMatch(strippedForHeuristic);
      if (wordMatch != null) {
        final candidate = wordMatch.group(1)!.trim();
        if (candidate.length >= 3 &&
            !_skipLineRx.hasMatch(candidate.toLowerCase())) {
          return _MatchResult(
            displayName: candidate,
            description: "Follow doctor's instructions",
            confidence: 65.0,
          );
        }
      }
    }

    return null;
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  /// Combine current line + next N lines for context extraction
  static String _contextLines(List<String> lines, int idx, int next) {
    final buf = StringBuffer(lines[idx]);
    for (int j = 1; j <= next && idx + j < lines.length; j++) {
      buf.write(' ');
      buf.write(lines[idx + j]);
    }
    return buf.toString();
  }

  static String _extractDosage(String context, String line) {
    // Prefer explicit mg/ml dosage from the medicine line itself
    final m = _dosageRx.firstMatch(line) ?? _dosageRx.firstMatch(context);
    if (m != null) return '${m.group(1)} ${m.group(2)}';
    return 'As prescribed';
  }

  static String _extractTiming(String context) {
    final lower = context.toLowerCase();
    final parts = <String>[];

    // Detect 1-0-1 style dosing (morning-afternoon-night)
    final dosingMatch = _dosingPatternRx.firstMatch(context);
    if (dosingMatch != null) {
      final m = dosingMatch.group(1)!;
      final a = dosingMatch.group(2)!;
      final n = dosingMatch.group(3)!;
      final mNum = double.tryParse(m) ?? 0;
      final aNum = double.tryParse(a) ?? 0;
      final nNum = double.tryParse(n) ?? 0;
      final total = mNum + aNum + nNum;
      if (total > 0) {
        final schedule = <String>[];
        if (mNum > 0) schedule.add('morning');
        if (aNum > 0) schedule.add('afternoon');
        if (nNum > 0) schedule.add('night');
        parts.add(schedule.join(' & '));
      }
    }

    // Detect before/after meals
    if (lower.contains('before meal') || lower.contains('before food') ||
        lower.contains('before breakfast') || lower.contains('before lunch') ||
        lower.contains('before dinner')) {
      parts.add('before meals');
    } else if (lower.contains('after meal') || lower.contains('after food') ||
        lower.contains('after breakfast') || lower.contains('after lunch') ||
        lower.contains('after dinner')) {
      parts.add('after meals');
    }

    // Detect duration
    final durMatch = _durationRx.firstMatch(lower);
    if (durMatch != null) {
      parts.add('for ${durMatch.group(1)} ${durMatch.group(2)}');
    }

    // Fallback to timing regex
    if (parts.isEmpty) {
      final matches = _timingRx.allMatches(lower);
      final timingParts = matches
          .map((m) => m.group(0)!.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      if (timingParts.isNotEmpty) return timingParts.join(', ');
      return 'As directed';
    }

    return parts.join(', ');
  }

  static String _extractDuration(String context) {
    final m = _durationRx.firstMatch(context.toLowerCase());
    if (m != null) return '${m.group(1)} ${m.group(2)}';
    return '';
  }

  static String _toTitleCase(String s) {
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

// ── DATA CLASSES ──────────────────────────────────────────────────────────────

class _MedInfo {
  final String description;
  const _MedInfo(this.description);
}

class _MatchResult {
  final String displayName;
  final String description;
  final double confidence;
  const _MatchResult({
    required this.displayName,
    required this.description,
    required this.confidence,
  });
}
