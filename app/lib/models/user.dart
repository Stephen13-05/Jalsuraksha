class User {
  // Optional local DB primary key (SQLite)
  final int? id;
  // Remote UID (e.g., Firestore)
  final String? uid;
  final String phoneNumber;
  final String password;
  final String? name;
  final String? email;
  final String? ashaId;
  final String? country;
  final String? state;
  final String? district;
  final String? village;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    this.uid,
    required this.phoneNumber,
    required this.password,
    this.name,
    this.email,
    this.ashaId,
    this.country,
    this.state,
    this.district,
    this.village,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert User object to Map for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      // Intentionally omit 'id' so SQLite can auto-increment on insert
      'phoneNumber': phoneNumber,
      'password': password,
      'name': name,
      'email': email,
      'ashaId': ashaId,
      'country': country,
      'state': state,
      'district': district,
      'village': village,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create User object from Firestore document
  factory User.fromMap(Map<String, dynamic> map, {String? uid}) {
    return User(
      id: map['id'] as int?,
      uid: uid,
      phoneNumber: map['phoneNumber'] ?? '',
      password: map['password'] ?? '',
      name: map['name'],
      email: map['email'],
      ashaId: map['ashaId'],
      country: map['country'],
      state: map['state'],
      district: map['district'],
      village: map['village'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  // Create a copy of User with updated fields
  User copyWith({
    int? id,
    String? uid,
    String? phoneNumber,
    String? password,
    String? name,
    String? email,
    String? ashaId,
    String? country,
    String? state,
    String? district,
    String? village,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      name: name ?? this.name,
      email: email ?? this.email,
      ashaId: ashaId ?? this.ashaId,
      country: country ?? this.country,
      state: state ?? this.state,
      district: district ?? this.district,
      village: village ?? this.village,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, uid: $uid, phoneNumber: $phoneNumber, name: $name, email: $email}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.uid == uid &&
        other.phoneNumber == phoneNumber &&
        other.password == password &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode {
    return (id ?? 0).hashCode ^
        uid.hashCode ^
        phoneNumber.hashCode ^
        password.hashCode ^
        name.hashCode ^
        email.hashCode;
  }
}
