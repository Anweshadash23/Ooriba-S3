import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ooriba/employee_checkin_page.dart';
import 'package:ooriba/hr_dashboard_page.dart';
import 'package:ooriba/services/retrieveDataByEmail.dart';
import 'package:ooriba/employee_signup_success.dart';
import 'package:ooriba/main.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      // Navigate to the confirmation page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ConfirmationPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      } else {
        message = 'An error occurred. Please try again.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signin({
    required String email,
    required String password,
    required String role,
    required BuildContext context,
  }) async {
    final FirestoreService firestoreService = FirestoreService();
    Map<String, dynamic>? employeeData =
        await firestoreService.searchEmployee(email: email);

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      // Navigate based on role
      if (role == "employee") {
        String firstName =
            employeeData != null ? employeeData['firstName'] ?? '' : '';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => EmployeeCheckInPage(
              empname: firstName,
              empemail: email,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const HRDashboardPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'An error occurred. Please try again.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signout({required BuildContext context}) async {
    try {
      await _auth.signOut();

      // Simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred while signing out. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }
}
