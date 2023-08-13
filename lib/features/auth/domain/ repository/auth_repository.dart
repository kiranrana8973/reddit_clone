import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reddit_clone/core/constants/app_constants.dart';
import 'package:reddit_clone/core/providers/providers.dart';

import '../entity/auth_entity.dart';

final authRepositoryProvder = Provider(
  (ref) => AuthRepository(
    firestore: ref.read(fireStoreProvider),
    firebaseAuth: ref.read(firebaseAuthProvider),
    googleSignIn: ref.read(googleSignInProvider),
  ),
);

class AuthRepository {
  final FirebaseFirestore _firebaseFirestore;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  CollectionReference get _users => _firebaseFirestore.collection('users');

  AuthRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseFirestore = firestore,
        _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  Future<AuthEntity> singInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Store in firebase
      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      late AuthEntity authEntity;

      // If the user is new then store data in firestore
      if (userCredential.additionalUserInfo!.isNewUser) {
        authEntity = AuthEntity(
          name: userCredential.user?.displayName ?? 'No name',
          profilePic:
              userCredential.user?.photoURL ?? AppConstants.avatarDefault,
          banner: AppConstants.bannerDefault,
          uid: userCredential.user!.uid,
          isAuthenticated: true,
          karma: 0,
          awards: [],
        );
        // Store in firestore
        await _users.doc(userCredential.user!.uid).set(authEntity.toMap());
      }

      return authEntity;
    } catch (e) {
      rethrow;
    }
  }
}
