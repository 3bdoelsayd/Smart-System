import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'data_service.dart';

/// Unified API Service wrapper for Smart University System backend interactions.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final DataService _ds = DataService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Authenticate user (Student, Doctor, Manager, or Super Admin)
  Future<String?> login(String loginInput, String password) async {
    return await _ds.unifiedLogin(loginInput, password);
  }

  /// Fetch all students for an institute
  Future<List<Map<String, dynamic>>> getStudents() async {
    var snap = await _ds.studentsColl.get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  /// Fetch all doctors for an institute
  Future<List<Map<String, dynamic>>> getDoctors() async {
    var snap = await _ds.commerceDoctorsColl.get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  /// Record student attendance
  Future<void> recordAttendance({
    required String subject,
    required String level,
    required int lectureNumber,
    required String division,
    String? location,
    String sessionType = 'lecture',
  }) async {
    await _ds.recordAttendanceCloud(
      subject: subject,
      level: level,
      lectureNumber: lectureNumber,
      division: division,
      studentLocation: location,
      sessionType: sessionType,
    );
  }

  /// Update user profile (Student or Doctor)
  Future<void> updateProfile({
    required bool isStudent,
    String? phone,
    String? personalEmail,
    String? photoUrl,
    Map<String, dynamic>? preferences,
  }) async {
    if (isStudent) {
      await _ds.updateStudentProfile(
        phone: phone,
        personalEmail: personalEmail,
        photoUrl: photoUrl,
      );
    } else {
      await _ds.updateDoctorProfile(
        phone: phone,
        personalEmail: personalEmail,
        photoUrl: photoUrl,
        preferences: preferences,
      );
    }
  }

  /// Sign out current user
  Future<void> logout() async {
    await _auth.signOut();
  }
}
