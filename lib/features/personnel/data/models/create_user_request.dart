class CreateUserRequest {
  CreateUserRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
  });

  final String username;
  final String password;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username,
      'password': password,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'roles': roles,
    };
  }
}
