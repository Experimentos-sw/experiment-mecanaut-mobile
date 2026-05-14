class UpdateUserRequest {
  UpdateUserRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
  });

  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'roles': roles,
    };
  }
}
