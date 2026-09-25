import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of Auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current Firebase User
  User? get currentFirebaseUser => _auth.currentUser;

  // Fetch UserModel from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      // Return null or handle error
    }
    return null;
  }

  // 1. Email/Password Signup
  Future<UserModel?> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? referredByCode,
    Map<String, dynamic>? addressData,
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final User? user = credential.user;
    if (user == null) return null;

    // Also update display name in Firebase Auth
    await user.updateDisplayName(fullName);

    final myReferralCode = UserModel.generateReferralCode(fullName);

    final List<Map<String, dynamic>> initialAddresses = [];
    String? primaryAddressId;
    if (addressData != null && addressData.isNotEmpty) {
      initialAddresses.add(addressData);
      primaryAddressId = addressData['id'];
    }

    final initialProfile = {
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'photoURL': null,
      'profileCompleted': true,
      'addresses': initialAddresses,
      'primaryAddressId': primaryAddressId,
      'wishlist': [],
      'welcomeEmailSent': true,
      'referredByCode':
          (referredByCode != null && referredByCode.trim().isNotEmpty)
          ? referredByCode.trim()
          : null,
      'myReferralCode': myReferralCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(user.uid).set(initialProfile);

    return UserModel.fromMap(initialProfile, user.uid);
  }

  // 2. Email/Password Login
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;
    if (user == null) return null;

    UserModel? profile = await getUserProfile(user.uid);

    // If profile document does not exist, provision initial record
    if (profile == null) {
      final myReferralCode = UserModel.generateReferralCode(
        user.displayName ?? 'User',
      );
      final fallbackData = {
        'fullName': user.displayName ?? 'User',
        'email': user.email ?? email,
        'phone': user.phoneNumber ?? '',
        'photoURL': user.photoURL,
        'profileCompleted': true,
        'addresses': [],
        'primaryAddressId': null,
        'wishlist': [],
        'welcomeEmailSent': true,
        'referredByCode': null,
        'myReferralCode': myReferralCode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('users').doc(user.uid).set(fallbackData);
      profile = UserModel.fromMap(fallbackData, user.uid);
    }

    return profile;
  }

  // 3. Native In-App Google OAuth Login Popup
  Future<UserModel?> loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) return null; // User cancelled the popup

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    final User? user = userCredential.user;
    if (user == null) return null;

    UserModel? profile = await getUserProfile(user.uid);

    if (profile == null) {
      final myReferralCode = UserModel.generateReferralCode(
        user.displayName ?? 'Google User',
      );
      final googleInitialProfile = {
        'fullName': user.displayName ?? 'Google User',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'photoURL': user.photoURL,
        'profileCompleted': false, // Requires phone number completion
        'addresses': [],
        'primaryAddressId': null,
        'wishlist': [],
        'welcomeEmailSent': true,
        'referredByCode': null,
        'myReferralCode': myReferralCode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(googleInitialProfile);
      profile = UserModel.fromMap(googleInitialProfile, user.uid);
    }

    return profile;
  }

  // 4. Logout
  Future<void> logout() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }

  // 5. Password Reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // 6. Complete Profile
  Future<UserModel?> completeProfile({
    required String uid,
    required String fullName,
    required String phone,
  }) async {
    final updateData = {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('users').doc(uid).update(updateData);
    return getUserProfile(uid);
  }

  // 6b. Update Phone & Optional Address (Google OAuth Post-Registration)
  Future<UserModel?> updatePhoneAndAddress({
    required String uid,
    required String phone,
    String? fullName,
    Map<String, dynamic>? addressData,
  }) async {
    final Map<String, dynamic> updateData = {
      'phone': phone.trim(),
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fullName != null && fullName.trim().isNotEmpty) {
      updateData['fullName'] = fullName.trim();
    }

    if (addressData != null && addressData.isNotEmpty) {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final List addresses = List.from(data['addresses'] ?? []);
        addresses.add(addressData);
        updateData['addresses'] = addresses;
        String? primaryId = data['primaryAddressId'];
        if (primaryId == null || primaryId.isEmpty) {
          updateData['primaryAddressId'] = addressData['id'];
        }
      }
    }

    await _firestore.collection('users').doc(uid).update(updateData);
    return getUserProfile(uid);
  }

  // 7. Update Profile Photo
  Future<UserModel?> updateProfilePhoto({
    required String uid,
    required String photoURL,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'photoURL': photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePhotoURL(photoURL);
    }
    return getUserProfile(uid);
  }

  // 8. Add Address
  Future<UserModel?> addAddress({
    required String uid,
    required Map<String, dynamic> addressData,
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data()!;
    List addresses = List.from(data['addresses'] ?? []);
    addresses.add(addressData);

    String? primaryId = data['primaryAddressId'];
    if (primaryId == null || primaryId.isEmpty) {
      primaryId = addressData['id'];
    }

    await _firestore.collection('users').doc(uid).update({
      'addresses': addresses,
      'primaryAddressId': primaryId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return getUserProfile(uid);
  }

  // 9. Delete Address
  Future<UserModel?> deleteAddress({
    required String uid,
    required String addressId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data()!;
    List addresses = List.from(data['addresses'] ?? []);
    addresses.removeWhere((item) => item['id'] == addressId);

    String? primaryId = data['primaryAddressId'];
    if (primaryId == addressId) {
      primaryId = addresses.isNotEmpty ? addresses.first['id'] : null;
    }

    await _firestore.collection('users').doc(uid).update({
      'addresses': addresses,
      'primaryAddressId': primaryId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return getUserProfile(uid);
  }

  // 10. Set Primary Address
  Future<UserModel?> setPrimaryAddress({
    required String uid,
    required String addressId,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'primaryAddressId': addressId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return getUserProfile(uid);
  }

  // 11. Toggle Wishlist Product
  Future<UserModel?> toggleWishlist({
    required String uid,
    required Map<String, dynamic> product,
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data()!;
    List wishlist = List.from(data['wishlist'] ?? []);
    final existsIndex = wishlist.indexWhere(
      (item) => item['id'] == product['id'],
    );

    if (existsIndex >= 0) {
      wishlist.removeAt(existsIndex);
    } else {
      wishlist.add(product);
    }

    await _firestore.collection('users').doc(uid).update({
      'wishlist': wishlist,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return getUserProfile(uid);
  }
}
