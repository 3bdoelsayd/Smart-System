import 'package:flutter_test/flutter_test.dart';

// Role-aware document validation function mirroring DataService
bool isValidUserDocument(Map<String, dynamic>? data, String role, String collectionName) {
  if (data == null) return false;
  String name = (data['name'] ?? '').toString().trim();
  if (name.isEmpty) return false;

  String r = role.toLowerCase();
  String col = collectionName.toLowerCase();

  if (col == 'students' && r != 'student') return false;
  if (col == 'doctors' && r != 'doctor') return false;
  if (col == 'tas' && r != 'ta') return false;
  if (col == 'managers' && r != 'manager') return false;
  if (col == 'super_admins' && !r.contains('admin')) return false;

  String getFirstNonEmpty(List<dynamic> values) {
    for (var v in values) {
      if (v != null) {
        String s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return '';
  }

  if (r == 'student') {
    String code = getFirstNonEmpty([data['code'], data['id']]);
    return code.isNotEmpty;
  } else if (r == 'doctor' || r == 'ta') {
    String id = getFirstNonEmpty([data['id'], data['email'], data['uid']]);
    return id.isNotEmpty;
  } else if (r == 'manager') {
    String id = getFirstNonEmpty([data['email'], data['uid'], data['id']]);
    return id.isNotEmpty;
  } else if (r.contains('admin')) {
    String email = getFirstNonEmpty([data['email'], data['uid'], data['id']]);
    return email.isNotEmpty;
  }
  return false;
}

void main() {
  group('Role-Aware Document Validation Unit Tests', () {
    test('1. Student role validation - success vs empty/missing code', () {
      var validStudent = {'name': 'أحمد محمد', 'code': '230001', 'level': '1'};
      var invalidStudentMissingCode = {'name': 'أحمد محمد', 'level': '1'};
      var emptyStudent = <String, dynamic>{};

      expect(isValidUserDocument(validStudent, 'student', 'students'), true);
      expect(isValidUserDocument(invalidStudentMissingCode, 'student', 'students'), false);
      expect(isValidUserDocument(emptyStudent, 'student', 'students'), false);
    });

    test('2. Doctor / TA role validation - success without code field (DOC_101 format)', () {
      var validDoctor = {'name': 'د. محمود', 'id': 'DOC_101', 'email': '101.college@smart.com', 'role': 'doctor'};
      var validTa = {'name': 'معيد أحمد', 'uid': 'ta_uid_123', 'role': 'ta'};

      expect(isValidUserDocument(validDoctor, 'doctor', 'doctors'), true);
      expect(isValidUserDocument(validTa, 'ta', 'tas'), true);
    });

    test('3. Manager role validation - success with random UID and no code field', () {
      var validManager = {'name': 'مدير فرقة', 'uid': 'random_firebase_uid_4eae', 'role': 'manager'};
      var invalidManagerMissingIdAndEmail = {'name': 'مدير', 'role': 'manager'};

      expect(isValidUserDocument(validManager, 'manager', 'managers'), true);
      expect(isValidUserDocument(invalidManagerMissingIdAndEmail, 'manager', 'managers'), false);
    });

    test('4. Admin / Super Admin role validation - success', () {
      var validSuperAdmin = {'name': 'سوبر أدمن', 'email': 'admin@smart.com', 'role': 'super_admin'};
      expect(isValidUserDocument(validSuperAdmin, 'super_admin', 'super_admins'), true);
    });

    test('5. Role mismatch rejection (e.g. student doc with super_admin role)', () {
      var fakeStudent = {'name': 'طالب مخترق', 'code': '999', 'role': 'super_admin'};
      expect(isValidUserDocument(fakeStudent, 'super_admin', 'students'), false);
    });
  });
}
