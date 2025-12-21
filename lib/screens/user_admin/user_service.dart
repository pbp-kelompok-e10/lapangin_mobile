import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:lapangin/screens/user_admin/user.dart';
import 'package:lapangin/config/api_config.dart';

class UserService {
<<<<<<< HEAD
=======
  // Changed: Use 10.0.2.2 for Android emulator and removed trailing slash
  static const String baseUrl = 'https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id';

>>>>>>> 297ad2dcdff3826bce3e44a3ac27b10392be96b9
  final CookieRequest request;

  UserService(this.request);

  /// fetch user w filter/search
  Future<List<User>> getUserList({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      String url = ApiConfig.userListUrl(
        search: search,
        status: status,
        page: page,
      );

      print('Fetching users from: $url');

      final response = await request.get(url);

      if (response != null) {
        List<dynamic> results;

        if (response is List) {
          results = response;
        } else if (response['results'] != null) {
          results = response['results'];
        } else if (response['users'] != null) {
          results = response['users'];
        } else {
          results = [];
        }

        return results.map((json) => User.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching user list: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  /// fetch user detail by id
  Future<User?> getUserDetail(int userId) async {
    try {
      final response = await request.get(ApiConfig.userDetailUrl(userId));

      if (response != null) {
        return User.fromJson(response);
      }

      return null;
    } catch (e) {
      print('Error fetching user detail: $e');
      throw Exception('Failed to load user detail: $e');
    }
  }

  /// create user
  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String confirmPassword,
    String? fullName,
    String? phone,
    String? address,
    bool isStaff = false,
    bool isActive = true,
  }) async {
    try {
      final response = await request.postJson(
        ApiConfig.createUserUrl,
        jsonEncode({
          'username': username,
          'password': password,
          'confirm_password': confirmPassword,
          'full_name': fullName,
          'phone': phone,
          'address': address,
          'is_staff': isStaff,
          'is_active': isActive,
        }),
      );

      return response;
    } catch (e) {
      print('Error creating user: $e');
      return {'status': 'error', 'message': 'Failed to create user: $e'};
    }
  }

  /// Update user
  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? username,
    String? password,
    String? confirmPassword,
    String? fullName,
    String? phone,
    String? address,
    bool? isStaff,
    bool? isActive,
  }) async {
    try {
      Map<String, dynamic> data = {};

      if (username != null) data['username'] = username;
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
        data['confirm_password'] = confirmPassword;
      }
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      if (isStaff != null) data['is_staff'] = isStaff;
      if (isActive != null) data['is_active'] = isActive;

      final response = await request.postJson(
        ApiConfig.editUserUrl(userId),
        jsonEncode(data),
      );

      return response;
    } catch (e) {
      print('Error updating user: $e');
      return {'status': 'error', 'message': 'Failed to update user: $e'};
    }
  }

  /// Toggle user status
  Future<Map<String, dynamic>> toggleUserStatus(int userId) async {
    try {
      final response = await request.post(
        ApiConfig.toggleUserStatusUrl(userId),
        {},
      );

      return response;
    } catch (e) {
      print('Error toggling user status: $e');
      return {'status': 'error', 'message': 'Failed to toggle user status: $e'};
    }
  }

  /// Delete user
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await request.post(ApiConfig.deleteUserUrl(userId), {});

      return response;
    } catch (e) {
      print('Error deleting user: $e');
      return {'status': 'error', 'message': 'Failed to delete user: $e'};
    }
  }
}
