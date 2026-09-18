import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._firestore, this._storage);
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Future<void> createProfile(UserProfile profile) =>
      _users.doc(profile.uid).set(profile.toMap());

  Future<void> updateProfile(String uid, Map<String, dynamic> changes) =>
      _users.doc(uid).update(changes);

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserProfile.fromDoc(doc) : null,
        );
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? UserProfile.fromDoc(doc) : null;
  }

  Future<String> uploadProfileImage(String uid, File file) async {
    final ref = _storage.ref('profile_images/$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
