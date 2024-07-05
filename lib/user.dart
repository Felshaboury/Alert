class User {
  final String id;
  final String username;
  final String email;
  final String mobileNumber;
  final String password;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.mobileNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'mobileNumber': mobileNumber,
      'password': password,
    };
  }
}