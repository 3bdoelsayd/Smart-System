// import 'package:cloud_firestore/cloud_firestore.dart';
//
// Future<void> uploadCurriculum() async {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   WriteBatch batch = firestore.batch();
//
//   final List<Map<String, dynamic>> subjects = [
//     // 🔹 الفرقة الأولى (مشتركة)
//     {"name": "حقوق الإنسان", "level": "1", "division": "all"},
//     {"name": "مبادئ العلوم السياسية", "level": "1", "division": "all"},
//     {"name": "طرق ومهارات الاتصال", "level": "1", "division": "all"},
//     {"name": "التفكير الابتكاري", "level": "1", "division": "all"},
//     {"name": "ريادة الأعمال", "level": "1", "division": "all"},
//     {"name": "السلوك التنظيمي", "level": "1", "division": "all"},
//
//     // 🔹 الفرقة الثانية (مشتركة)
//     {"name": "نظم المعلومات الإدارية", "level": "2", "division": "all"},
//     {"name": "محاسبة إدارية", "level": "2", "division": "all"},
//     {"name": "لغة أجنبية", "level": "2", "division": "all"},
//     {"name": "الإدارة المالية", "level": "2", "division": "all"},
//     {"name": "إدارة الإنتاج والعمليات", "level": "2", "division": "all"},
//     {"name": "تحليلات الأعمال", "level": "2", "division": "all"},
//
//     // 🔹 الفرقة الثالثة - نظم معلومات الاعمال
//     {"name": "إدارة الجودة الشاملة", "level": "3", "division": "نظم معلومات الاعمال"},
//     {"name": "تحليل وتصميم", "level": "3", "division": "نظم معلومات الاعمال"},
//     {"name": "الإدارة الاستراتيجية", "level": "3", "division": "نظم معلومات الاعمال"},
//     {"name": "إدارة المؤسسات", "level": "3", "division": "نظم معلومات الاعمال"},
//     {"name": "البنية التحتية لتكنولوجيا المعلومات", "level": "3", "division": "نظم معلومات الاعمال"},
//     {"name": "ريادة الأعمال", "level": "3", "division": "نظم معلومات الاعمال"},
//
//     // 🔹 الفرقة الثالثة - محاسبه
//     {"name": "نظم معلومات محاسبية", "level": "3", "division": "محاسبه"},
//     {"name": "إدارة الجودة الشاملة", "level": "3", "division": "محاسبه"},
//     {"name": "الإدارة الاستراتيجية", "level": "3", "division": "محاسبه"},
//     {"name": "إدارة المؤسسات", "level": "3", "division": "محاسبه"},
//     {"name": "محاسبة متوسطة", "level": "3", "division": "محاسبه"},
//     {"name": "ريادة الأعمال", "level": "3", "division": "محاسبه"},
//
//     // 🔹 الفرقة الرابعة - نظم معلومات الاعمال
//     {"name": "الأعمال الإلكترونية", "level": "4", "division": "نظم معلومات الاعمال"},
//     {"name": "إدارة الموارد البشرية", "level": "4", "division": "نظم معلومات الاعمال"},
//     {"name": "دراسة جدوى المشروعات", "level": "4", "division": "نظم معلومات الاعمال"},
//     {"name": "الإحصاء التطبيقي", "level": "4", "division": "نظم معلومات الاعمال"},
//     {"name": "تطبيقات في برمجة الحاسب", "level": "4", "division": "نظم معلومات الاعمال"},
//     {"name": "إدارة مخاطر أمن تكنولوجيا المعلومات", "level": "4", "division": "نظم معلومات الاعمال"},
//
//     // 🔹 الفرقة الرابعة - محاسبه
//     {"name": "الأعمال الإلكترونية", "level": "4", "division": "محاسبه"},
//     {"name": "مراجعة النظم الإلكترونية", "level": "4", "division": "محاسبه"},
//     {"name": "محاسبة المنشآت المتخصصة", "level": "4", "division": "محاسبه"},
//     {"name": "إدارة الموارد البشرية", "level": "4", "division": "محاسبه"},
//     {"name": "الإحصاء التطبيقي", "level": "4", "division": "محاسبه"},
//     {"name": "دراسة جدوى المشروعات", "level": "4", "division": "محاسبه"},
//   ];
//
//   for (var subject in subjects) {
//     // إنشاء ID فريد للمادة لضمان عدم التكرار
//     String subId = "${subject['name']}_${subject['level']}_${subject['division']}";
//     DocumentReference docRef = firestore.collection("curriculum").doc(subId);
//     batch.set(docRef, subject);
//   }
//
//   await batch.commit();
//   print("✅ تم رفع كافة المواد الدراسية بنجاح");
// }
