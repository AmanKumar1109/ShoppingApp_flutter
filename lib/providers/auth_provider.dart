import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

class AuthProvider extends ChangeNotifier {
  static const String _userCacheKey = 'cached_user_profile_data';

  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider() {
    _initPersistenceAndAuthListener();
  }

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null || _authService.currentFirebaseUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 1. Initialize local offline cache and background auth listener
  Future<void> _initPersistenceAndAuthListener() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_userCacheKey);

      // Instantly hydrate in-memory user from local disk with 0 network delay
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          _user = UserModel.fromJsonString(cachedJson);
          notifyListeners();
        } catch (_) {}
      }

      // Listen to Firebase Auth state in the background
      _authService.authStateChanges.listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          // If we don't have user or need to sync latest data
          final freshProfile = await _authService.getUserProfile(firebaseUser.uid);
          if (freshProfile != null) {
            _user = freshProfile;
            await _cacheUserLocally(_user!);
            notifyListeners();
          }
          final token = NotificationService.instance.fcmToken;
          if (token != null && token.isNotEmpty) {
            await NotificationService.instance.syncTokenWithFirestore(token);
          }
        } else {
          _user = null;
          await _clearLocalCache();
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Auth persistence init error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Cache user model to SharedPreferences
  Future<void> _cacheUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCacheKey, user.toJsonString());
    } catch (e) {
      debugPrint('Failed to cache user: $e');
    }
  }

  // Clear SharedPreferences
  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
    } catch (_) {}
  }

  // 1. Signup
  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? referredByCode,
    Map<String, dynamic>? addressData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signup(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        referredByCode: referredByCode,
        addressData: addressData,
      );
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthException(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 2. Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthException(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 3. Google OAuth Login (Native in-app modal)
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.loginWithGoogle();
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthException(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 4. Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    await _clearLocalCache();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  // 5. Password Reset
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthException(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 6. Complete Profile
  Future<bool> completeProfile({
    required String fullName,
    required String phone,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.completeProfile(
        uid: _user!.uid,
        fullName: fullName,
        phone: phone,
      );
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 6b. Update Phone & Optional Address (Google Login Onboarding)
  Future<bool> updatePhoneAndAddress({
    required String phone,
    String? fullName,
    Map<String, dynamic>? addressData,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.updatePhoneAndAddress(
        uid: _user!.uid,
        phone: phone,
        fullName: fullName,
        addressData: addressData,
      );
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 6b. Update Profile Photo
  Future<bool> updateProfilePhoto(String photoURL) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.updateProfilePhoto(
        uid: _user!.uid,
        photoURL: photoURL,
      );
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 7. Add Address
  Future<bool> addAddress(Map<String, dynamic> addressData) async {
    if (_user == null) return false;
    try {
      _user = await _authService.addAddress(uid: _user!.uid, addressData: addressData);
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  // 8. Delete Address
  Future<bool> deleteAddress(String addressId) async {
    if (_user == null) return false;
    try {
      _user = await _authService.deleteAddress(uid: _user!.uid, addressId: addressId);
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  // 9. Set Primary Address
  Future<bool> setPrimaryAddress(String addressId) async {
    if (_user == null) return false;
    try {
      _user = await _authService.setPrimaryAddress(uid: _user!.uid, addressId: addressId);
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  // 10. Toggle Wishlist
  Future<bool> toggleWishlist(Map<String, dynamic> product) async {
    if (_user == null) return false;
    try {
      _user = await _authService.toggleWishlist(uid: _user!.uid, product: product);
      if (_user != null) {
        await _cacheUserLocally(_user!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  String _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
