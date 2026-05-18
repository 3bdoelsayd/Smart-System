// import 'dart:math';
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:crypto/crypto.dart';
//
// Future<void> uploadStudents() async {
//   final firestore = FirebaseFirestore.instance;
//
//   // تشفير الباسورد الموحد: 123456
//   const String originalPassword = "123456";
//   const String salt = "SystemSalt2026";
//   final String hashedPassword = sha256.convert(utf8.encode(originalPassword + salt)).toString();
//
//   List<String> firstNames = ["محمد", "أحمد", "محمود", "عبدالله", "يوسف", "عمر", "علي", "مصطفى", "إبراهيم", "حسن", "سعيد", "خالد", "طارق", "كريم", "ياسين"];
//   List<String> lastNames = ["أحمد", "محمد", "حسن", "علي", "محمود", "السيد", "إبراهيم", "مصطفى", "صلاح", "جمال", "يوسف", "منصور", "عبده"];
//   List<String> divisions = ["نظم معلومات الاعمال", "محاسبه"];
//   List<String> groups = ["A", "B", "C"];
//
//   Random random = Random();
//
//   // سنقوم برفع 1000 طالب جديد
//   int totalToUpload = 1000;
//   int batchSize = 500; // حد الفايربيز للباتش الواحد
//
//   for (int i = 0; i < totalToUpload; i += batchSize) {
//     WriteBatch batch = firestore.batch();
//
//     for (int j = 1; j <= batchSize; j++) {
//       int currentIdx = i + j;
//       // IDs تبدأ من 2025001 لضمان عدم التكرار
//       String studentId = (2025000 + currentIdx).toString();
//
//       DocumentReference docRef = firestore.collection("students").doc(studentId);
//
//       batch.set(docRef, {
//         "id": studentId,
//         "name": "${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}",
//         "division": divisions[random.nextInt(divisions.length)],
//         "level": random.nextInt(4) + 1,
//         "group": groups[random.nextInt(groups.length)],
//         "password": hashedPassword,
//       });
//     }
//
//     await batch.commit();
//     print("📦 تم رفع دفعة من ${i + batchSize} طالب...");
//   }
//
//   print("✅ تم رفع 1000 طالب إضافي بنجاح (المجموع الحالي 1500)");
// }
