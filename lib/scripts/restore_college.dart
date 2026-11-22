import 'package:cloud_firestore/cloud_firestore.dart';

/// Run this from Flutter DevTools Console or a temporary button
Future<void> restoreMissingCollege() async {
  final firestore = FirebaseFirestore.instance;

  print('🔄 Adding missing college...');

  const collegeId = 'admin_college_balqas';
  final collegeData = {
    'nameAr': 'المعهد العلي للعلوم الاداريه ببلقاس',
    'nameEn': 'Higher Institute of Administrative Sciences - Balqas',
    'location': 'Balqas',
    'isActive': true,
    'createdAt': DateTime.now().millisecondsSinceEpoch,
  };

  try {
    // Check if already exists
    final doc = await firestore.collection('colleges').doc(collegeId).get();
    if (doc.exists) {
      print('✅ College already exists');
      return;
    }

    // Create college
    await firestore.collection('colleges').doc(collegeId).set(collegeData);
    print('✅ Created college: ${collegeData['nameAr']}');

    // Create subcollections structure (placeholders will be auto-removed when real data added)
    final subcollections = [
      'students',
      'doctors',
      'tas',
      'managers',
      'levels',
      'courses',
      'exams',
      'researches',
      'attendance'
    ];

    for (final subCol in subcollections) {
      await firestore
          .collection('colleges')
          .doc(collegeId)
          .collection(subCol)
          .doc('_placeholder')
          .set({'_created': DateTime.now().millisecondsSinceEpoch});
    }

    print('✅ Created subcollections for: $collegeId');
    print('✨ Restore complete!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
