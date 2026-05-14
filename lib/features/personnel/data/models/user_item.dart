class UserItem {
  UserItem({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.roles,
  });

  final int id;
  final String username;
  final String fullName;
  final String email;
  final List<String> roles;

  String get initials {
    final parts = fullName
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return username.isNotEmpty ? username[0].toUpperCase() : 'U';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory UserItem.fromMap(Map<String, dynamic> map) {
    return UserItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      username: map['username']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      roles: (map['roles'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
    );
  }
}
