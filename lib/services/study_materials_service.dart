import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_material_model.dart';

class StudyMaterialsService {
  static final StudyMaterialsService _i = StudyMaterialsService._();
  factory StudyMaterialsService() => _i;
  StudyMaterialsService._();

  List<StudyMaterial> materials = [];
  String _uid = 'guest';
  String get _key => 'study_materials_v2_$_uid';

  Future<void> setUser(String? uid) async {
    _uid = (uid == null || uid.isEmpty) ? 'guest' : uid;
    await load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      materials = [];
      return;
    }
    final list = jsonDecode(raw) as List;
    materials = list
        .map((e) => StudyMaterial.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(materials.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> add({required String title, required String content}) async {
    materials.insert(
      0,
      StudyMaterial(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.isEmpty ? 'Note' : title,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
    await _save();
  }

  Future<void> remove(String id) async {
    materials.removeWhere((m) => m.id == id);
    await _save();
  }

  List<String> generateQuestions(String content) {
    final words = content
        .split(RegExp(r'[\s,.\n;:!?]+'))
        .where((w) => w.length > 4)
        .take(10)
        .toList();
    return [
      if (words.isNotEmpty)
        'What is the main idea related to "${words.first}"?',
      if (words.length > 1) 'Explain how ${words[1]} fits this topic.',
      if (words.length > 2) 'Define: ${words[2]}',
      'List 3 key points from this material.',
      'Write a short summary of these notes.',
      'Create one MCQ based on this content.',
      'Give one practical example from this material.',
    ];
  }
}
