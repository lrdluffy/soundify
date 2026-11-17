import '../../core/network/api_contract.dart';
import 'json_utils.dart';

class User {
  const User({required this.id, required this.email, this.name});

  final String id;
  final String email;
  final String? name;

  String get displayName =>
      (name != null && name!.isNotEmpty) ? name! : email.split('@').first;

  factory User.fromJson(Map<String, dynamic> j) {
    final data = j['data'] is Map ? asMap(j['data']) : j;
    return User(
      id: pickString(data, ResponseKeys.id) ?? '',
      email: pickString(data, const ['email']) ?? '',
      name: pickString(data, ResponseKeys.userName),
    );
  }
}
