import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:app/services/asha_auth_service.dart' show OperationResult, LoginResult;

/// Authentication service for villager-facing experience backed by Firestore.
///
/// Firestore path layout:
///   appdata/main/villagers/{uid}
/// Each villager document stores their profile metadata plus the password hash.
class VillagerAuthService {
  VillagerAuthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _villagersCollection = 'appdata/main/villagers';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> _phoneExists(String phoneNumber) async {
    final snap = await _firestore
        .collection(_villagersCollection)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<OperationResult> register({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String village,
    required String district,
    required String state,
    String? gender,
  }) async {
    try {
      if (await _phoneExists(phoneNumber)) {
        return OperationResult.failure('An account already exists for this phone number');
      }

      if (state.trim().isEmpty || district.trim().isEmpty || village.trim().isEmpty) {
        return OperationResult.failure('State, district, and village are required');
      }

      final docRef = _firestore.collection(_villagersCollection).doc();
      final data = <String, dynamic>{
        'uid': docRef.id,
        'phoneNumber': phoneNumber,
        'passwordHash': _hashPassword(password),
        'fullName': fullName,
        'village': village,
        'district': district,
        'state': state,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      return OperationResult.success();
    } on FirebaseException catch (e) {
      return OperationResult.failure('Firestore error (${e.code}): ${e.message ?? 'unknown'}');
    } catch (e) {
      return OperationResult.failure('Registration failed: $e');
    }
  }

  Future<LoginResult> login(String phoneNumber, String password) async {
    try {
      final query = await _firestore
          .collection(_villagersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return LoginResult.failure('No villager account found for this phone number');
      }

      final doc = query.docs.first;
      final data = doc.data();
      final storedHash = data['passwordHash'] as String?;
      if (storedHash == null || storedHash != _hashPassword(password)) {
        return LoginResult.failure('Incorrect phone number or password');
      }

      final userData = <String, dynamic>{'uid': doc.id, ...data};
      return LoginResult.success(userData);
    } on FirebaseException catch (e) {
      return LoginResult.failure('Firestore error (${e.code}): ${e.message ?? 'unknown'}');
    } catch (e) {
      return LoginResult.failure('Login failed: $e');
    }
  }

  Future<OperationResult> updateProfile(String uid, Map<String, dynamic> updates) async {
    try {
      final safeData = Map<String, dynamic>.from(updates);
      if (safeData.containsKey('password')) {
        final pwd = safeData.remove('password');
        if (pwd is String && pwd.isNotEmpty) {
          safeData['passwordHash'] = _hashPassword(pwd);
        }
      }
      safeData.remove('uid');
      await _firestore.collection(_villagersCollection).doc(uid).update(safeData);
      return OperationResult.success();
    } on FirebaseException catch (e) {
      return OperationResult.failure('Firestore error (${e.code}): ${e.message ?? 'unknown'}');
    } catch (e) {
      return OperationResult.failure('Profile update failed: $e');
    }
  }
}
