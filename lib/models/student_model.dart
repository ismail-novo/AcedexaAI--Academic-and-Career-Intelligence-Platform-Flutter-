import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String uid;
  final String name;
  final String email;
  final String studentId;
  final String university;
  final String faculty;
  final String department;
  final String program;
  final String semester;
  final String year;
  final String batch;
  final String graduationYear;
  final double cgpa;
  final String careerGoal;
  final List<String> targetRoles;
  final List<String> interests;
  final String profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.studentId,
    required this.university,
    required this.faculty,
    required this.department,
    required this.program,
    required this.semester,
    required this.year,
    required this.batch,
    required this.graduationYear,
    required this.cgpa,
    required this.careerGoal,
    required this.targetRoles,
    required this.interests,
    this.profileImageUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'studentId': studentId,
      'university': university,
      'faculty': faculty,
      'department': department,
      'program': program,
      'semester': semester,
      'year': year,
      'batch': batch,
      'graduationYear': graduationYear,
      'cgpa': cgpa,
      'careerGoal': careerGoal,
      'targetRoles': targetRoles,
      'interests': interests,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentId: map['studentId'] ?? '',
      university: map['university'] ?? '',
      faculty: map['faculty'] ?? '',
      department: map['department'] ?? '',
      program: map['program'] ?? '',
      semester: map['semester'] ?? '',
      year: map['year'] ?? '',
      batch: map['batch'] ?? '',
      graduationYear: map['graduationYear'] ?? '',
      cgpa: (map['cgpa'] ?? 0).toDouble(),
      careerGoal: map['careerGoal'] ?? '',
      targetRoles: List<String>.from(map['targetRoles'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      profileImageUrl: map['profileImageUrl'] ?? '',
      createdAt: _timestampToDate(map['createdAt']),
      updatedAt: _timestampToDate(map['updatedAt']),
    );
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
