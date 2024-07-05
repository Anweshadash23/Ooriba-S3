import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ooriba/HR/hr_dashboard_page.dart';
import 'package:ooriba/main.dart';
import 'package:ooriba/post_login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<bool> signin({
    required String identifier,
    required String password,
    required BuildContext context,
  }) async {
    String? email;

    try {
      // Determine if the identifier is an email or phone number
      if (isEmail(identifier)) {
        email = identifier;
      } else if (isPhoneNumber(identifier)) {
        email = await getEmailFromPhoneNumber(identifier);
        if (email == null) {
          Fluttertoast.showToast(
            msg: 'No user found for that phone number.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 14.0,
          );
          return false;
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Invalid email or phone number format.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        return false;
      }

      // Fetch the document from the Firestore collection "Regemp"
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection('Regemp')
              .doc(email)
              .get();

      // Check if the document exists
      if (!documentSnapshot.exists) {
        Fluttertoast.showToast(
          msg: 'No user found for that email.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        return false;
      }

      // Retrieve the role from the document
      String role = documentSnapshot.data()?['role'] ?? '';

      // Sign in with Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email!,
        password: password,
      );

      await saveUserSession(email, role);

      // Navigate to the appropriate page based on the role
      await Future.delayed(const Duration(seconds: 1));
      if (role == "Standard") {
        String firstName = documentSnapshot.data()?['firstName'] ?? '';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                PostLoginPage(phoneNumber: email!, userDetails: {}),
          ),
        );
        return true;
      } else if (role == "HR") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const HRDashboardPage(),
          ),
        );
        return true;
      } else {
        Fluttertoast.showToast(
          msg: 'Invalid role assigned to the user.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        return false;
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return false;
    }
  }

  Future<void> signout({
    required BuildContext context,
  }) async {
    await FirebaseAuth.instance.signOut();
    await clearUserSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(),
      ),
    );
  }

  Future<String?> getUserSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<String?> getUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<void> saveUserSession(String email, String role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('role', role);
  }

  Future<void> clearUserSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('role');
  }

  bool isEmail(String input) {
    // Simple regex to check if the input is an email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(input);
  }

  bool isPhoneNumber(String input) {
    // Simple regex to check if the input is a phone number
    final phoneRegex = RegExp(r'^\d{10}$');
    return phoneRegex.hasMatch(input);
  }

  Future<String?> getEmailFromPhoneNumber(String phoneNumber) async {
    // Query Firestore to get the email associated with the phone number
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('Regemp')
        .where('phoneNo', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.id;
  }
}
