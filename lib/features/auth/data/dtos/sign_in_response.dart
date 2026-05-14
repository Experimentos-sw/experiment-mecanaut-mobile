class SignInResponse {
  SignInResponse({
    required this.id,
    required this.username,
    required this.token,
  });

  final int id;
  final String username;
  final String token;

  factory SignInResponse.fromMap(Map<String, dynamic> map) {
    return SignInResponse(
      id: (map['id'] as num).toInt(),
      username: map['username']?.toString() ?? '',
      token: map['token']?.toString() ?? '',
    );
  }
}
