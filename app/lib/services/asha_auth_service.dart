import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// Auth service for ASHA Worker app backed by Firestore.
///
/// Firestore collection used: `appdata/main/users`.
/// Ensure Firebase is initialized before using this class:
///   await Firebase.initializeApp(...);
class AshaAuthService {
  AshaAuthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'appdata/main/users';

  // =============== Helpers ===============
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Changes the user's password after verifying the old password.
  Future<OperationResult> changePassword({
    required String uid,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final docRef = _firestore.collection(_usersCollection).doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        return OperationResult.failure('User not found');
      }
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final storedHash = data['passwordHash'] as String?;
      if (storedHash == null || storedHash != _hashPassword(oldPassword)) {
        return OperationResult.failure('Old password is incorrect');
      }
      await docRef.update({'passwordHash': _hashPassword(newPassword)});
      return OperationResult.success();
    } on FirebaseException catch (e) {
      return OperationResult.failure('Firestore error (${e.code}): ${e.message ?? 'unknown'}');
    } catch (e) {
      return OperationResult.failure('Change password failed: $e');
    }
  }

  Future<bool> _phoneExists(String phoneNumber) async {
    final snap = await _firestore
        .collection(_usersCollection)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // =============== API ===============

  /// Registers a new user document in Firestore.
  ///
  /// Returns [OperationResult] with isSuccess flag and optional errorMessage.
  Future<OperationResult> register({
    required String phoneNumber,
    required String password,
    required String name,
    required String ashaId,
    required String? country,
    required String? state,
    required String? district,
    required String? village,
  }) async {
    try {
      // Check duplicates by phone number
      if (await _phoneExists(phoneNumber)) {
        return OperationResult.failure('User with this phone number already exists');
      }

      final docRef = _firestore.collection(_usersCollection).doc();
      final passwordHash = _hashPassword(password);

      final data = <String, dynamic>{
        'uid': docRef.id,
        'phoneNumber': phoneNumber,
        'passwordHash': passwordHash,
        'name': name,
        'ashaId': ashaId,
        'country': country,
        'state': state,
        'district': district,
        'village': village,
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

  /// Logs in a user by verifying phoneNumber and password.
  ///
  /// Returns [LoginResult] with isSuccess, optional errorMessage, and userData on success.
  Future<LoginResult> login(String phoneNumber, String password) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return LoginResult.failure('No account found for this phone number');
      }

      final doc = query.docs.first;
      final data = doc.data();

      final storedHash = data['passwordHash'] as String?;
      final givenHash = _hashPassword(password);

      if (storedHash == null || storedHash != givenHash) {
        return LoginResult.failure('Invalid phone number or password');
      }

      // Ensure uid is present in returned data
      final userData = <String, dynamic>{'uid': doc.id, ...data};
      return LoginResult.success(userData);
    } on FirebaseException catch (e) {
      return LoginResult.failure('Firestore error (${e.code}): ${e.message ?? 'unknown'}');
    } catch (e) {
      return LoginResult.failure('Login failed: $e');
    }
  }

  /// Updates a user profile document.
  ///
  /// [updatedData] may include any subset of allowed fields (except passwordHash; to
  /// change password, pass plain `password` and this method will hash it into `passwordHash`).
  Future<OperationResult> updateProfile(String uid, Map<String, dynamic> updatedData) async {
    try {
      final safeData = Map<String, dynamic>.from(updatedData);

      // If caller passes a plain password, convert it to passwordHash
      if (safeData.containsKey('password')) {
        final pwd = safeData.remove('password');
        if (pwd is String && pwd.isNotEmpty) {
          safeData['passwordHash'] = _hashPassword(pwd);
        }
      }

      // Never allow uid overwrite
      safeData.remove('uid');

      await _firestore.collection(_usersCollection).doc(uid).update(safeData);
      return OperationResult.success();
    } on FirebaseException catch (e) {
      return OperationResult.failure('Firestore error (${e.code}): ${e.message ?? 'unknown'}');
    } catch (e) {
      return OperationResult.failure('Profile update failed: $e');
    }
  }
}

/// Generic operation result for register and update.
class OperationResult {
  OperationResult._(this.isSuccess, [this.errorMessage]);

  final bool isSuccess;
  final String? errorMessage;

  factory OperationResult.success() => OperationResult._(true);
  factory OperationResult.failure(String message) => OperationResult._(false, message);
}

/// Login result including user data on success.
class LoginResult {
  LoginResult._(this.isSuccess, {this.errorMessage, this.userData});

  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  factory LoginResult.success(Map<String, dynamic> userData) =>
      LoginResult._(true, userData: userData);
  factory LoginResult.failure(String message) =>
      LoginResult._(false, errorMessage: message);
}
