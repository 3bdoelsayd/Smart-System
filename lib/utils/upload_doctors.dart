// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:crypto/crypto.dart';
//
// Future<void> uploadDoctors() async {
//   final firestore = FirebaseFirestore.instance;
//
//   // تشفير كلمة المرور الافتراضية
//   const String originalPassword = "123456";
//   const String salt = "SystemSalt2026";
//   final String hashedPassword = sha256.convert(utf8.encode(originalPassword + salt)).toString();
//
//   final List<Map<String, dynamic>> doctors = [
//     {
//       "id": "doc001",
//       "name": "نور الإسلام إبراهيم عبد الحميد",
//       "subjects": [
//         {"division": "all", "level": "1", "name": "حقوق الإنسان"},
//         {"division": "all", "level": "1", "name": "مبادئ العلوم السياسية"},
//       ]
//     },
//     {
//       "id": "doc002",
//       "name": "عثمان بيومي العاصي",
//       "subjects": [
//         {"division": "all", "level": "1", "name": "طرق ومهارات الاتصال"},
//         {"division": "نظم معلومات الاعمال", "level": "3", "name": "ريادة الأعمال"},
//         {"division": "محاسبه", "level": "3", "name": "ريادة الأعمال"},
//       ]
//     },
//     {
//       "id": "doc003",
//       "name": "محمد حامد رشاد",
//       "subjects": [
//         {"division": "all", "level": "1", "name": "التفكير الابتكاري"},
//         {"division": "نظم معلومات الاعمال", "level": "4", "name": "دراسة جدوى المشروعات"},
//         {"division": "محاسبه", "level": "4", "name": "دراسة جدوى المشروعات"},
//       ]
//     },
//     {
//       "id": "doc004",
//       "name": "أماني مسعد المرسي",
//       "subjects": [
//         {"division": "all", "level": "1", "name": "ريادة الأعمال"},
//         {"division": "نظم معلومات الاعمال", "level": "4", "name": "الإحصاء التطبيقي"},
//         {"division": "محاسبه", "level": "4", "name": "الإحصاء التطبيقي"},
//       ]
//     },
//     {
//       "id": "doc005",
//       "name": "ماجدة أحمد عبد القادر",
//       "subjects": [
//         {"division": "all", "level": "1", "name": "السلوك التنظيمي"},
//         {"division": "all", "level": "2", "name": "إدارة الإنتاج والعمليات"},
//       ]
//     },
//     {
//       "id": "doc006",
//       "name": "آية محمد الكيلاني",
//       "subjects": [
//         {"division": "all", "level": "2", "name": "نظم المعلومات الإدارية"},
//         {"division": "محاسبه", "level": "4", "name": "مراجعة النظم الإلكترونية"},
//       ]
//     },
//     {
//       "id": "doc007",
//       "name": "السيد السعيد العراقي",
//       "subjects": [
//         {"division": "all", "level": "2", "name": "محاسبة إدارية"},
//         {"division": "محاسبه", "level": "4", "name": "محاسبة المنشآت المتخصصة"},
//       ]
//     },
//     {
//       "id": "doc008",
//       "name": "زينب المتولي الدمناوي",
//       "subjects": [
//         {"division": "all", "level": "2", "name": "لغة أجنبية"},
//         {"division": "نظم معلومات الاعمال", "level": "4", "name": "إدارة الموارد البشرية"},
//         {"division": "محاسبه", "level": "4", "name": "إدارة الموارد البشرية"},
//       ]
//     },
//     {
//       "id": "doc009",
//       "name": "فراج مخيمر محمد",
//       "subjects": [
//         {"division": "all", "level": "2", "name": "الإدارة المالية"},
//         {"division": "نظم معلومات الاعمال", "level": "3", "name": "إدارة المؤسسات"},
//         {"division": "محاسبه", "level": "3", "name": "إدارة المؤسسات"},
//       ]
//     },
//     {
//       "id": "doc010",
//       "name": "أحمد جمال غزالي",
//       "subjects": [
//         {"division": "all", "level": "2", "name": "تحليلات الأعمال"},
//         {"division": "نظم معلومات الاعمال", "level": "3", "name": "الإدارة الاستراتيجية"},
//         {"division": "محاسبه", "level": "3", "name": "الإدارة الاستراتيجية"},
//       ]
//     },
//     {
//       "id": "doc011",
//       "name": "فتحي السيد طه",
//       "subjects": [
//         {"division": "نظم معلومات الاعمال", "level": "3", "name": "إدارة الجودة الشاملة"},
//         {"division": "محاسبه", "level": "3", "name": "إدارة الجودة الشاملة"},
//       ]
//     },
//     {
//       "id": "doc012",
//       "name": "محمد قاسم خليل",
//       "subjects": [
//         {"division": "نظم معلومات الاعمال", "level": "3", "name": "تحليل وتصميم"},
//         {"division": "نظم معلومات الاعمال", "level": "4", "name": "الأعمال الإلكترونية"},
//         {"division": "محاسبه", "level": "4", "name": "الأعمال الإلكترونية"},
//       ]
//     },
//     {
//       "id": "doc013",
//       "name": "أسماء محمد عبد الحميد",
//       "subjects": [
//         {"division": "نظم معلومات الاعمال", "level": "3", "name": "البنية التحتية لتكنولوجيا المعلومات"},
//       ]
//     },
//     {
//       "id": "doc014",
//       "name": "ياسمين محمد الشافعي",
//       "subjects": [
//         {"division": "محاسبه", "level": "3", "name": "نظم معلومات محاسبية"},
//       ]
//     },
//     {
//       "id": "doc015",
//       "name": "هالة محمد عامر",
//       "subjects": [
//         {"division": "محاسبه", "level": "3", "name": "محاسبة متوسطة"},
//       ]
//     },
//     {
//       "id": "doc016",
//       "name": "أحمد عبد البديع عبد الله",
//       "subjects": [
//         {"division": "نظم معلومات الاعمال", "level": "4", "name": "تطبيقات في برمجة الحاسب"},
//         {"division": "نظم معلومات الاعمال", "level": "4", "name": "إدارة مخاطر أمن تكنولوجيا المعلومات"},
//       ]
//     },
//   ];
//
//   WriteBatch batch = firestore.batch();
//
//   for (var doctor in doctors) {
//     DocumentReference docRef = firestore.collection("doctors").doc(doctor["id"]);
//     batch.set(docRef, {
//       "id": doctor["id"],
//       "name": doctor["name"],
//       "password": hashedPassword,
//       "subjects": doctor["subjects"],
//     });
//   }
//
//   await batch.commit();
//   print("✅ تم رفع كافة الدكاترة (16 دكتور) بنجاح");
// }
