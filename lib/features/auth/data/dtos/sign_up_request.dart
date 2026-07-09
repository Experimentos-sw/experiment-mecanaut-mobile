class SignUpRequest {
  SignUpRequest({
    required this.ruc,
    required this.legalName,
    this.commercialName,
    this.address,
    this.city,
    this.country,
    this.tenantPhone,
    required this.tenantEmail,
    this.website,
    required this.subscriptionPlanId,
    required this.username,
    required this.password,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  final String ruc;
  final String legalName;
  final String? commercialName;
  final String? address;
  final String? city;
  final String? country;
  final String? tenantPhone;
  final String tenantEmail;
  final String? website;
  final int subscriptionPlanId;
  final String username;
  final String password;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ruc': ruc,
      'legalName': legalName,
      'commercialName': commercialName,
      'address': address,
      'city': city,
      'country': country,
      'tenantPhone': tenantPhone,
      'tenantEmail': tenantEmail,
      'website': website,
      'subscriptionPlanId': subscriptionPlanId,
      'username': username,
      'password': password,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
  }
}
