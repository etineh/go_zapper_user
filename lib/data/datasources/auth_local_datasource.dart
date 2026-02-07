import 'dart:convert';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<void> setLoggedIn(bool isLoggedIn);
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await sharedPreferences.setString(AppConstants.userKey, userJson);
    } catch (e) {
      throw CacheException('Failed to cache user data');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJsonString = sharedPreferences.getString(AppConstants.userKey);
      if (userJsonString != null) {
        final userJson = jsonDecode(userJsonString);
        return UserModel.fromJson(userJson);
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to retrieve cached user data');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(AppConstants.userKey);
      await sharedPreferences.remove(AppConstants.isLoggedInKey);
    } catch (e) {
      throw CacheException('Failed to clear cache');
    }
  }

  @override
  Future<void> setLoggedIn(bool isLoggedIn) async {
    try {
      await sharedPreferences.setBool(AppConstants.isLoggedInKey, isLoggedIn);
    } catch (e) {
      throw CacheException('Failed to set login status');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      return sharedPreferences.getBool(AppConstants.isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }
}
