// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
//
// class MigrationUtility {
//   static Future<void> migrateAllData() async {
//     final firestore = FirebaseFirestore.instance;
//     const String collegeId = "commerce";
//     const String salt = "SystemSalt2026";
//     // الباسورد الجديد للدكاترة فقط: 123456
//     final String hashedDoctorPassword = sha256.convert(utf8.encode("123456" + salt)).toString();
//
//     print("🚀 Starting Optimized Migration...");
//
//     // 1. نقل الطلاب (بدون تغيير الباسورد) - استخدام Batches للسرعة
//     final studentsSnapshot = await firestore.collection('students').get();
//     if (studentsSnapshot.docs.isNotEmpty) {
//       WriteBatch batch = firestore.batch();
//       int count = 0;
//
//       for (var student in studentsSnapshot.docs) {
//         final data = student.data();
//         final newDocRef = firestore
//             .collection('colleges')
//             .doc(collegeId)
//             .collection('students')
//             .doc(student.id);
//
//         batch.set(newDocRef, {
//           ...data,
//           // نحتفظ بالباسورد القديم للطالب كما هو
//           'collegeId': collegeId,
//           'migratedAt': FieldValue.serverTimestamp(),
//         });
//
//         count++;
//         if (count >= 450) {
//           await batch.commit();
//           batch = firestore.batch();
//           count = 0;
//         }
//       }
//       await batch.commit();
//     }
//     print("Students migrated (keeping original passwords) ✅");
//
//     // 2. نقل الدكاترة (مع تغيير الباسورد لـ 123456)
//     final doctorsSnapshot = await firestore.collection('doctors').get();
//     for (var doctor in doctorsSnapshot.docs) {
//       final data = doctor.data();
//       final doctorRef = firestore.collection('colleges').doc(collegeId).collection('doctors').doc(doctor.id);
//
//       // نقل بيانات الدكتور الأساسية
//       await doctorRef.set({
//         ...data,
//         'collegeId': collegeId,
//         'migratedAt': FieldValue.serverTimestamp(),
//       });
//
//       // تعيين الباسورد الجديد للدكتور في المكان الآمن
//       WriteBatch subBatch = firestore.batch();
//
//       subBatch.set(doctorRef.collection('private').doc('credentials'), {
//         'password': hashedDoctorPassword,
//       });
//
//       // نقل المواد التابعة للدكتور
//       final subjectsSnapshot = await firestore.collection('doctors').doc(doctor.id).collection('subjects').get();
//       for (var subject in subjectsSnapshot.docs) {
//         subBatch.set(doctorRef.collection('subjects').doc(subject.id), subject.data());
//       }
//
//       await subBatch.commit();
//     }
//
//     print("Doctors migrated (passwords reset to 123456) ✅");
//     print("Migration Completed Successfully 🔥");
//   }
// }
