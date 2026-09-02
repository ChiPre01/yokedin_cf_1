import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

Future<void> saveGoogleUser({
  required String uid,
  required String email,
  required String name,
}) async {
  await _firestore.collection("userData").doc(uid).set({
    'name': name,
    'uid': uid,
    'email': email,
    'score': 0,
  });
}

  //  sign up function inside class
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some Error Occured";

    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        // register user in firebase with email and password
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // store user in Firestore
        await _firestore.collection("userData").doc(credential.user!.uid).set(
          {
            'name': name,
            'uid': credential.user!.uid,
            'email': email,
            'score': 0,
          },
        );

        res = "success";
      } else {
        res = "Please fill all the fields";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }

  // for log in user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some Error Occured";

    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        res = "success";
      } else {
        res = "Please fill all the fields";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }
  
  //google sign in
 Future<Map<String, dynamic>?> signInWithGoogle() async {
  try {
    UserCredential? userCredential;

    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user;

    if (user == null) return null;

    // 🔥 Check if user already exists in Firestore
    final doc = await _firestore.collection("userData").doc(user.uid).get();

    if (doc.exists) {
      // already registered
      return {
        "status": "existing",
        "user": user,
      };
    } else {
      // new user → needs name
      return {
        "status": "new",
        "user": user,
      };
    }
  } catch (e) {
    print(e.toString());
    return null;
  }
}

  // for log out 
  Future<void>signOut()async{ 
    await _auth.signOut(); 
  } 
}