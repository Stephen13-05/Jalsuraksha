import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VillagerDataService {
  VillagerDataService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _villagersCollection() =>
      _firestore.collection('appdata').doc('main').collection('villagers');

  Future<String?> uploadIssueImage({required File file, required String uid}) async {
    try {
      final ref = _storage
          .ref()
          .child('villagers')
          .child(uid)
          .child('issues')
          .child('${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> submitIssue({
    required String uid,
    required String title,
    required String description,
    required String category,
    required String village,
    required String district,
    String? imageUrl,
    Map<String, dynamic>? extra,
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'title': title,
      'description': description,
      'category': category,
      'village': village,
      'district': district,
      'imageUrl': imageUrl,
      'extra': extra,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = _villagersCollection().doc(uid).collection('issues').doc();
    await docRef.set(data);

    // Mirror a village-level feed for dashboards
    final feedRef = _firestore
        .collection('appdata')
        .doc('main')
        .collection('villager_issues')
        .doc(docRef.id);
    await feedRef.set(data);
  }

  Future<List<Map<String, dynamic>>> fetchRecentIssues({
    required String uid,
    int limit = 5,
  }) async {
    try {
      final snap = await _villagersCollection()
          .doc(uid)
          .collection('issues')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchVillageAlerts({
    required String district,
    required String village,
    int limit = 10,
  }) async {
    try {
      final snap = await _firestore
          .collection('appdata')
          .doc('main')
          .collection('village_alerts')
          .where('district', isEqualTo: district)
          .where('village', isEqualTo: village)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) {
          final data = {'id': d.id, ...d.data()};
          final createdAt = data['createdAt'];
          if (createdAt is Timestamp) {
            data['createdAt'] = createdAt.toDate();
          }
          return data;
        }).toList();
      }
    } catch (_) {}

    // Provide fallback alerts if none exist
    return [
      {
        'id': 'fallback-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Maintain clean drinking water',
        'description': 'Boil drinking water for at least 1 minute before use until further notice.',
        'createdAt': DateTime.now(),
        'severity': 'medium',
      },
      {
        'id': 'fallback2-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Report stagnant water',
        'description': 'Please report stagnant water bodies to sanitation officers to help prevent disease spread.',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'severity': 'low',
      },
    ];
  }
}
