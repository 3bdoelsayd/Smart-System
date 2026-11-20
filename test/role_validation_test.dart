import 'package:flutter_test/flutter_test.dart';

// Helper simulating role-aware document validation
bool isValidUserDocument(Map<String, dynamic>? data, String role) {
  if (data == null) return false;
  String name = (data['name'] ?? '').toString().trim();
  if (name.isEmpty) return false;

  String r = role.toLowerCase();
  if (r == 'student') {
    String code = (data['code'] ?? data['id'] ?? data['uid'] ?? '').toString().trim();
    return code.isNotEmpty;
  } else if (r == 'doctor' || r == 'ta') {
    String id = (data['id'] ?? data['email'] ?? '').toString().trim();
    return id.isNotEmpty;
  } else if (r == 'manager') {
    String id = (data['id'] ?? data['name'] ?? '').toString().trim();
    return id.isNotEmpty;
  } else if (r.contains('admin')) {
    String email = (data['email'] ?? data['id'] ?? data['name'] ?? '').toString().trim();
    return email.isNotEmpty;
  }
  return true;
}

void main() {
  group('Role-Aware Document Validation Unit Tests', () {
    test('1. Student role validation - success vs empty/missing code', () {
      var validStudent = {'name': 'أحمد محمد', 'code': '230001', 'level': '1'};
      var invalidStudentMissingCode = {'name': 'أحمد محمد', 'level': '1'};
      var emptyStudent = <String, dynamic>{};

      expect(isValidUserDocument(validStudent, 'student'), true);
      expect(isValidUserDocument(invalidStudentMissingCode, 'student'), false);
      expect(isValidUserDocument(emptyStudent, 'student'), false);
    });

    test('2. Doctor / TA role validation - success vs missing id/email', () {
      var validDoctor = {'name': 'د. محمود', 'id': '101', 'email': '101.college@smart.com'};
      var invalidDoctorMissingId = {'name': 'د. محمود'};

      expect(isValidUserDocument(validDoctor, 'doctor'), true);
      expect(isValidUserDocument(validDoctor, 'ta'), true);
      expect(isValidUserDocument(invalidDoctorMissingId, 'doctor'), false);
    });

    test('3. Manager role validation - success vs empty name', () {
      var validManager = {'name': 'مدير النظام', 'id': 'm1'};
      var invalidManagerEmptyName = {'name': '', 'id': 'm1'};

      expect(isValidUserDocument(validManager, 'manager'), true);
      expect(isValidUserDocument(invalidManagerEmptyName, 'manager'), false);
    });

    test('4. Admin / Super Admin role validation - success without code field', () {
      var validSuperAdmin = {'name': 'سوبر أدمن', 'email': 'admin@smart.com', 'role': 'super_admin'};
      var invalidSuperAdminEmpty = {'name': ''};

      expect(isValidUserDocument(validSuperAdmin, 'super_admin'), true);
      expect(isValidUserDocument(validSuperAdmin, 'super_admin_plus'), true);
      expect(isValidUserDocument(invalidSuperAdminEmpty, 'super_admin'), false);
    });
  });
}
