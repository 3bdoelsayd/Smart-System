import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// طبقة مركزية لمعالجة الأخطاء وتحويل الاستثناءات لرسائل عربية سهلة ومفهومة للمستخدم
class AppErrorHandler {
  /// تحويل أي Exception إلى رسالة واضحة للمستخدم وتسجيل التفاصيل في الـ Log
  static String handle(dynamic error, [StackTrace? stackTrace]) {
    // تسجيل الخطأ الحقيقي في الـ Debug log دون إظهاره للمستخدم
    debugPrint("🚨 [AppErrorHandler Log] Exception caught: $error");
    if (stackTrace != null) {
      debugPrint("📌 Stack trace: $stackTrace");
    }

    if (error == null) {
      return "حدث خطأ غير معروف. يرجى المحاولة لاحقاً.";
    }

    // إذا كان الخطأ عبارة عن نص عربي صريح تم رميه من التطبيق (مثل رسائل التنبيه)
    if (error is String) {
      if (error.startsWith("Exception: ")) {
        return error.replaceFirst("Exception: ", "").trim();
      }
      return error.trim();
    }

    // أخطاء Firebase Auth
    if (error is FirebaseAuthException) {
      return _mapFirebaseAuthError(error);
    }

    // أخطاء Firebase / Firestore العامة
    if (error is FirebaseException) {
      return _mapFirebaseError(error);
    }

    // أخطاء الشبكة والاتصال
    if (error is SocketException) {
      return "تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والإعادة.";
    }

    if (error is TimeoutException) {
      return "انتهت مهلة الاتصال بالشبكة. يرجى إعادة المحاولة.";
    }

    // فحص أسماء الأخطاء المعروفة نصياً إذا لم تكن نوع المباشر
    String errStr = error.toString().toLowerCase();

    if (errStr.contains('socketexception') || errStr.contains('network_error') || errStr.contains('failed host lookup')) {
      return "تعذر الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت.";
    }

    if (errStr.contains('timeout')) {
      return "انتهت مهلة الاتصال بالشبكة. يرجى إعادة المحاولة.";
    }

    if (errStr.contains('user-not-found')) {
      return "الحساب غير موجود. يرجى التأكد من الكود أو البريد الإلكتروني.";
    }

    if (errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
      return "كلمة المرور غير صحيحة.";
    }

    if (errStr.contains('too-many-requests')) {
      return "تم حظر المحاولات مؤقتاً لكثرة محاولات الدخول الخاطئة. يرجى الانتظار والمحاولة لاحقاً.";
    }

    if (errStr.contains('user-disabled')) {
      return "تم تعطيل هذا الحساب. يرجى مراجعة إدارة الكلية.";
    }

    // الخطأ الافتراضي الآمن
    return "حدث خطأ غير متوقع. يرجى المحاولة لاحقاً أو الاتصال بالدعم الفني.";
  }

  /// خريطة ترجمة أخطاء Firebase Auth
  static String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return "كلمة المرور غير صحيحة. يرجى التأكد وإعادة المحاولة.";
      case 'user-not-found':
        return "الحساب غير موجود. يرجى التأكد من الكود المكتوب.";
      case 'invalid-email':
        return "صيغة الكود أو البريد الإلكتروني غير صحيحة.";
      case 'user-disabled':
        return "تم تعطيل هذا الحساب. يرجى مراجعة شؤون الطلاب أو إدارة الكلية.";
      case 'too-many-requests':
        return "تم حظر محاولات الدخول مؤقتاً لكثرة المحاولات الخاطئة. يرجى المحاولة بعد عدة دقائق.";
      case 'operation-not-allowed':
        return "خدمة تسجيل الدخول غير متاحة حالياً.";
      case 'network-request-failed':
        return "فشل الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت.";
      case 'weak-password':
        return "كلمة المرور ضعيفة جداً. يرجى اختيار كلمة مرور أقوى.";
      case 'email-already-in-use':
        return "هذا الحساب أو البريد الإلكتروني مسجل بالفعل.";
      case 'requires-recent-login':
        return "يتطلب هذا الإجراء تسجيل الدخول مجدداً للأمان.";
      default:
        if (e.message != null && e.message!.isNotEmpty && _isArabicText(e.message!)) {
          return e.message!;
        }
        return "حدث خطأ أثناء تسجيل الدخول (${e.code}). يرجى المحاولة لاحقاً.";
    }
  }

  /// خريطة ترجمة أخطاء Firebase/Firestore العامة
  static String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "عذراً، ليس لديك الصلاحية المطلوبة لإتمام هذا الإجراء.";
      case 'unavailable':
        return "الخدمة غير متاحة حالياً. يرجى المحاولة في وقت لاحق.";
      case 'deadline-exceeded':
      case 'canceled':
        return "انتهت مهلة الطلب قبل اكتماله. يرجى المحاولة مجدداً.";
      case 'not-found':
        return "البيانات المطلوبة غير موجودة على السيرفر.";
      case 'already-exists':
        return "البيانات المراد إضافتها موجودة مسبقاً.";
      case 'resource-exhausted':
        return "تم تجاوز حد الاستخدام المسموح. يرجى المحاولة لاحقاً.";
      default:
        return "حدث خطأ في قاعدة البيانات (${e.code}). يرجى المحاولة لاحقاً.";
    }
  }

  static bool _isArabicText(String text) {
    final RegExp arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }
}
