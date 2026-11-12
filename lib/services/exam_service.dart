import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_model.dart';
import 'data_service.dart';

class ExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataService _ds = DataService();

  String get _collegeId => _ds.selectedInstituteId ?? 'commerce';

  CollectionReference get _examsColl => _firestore
      .collection('colleges')
      .doc(_collegeId)
      .collection('exams');

  // Fetch estimated server time by reading local time adjusted by offset
  Future<DateTime> getServerTime() async {
    try {
      final docRef = _firestore.collection('tmp').doc('server_time_check');
      await docRef.set({'time': FieldValue.serverTimestamp()});
      final snap = await docRef.get();
      final Timestamp? serverTs = snap.data()?['time'] as Timestamp?;
      if (serverTs != null) {
        return serverTs.toDate();
      }
    } catch (e) {
      debugPrint("Error fetching server time: $e");
    }
    return DateTime.now();
  }

  // Save or update exam metadata
  Future<String> createOrUpdateExam(ExamModel exam) async {
    final docRef = exam.id.isEmpty ? _examsColl.doc() : _examsColl.doc(exam.id);
    final examId = docRef.id;

    final examData = exam.toMap();
    examData['id'] = examId;

    await docRef.set(examData, SetOptions(merge: true));

    if (exam.isPublished) {
      await notifyExamPublished(exam.copyWith(id: examId));
    }

    return examId;
  }

  // Delete an exam and its questions & submissions
  Future<void> deleteExam(String examId) async {
    final examRef = _examsColl.doc(examId);

    // Delete questions
    final qSnap = await examRef.collection('questions').get();
    for (var doc in qSnap.docs) {
      await doc.reference.delete();
    }

    // Delete submissions
    final sSnap = await examRef.collection('submissions').get();
    for (var doc in sSnap.docs) {
      await doc.reference.delete();
    }

    await examRef.delete();
  }

  // Save/Replace all questions for an exam and update total score
  Future<void> saveExamQuestions(String examId, List<QuestionModel> questions) async {
    final examRef = _examsColl.doc(examId);
    final qColl = examRef.collection('questions');

    // Fetch existing questions to clean up removed ones
    final existingSnap = await qColl.get();
    final newIds = questions.map((q) => q.id).toSet();

    for (var doc in existingSnap.docs) {
      if (!newIds.contains(doc.id)) {
        await doc.reference.delete();
      }
    }

    double totalScore = 0.0;
    final batch = _firestore.batch();

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final docRef = q.id.isEmpty ? qColl.doc() : qColl.doc(q.id);
      totalScore += q.points;

      final data = q.toMap();
      data['id'] = docRef.id;
      data['examId'] = examId;
      data['order'] = i;

      batch.set(docRef, data, SetOptions(merge: true));
    }

    // Update total score in main exam document
    batch.update(examRef, {'totalScore': totalScore});

    await batch.commit();
  }

  // Stream of exams for Doctor / TA
  Stream<List<ExamModel>> getExamsStreamForDoctor(String doctorUid) {
    return _examsColl
        .where('createdByUid', isEqualTo: doctorUid)
        .snapshots()
        .map((snap) {
      final exams = snap.docs.map((doc) => ExamModel.fromFirestore(doc)).toList();
      exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return exams;
    });
  }

  // Stream of published exams for Students filtered by level & division
  Stream<List<ExamModel>> getExamsStreamForStudent(String level, String section) {
    final cleanLevel = _ds.normalizeLevel(level);
    final studentSec = _ds.normalizeDivision(section);

    return _examsColl
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .asyncMap((snap) async {
      final List<ExamModel> filteredExams = [];

      for (var doc in snap.docs) {
        final exam = ExamModel.fromFirestore(doc);
        final examLvl = _ds.normalizeLevel(exam.targetLevel);
        if (examLvl != cleanLevel) continue;

        String effectiveSection = exam.targetSection;
        if ((effectiveSection == 'all' || effectiveSection.isEmpty) && exam.courseId.isNotEmpty) {
          try {
            final courseDoc = await _firestore
                .collection('colleges')
                .doc(_collegeId)
                .collection('levels')
                .doc('level_$cleanLevel')
                .collection('courses')
                .doc(exam.courseId)
                .get();
            if (courseDoc.exists) {
              final courseDiv = courseDoc.data()?['division']?.toString();
              if (courseDiv != null && courseDiv.isNotEmpty) {
                effectiveSection = courseDiv;
              }
            }
          } catch (_) {}
        }

        if (effectiveSection != 'all' && effectiveSection.isNotEmpty) {
          final examSec = _ds.normalizeDivision(effectiveSection);
          if (examSec != 'all' && examSec != studentSec) {
            continue;
          }
        }

        filteredExams.add(exam);
      }

      filteredExams.sort((a, b) => b.startTime.compareTo(a.startTime));
      return filteredExams;
    });
  }

  // Stream of exams for Class Manager
  Stream<List<ExamModel>> getExamsStreamForManager(List<String> managedLevels) {
    final cleanLevels = managedLevels.map((l) => _ds.normalizeLevel(l)).toSet();

    return _examsColl.snapshots().map((snap) {
      final exams = snap.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .where((exam) {
        if (!exam.isPublished) return false;
        if (cleanLevels.isEmpty) return true;
        return cleanLevels.contains(_ds.normalizeLevel(exam.targetLevel));
      }).toList();

      exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return exams;
    });
  }

  // Fetch all questions for an exam
  Future<List<QuestionModel>> getExamQuestions(String examId) async {
    final snap = await _examsColl
        .doc(examId)
        .collection('questions')
        .orderBy('order')
        .get();

    return snap.docs
        .map((doc) => QuestionModel.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  // Stream of questions
  Stream<List<QuestionModel>> getExamQuestionsStream(String examId) {
    return _examsColl
        .doc(examId)
        .collection('questions')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => QuestionModel.fromMap(doc.data(), docId: doc.id))
            .toList());
  }

  // Check if student has already submitted
  Future<ExamSubmissionModel?> getStudentSubmission(String examId, String studentUid, {String? studentId}) async {
    final coll = _examsColl.doc(examId).collection('submissions');

    if (studentUid.isNotEmpty) {
      final q1 = await coll.where('studentUid', isEqualTo: studentUid).get();
      if (q1.docs.isNotEmpty) return ExamSubmissionModel.fromFirestore(q1.docs.first);

      final q1b = await coll.where('id', isEqualTo: studentUid).get();
      if (q1b.docs.isNotEmpty) return ExamSubmissionModel.fromFirestore(q1b.docs.first);
    }

    if (studentId != null && studentId.isNotEmpty) {
      final q2 = await coll.where('studentId', isEqualTo: studentId).get();
      if (q2.docs.isNotEmpty) return ExamSubmissionModel.fromFirestore(q2.docs.first);

      final q2b = await coll.where('studentUid', isEqualTo: studentId).get();
      if (q2b.docs.isNotEmpty) return ExamSubmissionModel.fromFirestore(q2b.docs.first);
    }

    if (studentId != null && studentId.isNotEmpty) {
      final docId = await coll.doc(studentId).get();
      if (docId.exists) return ExamSubmissionModel.fromFirestore(docId);
    }

    if (studentUid.isNotEmpty) {
      final doc = await coll.doc(studentUid).get();
      if (doc.exists) return ExamSubmissionModel.fromFirestore(doc);
    }

    return null;
  }

  // Stream student submission
  Stream<ExamSubmissionModel?> getStudentSubmissionStream(String examId, String studentUid, {String? studentId}) {
    return _examsColl
        .doc(examId)
        .collection('submissions')
        .doc(studentUid.isNotEmpty ? studentUid : (studentId ?? ''))
        .snapshots()
        .map((doc) => doc.exists ? ExamSubmissionModel.fromFirestore(doc) : null);
  }

  // Submit student exam & calculate auto score
  Future<ExamSubmissionModel> submitStudentExam({
    required String examId,
    required String studentUid,
    required String studentName,
    required String studentId,
    required String level,
    required String section,
    required Map<String, dynamic> answers,
    required List<QuestionModel> questions,
    required double maxScore,
  }) async {
    final serverNow = await getServerTime();

    double autoScore = 0.0;
    bool hasEssayQuestions = false;

    for (var q in questions) {
      final studentAnswer = answers[q.id];
      if (q.type == QuestionType.essay) {
        hasEssayQuestions = true;
      } else if (q.type == QuestionType.mcq) {
        if (studentAnswer != null && studentAnswer.toString() == q.correctAnswer?.toString()) {
          autoScore += q.points;
        }
      } else if (q.type == QuestionType.trueFalse) {
        if (studentAnswer != null && studentAnswer.toString().toLowerCase() == q.correctAnswer?.toString().toLowerCase()) {
          autoScore += q.points;
        }
      }
    }

    final isGraded = !hasEssayQuestions;
    final finalScore = autoScore;

    final submission = ExamSubmissionModel(
      id: studentUid,
      examId: examId,
      studentUid: studentUid,
      studentName: studentName,
      studentId: studentId,
      level: level,
      section: section,
      startTime: serverNow,
      submittedAt: serverNow,
      isSubmitted: true,
      autoScore: autoScore,
      finalScore: finalScore,
      maxScore: maxScore,
      isGraded: isGraded,
      answers: answers,
      essayGrades: {},
      status: isGraded ? 'graded' : 'submitted',
    );

    final docId1 = studentUid.isNotEmpty ? studentUid : studentId;
    final subColl = _examsColl.doc(examId).collection('submissions');

    if (docId1.isNotEmpty) {
      await subColl.doc(docId1).set(submission.toMap(), SetOptions(merge: true));
    }
    if (studentId.isNotEmpty && studentId != docId1) {
      await subColl.doc(studentId).set(submission.toMap(), SetOptions(merge: true));
    }

    return submission;
  }

  // Stream of all submissions for an exam
  Stream<List<ExamSubmissionModel>> getSubmissionsStream(String examId) {
    return _examsColl
        .doc(examId)
        .collection('submissions')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ExamSubmissionModel.fromFirestore(doc))
            .toList());
  }

  // Doctor/TA manually grades essay questions
  Future<void> gradeEssaySubmission({
    required String examId,
    required String studentUid,
    required Map<String, Map<String, dynamic>> essayGrades,
    required double autoScore,
    required double maxScore,
    required String examTitle,
  }) async {
    double essayTotalScore = 0.0;
    essayGrades.forEach((qId, gradeData) {
      final pts = (gradeData['points'] ?? 0.0).toDouble();
      essayTotalScore += pts;
    });

    final finalScore = autoScore + essayTotalScore;

    await _examsColl
        .doc(examId)
        .collection('submissions')
        .doc(studentUid)
        .update({
      'essayGrades': essayGrades,
      'finalScore': finalScore,
      'isGraded': true,
      'status': 'graded',
    });

    // Notify student
    await notifyExamGraded(studentUid, examTitle, finalScore, maxScore);
  }

  // Get absent students for an exam
  Future<List<Map<String, dynamic>>> getAbsentStudents({
    required String examId,
    required String level,
    required String section,
  }) async {
    String effectiveSection = section;
    try {
      final examDoc = await _examsColl.doc(examId).get();
      if (examDoc.exists) {
        final exam = ExamModel.fromFirestore(examDoc);
        String targetSec = exam.targetSection;
        if ((targetSec == 'all' || targetSec.isEmpty) && exam.courseId.isNotEmpty) {
          final courseDoc = await _firestore
              .collection('colleges')
              .doc(_collegeId)
              .collection('levels')
              .doc('level_${_ds.normalizeLevel(exam.targetLevel)}')
              .collection('courses')
              .doc(exam.courseId)
              .get();
          if (courseDoc.exists) {
            final courseDiv = courseDoc.data()?['division']?.toString();
            if (courseDiv != null && courseDiv.isNotEmpty) {
              targetSec = courseDiv;
            }
          }
        }
        effectiveSection = targetSec;
      }
    } catch (_) {}

    final cleanLvl = _ds.normalizeLevel(level);
    final studentsSnap = await _ds.getCommerceStudentsColl('level_$cleanLvl').get();

    final submissionsSnap = await _examsColl
        .doc(examId)
        .collection('submissions')
        .get();

    final submittedStudentUids = submissionsSnap.docs.map((d) => d.id).toSet();

    final List<Map<String, dynamic>> absentStudents = [];

    for (var doc in studentsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final uid = data['uid'] ?? data['id'] ?? doc.id;
      final studentDiv = _ds.normalizeDivision(data['division']?.toString() ?? 'all');
      final targetDiv = _ds.normalizeDivision(effectiveSection);

      if (targetDiv != 'all' && studentDiv != 'all' && studentDiv != targetDiv) {
        continue;
      }

      if (!submittedStudentUids.contains(uid)) {
        absentStudents.add({
          'uid': uid,
          'id': data['id']?.toString() ?? '',
          'name': data['name']?.toString() ?? 'طالب',
          'division': data['division']?.toString() ?? '',
        });
      }
    }

    return absentStudents;
  }

  // Push notifications
  Future<void> notifyExamPublished(ExamModel exam) async {
    try {
      await _firestore.collection('notifications').add({
        'title': _ds.isArabic ? 'اختبار جديد: ${exam.title}' : 'New Exam: ${exam.title}',
        'body': _ds.isArabic
            ? 'تم إتاحة اختبار في مادة ${exam.subject}. موعد البدء: ${_formatDate(exam.startTime)}'
            : 'New exam added for ${exam.subject}. Starts at: ${_formatDate(exam.startTime)}',
        'targetType': 'student',
        'timestamp': FieldValue.serverTimestamp(),
        'instituteId': _collegeId,
        'isRead': false,
      });
    } catch (e) {
      debugPrint("Notify exam error: $e");
    }
  }

  Future<void> notifyExamGraded(
      String studentUid, String examTitle, double finalScore, double maxScore) async {
    try {
      await _firestore.collection('notifications').add({
        'title': _ds.isArabic ? 'نتيجة الاختبار جاهزة' : 'Exam Result Ready',
        'body': _ds.isArabic
            ? 'تم تقييم إجاباتك في اختبار "$examTitle". الدرجة النهائية: $finalScore / $maxScore'
            : 'Your answers for "$examTitle" have been graded. Final Score: $finalScore / $maxScore',
        'targetType': 'student',
        'targetUserId': studentUid,
        'timestamp': FieldValue.serverTimestamp(),
        'instituteId': _collegeId,
        'isRead': false,
      });
    } catch (e) {
      debugPrint("Notify graded error: $e");
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}

extension ExamModelCopy on ExamModel {
  ExamModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? courseId,
    String? targetLevel,
    String? targetSection,
    String? description,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    bool? isPublished,
    double? totalScore,
    String? createdByUid,
    String? createdByName,
    String? createdByRole,
    DateTime? createdAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      courseId: courseId ?? this.courseId,
      targetLevel: targetLevel ?? this.targetLevel,
      targetSection: targetSection ?? this.targetSection,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isPublished: isPublished ?? this.isPublished,
      totalScore: totalScore ?? this.totalScore,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
