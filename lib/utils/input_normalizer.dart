/// وحدة تنظيف وتوحيد المدخلات (الكود وكلمة المرور)
class InputNormalizer {
  /// تحويل الأرقام العربية والشرقية (٠١٢٣٤٥٦٧٨٩ / ۰۱۲۳۴۵۶۷۸۹) إلى أرقام إنجليزية أصلية (0123456789)
  static String normalizeArabicDigits(String input) {
    if (input.isEmpty) return input;
    const String easternArabic = '٠١٢٣٤٥٦٧٨٩';
    const String persian = '۰۱۲۳۴۵۶۷۸۹';
    const String western = '0123456789';

    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(easternArabic[i], western[i]);
      result = result.replaceAll(persian[i], western[i]);
    }
    return result;
  }

  /// تنظيف وتوحيد كود المستخدم (طالب / دكتور / أدمن)
  /// يحول الأرقام العربية لإنجليزي، يزيل المسافات، يزيل البادئات والسوابق
  static String cleanUserCode(String rawInput) {
    if (rawInput.trim().isEmpty) return '';

    // 1. إزالة المسافات الزائدة
    String trimmed = rawInput.trim();

    // 2. تحويل الأرقام العربية إلى إنجليزية
    String normalizedDigits = normalizeArabicDigits(trimmed);

    // 3. تحويل للأحرف الصغيرة
    String lower = normalizedDigits.toLowerCase();

    // 4. تنظيف الإيميل أو البادئات إذا تم لصق إيميل كامل أو كود ببادئة
    String cleanCode = lower
        .replaceAll('std_', '')
        .replaceAll('doc_', '')
        .replaceAll('ta_', '')
        .replaceAll('.college@smart.com', '')
        .replaceAll('@smart.edu.eg', '')
        .replaceAll('@smart.edu', '')
        .replaceAll('@smart.com', '')
        .trim();

    return cleanCode;
  }

  /// نسخة منظفة من كلمة المرور لتجربتها كـ Retry fallback فقط في حالة فشل الأولى
  /// تنظيف المسافات من الأطراف + تحويل الأرقام العربية لإنجليزي فقط دون حذف أي حروف أو رموز خاصة
  static String cleanPasswordVariant(String rawPassword) {
    if (rawPassword.isEmpty) return rawPassword;
    // تنظيف المسافات من الحواف وتحويل الأرقام العربية فقط
    String trimmed = rawPassword.trim();
    return normalizeArabicDigits(trimmed);
  }
}
