class SignInRequest {
  SignInRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'username': username.trim(), 'password': password};
  }
}
