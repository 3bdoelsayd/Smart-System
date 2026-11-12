import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType { mcq, trueFalse, essay }

class QuestionModel {
  final String id;
  final String examId;
  final String questionText;
  final QuestionType type;
  final List<String> options; // For MCQ
  final dynamic correctAnswer; // int for MCQ (option index), bool for True/False, null for Essay
  final double points;
  final int order;

  QuestionModel({
    required this.id,
    required this.examId,
    required this.questionText,
    required this.type,
    this.options = const [],
    this.correctAnswer,
    this.points = 1.0,
    this.order = 0,
  });

  Map<String, dynamic> toMap({bool includeCorrectAnswer = true}) {
    final map = <String, dynamic>{
      'id': id,
      'examId': examId,
      'questionText': questionText,
      'type': type.name,
      'options': options,
      'points': points,
      'order': order,
    };
    if (includeCorrectAnswer) {
      map['correctAnswer'] = correctAnswer;
    }
    return map;
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    QuestionType qType = QuestionType.mcq;
    final typeStr = (map['type'] ?? '').toString();
    if (typeStr == 'trueFalse' || typeStr == 'true_false') {
      qType = QuestionType.trueFalse;
    } else if (typeStr == 'essay') {
      qType = QuestionType.essay;
    }

    return QuestionModel(
      id: docId ?? (map['id'] ?? ''),
      examId: map['examId'] ?? '',
      questionText: map['questionText'] ?? '',
      type: qType,
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'],
      points: (map['points'] ?? 1.0).toDouble(),
      order: (map['order'] ?? 0).toInt(),
    );
  }
}

class ExamModel {
  final String id;
  final String title;
  final String subject;
  final String courseId;
  final String targetLevel; // e.g. "level_1" or "1"
  final String targetSection; // e.g. "all" or section ID
  final String description;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final bool isPublished;
  final double totalScore;
  final String createdByUid;
  final String createdByName;
  final String createdByRole; // 'doctor' or 'ta'
  final DateTime createdAt;

  ExamModel({
    required this.id,
    required this.title,
    required this.subject,
    this.courseId = '',
    required this.targetLevel,
    this.targetSection = 'all',
    this.description = '',
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    this.isPublished = false,
    this.totalScore = 0.0,
    required this.createdByUid,
    required this.createdByName,
    this.createdByRole = 'doctor',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOpen {
    final now = DateTime.now();
    return isPublished && now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return isPublished && now.isBefore(startTime);
  }

  bool get isClosed {
    final now = DateTime.now();
    return !isPublished || now.isAfter(endTime);
  }

  String get statusKey {
    if (!isPublished) return 'draft';
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 'upcoming';
    if (now.isAfter(endTime)) return 'closed';
    return 'open';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'courseId': courseId,
      'targetLevel': targetLevel,
      'targetSection': targetSection,
      'description': description,
      'durationMinutes': durationMinutes,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isPublished': isPublished,
      'totalScore': totalScore,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ExamModel(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      courseId: data['courseId'] ?? '',
      targetLevel: (data['targetLevel'] ?? '1').toString(),
      targetSection: (data['targetSection'] ?? 'all').toString(),
      description: data['description'] ?? '',
      durationMinutes: (data['durationMinutes'] ?? 30).toInt(),
      startTime: parseTime(data['startTime']),
      endTime: parseTime(data['endTime']),
      isPublished: data['isPublished'] ?? false,
      totalScore: (data['totalScore'] ?? 0.0).toDouble(),
      createdByUid: data['createdByUid'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdByRole: data['createdByRole'] ?? 'doctor',
      createdAt: parseTime(data['createdAt']),
    );
  }
}

class ExamSubmissionModel {
  final String id;
  final String examId;
  final String studentUid;
  final String studentName;
  final String studentId;
  final String level;
  final String section;
  final DateTime startTime;
  final DateTime? submittedAt;
  final bool isSubmitted;
  final double autoScore; // Score from MCQ & T/F
  final double finalScore; // Final score after essay grading
  final double maxScore;
  final bool isGraded; // True if essays have been manually graded or if no essays
  final Map<String, dynamic> answers; // qId -> selected option index (int), bool, or text (String)
  final Map<String, dynamic> essayGrades; // qId -> {'points': double, 'comment': String}
  final String status; // 'submitted', 'graded'

  ExamSubmissionModel({
    required this.id,
    required this.examId,
    required this.studentUid,
    required this.studentName,
    required this.studentId,
    required this.level,
    this.section = '',
    required this.startTime,
    this.submittedAt,
    this.isSubmitted = false,
    this.autoScore = 0.0,
    this.finalScore = 0.0,
    this.maxScore = 0.0,
    this.isGraded = false,
    this.answers = const {},
    this.essayGrades = const {},
    this.status = 'submitted',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'studentUid': studentUid,
      'studentName': studentName,
      'studentId': studentId,
      'level': level,
      'section': section,
      'startTime': Timestamp.fromDate(startTime),
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'isSubmitted': isSubmitted,
      'autoScore': autoScore,
      'finalScore': finalScore,
      'maxScore': maxScore,
      'isGraded': isGraded,
      'answers': answers,
      'essayGrades': essayGrades,
      'status': status,
    };
  }

  factory ExamSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ExamSubmissionModel(
      id: doc.id,
      examId: data['examId'] ?? '',
      studentUid: data['studentUid'] ?? '',
      studentName: data['studentName'] ?? '',
      studentId: data['studentId'] ?? '',
      level: (data['level'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      startTime: parseTime(data['startTime']),
      submittedAt: data['submittedAt'] != null ? parseTime(data['submittedAt']) : null,
      isSubmitted: data['isSubmitted'] ?? false,
      autoScore: (data['autoScore'] ?? 0.0).toDouble(),
      finalScore: (data['finalScore'] ?? 0.0).toDouble(),
      maxScore: (data['maxScore'] ?? 0.0).toDouble(),
      isGraded: data['isGraded'] ?? false,
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      essayGrades: Map<String, dynamic>.from(data['essayGrades'] ?? {}),
      status: data['status'] ?? 'submitted',
    );
  }
}
