import 'dart:convert';

class UserProfile {
  UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.roles = const <String>[],
  });

  final int id;
  final String username;
  final String? fullName;
  final String? email;
  final List<String> roles;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: (map['id'] as num).toInt(),
      username: map['username']?.toString() ?? '',
      fullName: map['fullName']?.toString(),
      email: map['email']?.toString(),
      roles: ((map['roles'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic role) => role.toString())
          .toList()),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'roles': roles,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory UserProfile.fromJson(String source) {
    return UserProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
