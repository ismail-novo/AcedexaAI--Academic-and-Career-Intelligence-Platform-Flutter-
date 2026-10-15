import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createStudent(StudentModel student) async {
    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(student.uid)
        .set(student.toMap());
  }

  Future<StudentModel?> getStudent(String uid) async {
    final document = await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(uid)
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return StudentModel.fromMap(document.data()!, document.id);
  }

  Future<void> updateStudent(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(uid)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteStudent(String uid) async {
    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(uid)
        .delete();
  }
}
