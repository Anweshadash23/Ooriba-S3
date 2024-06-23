import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ooriba/employee_checkin_page.dart';
import 'package:ooriba/employee_signup_success.dart';
import 'package:ooriba/hr_dashboard_page.dart';
import 'package:ooriba/main.dart';

class AuthService {
  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ConfirmationPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<bool> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Sign in the user
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Retrieve the role from Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Regemp')
          .doc(email)
          .get();

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

      Map<String, dynamic> userData =
          documentSnapshot.data() as Map<String, dynamic>;
      String role = userData['role'] ?? '';

      await Future.delayed(const Duration(seconds: 1));
      if (role == 'Employee') {
        String firstName = userData['firstName'] ?? '';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                EmployeeCheckInPage(empname: firstName, empemail: email),
          ),
        );
      } else if (role == 'HR') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const HRDashboardPage(),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Invalid role for the user.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        return false;
      }

      return true;
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
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(),
      ),
    );
  }
}
