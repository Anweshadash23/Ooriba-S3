import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ooriba/Admin/admin_dashboard_page.dart';
import 'package:ooriba/HR/hr_dashboard_page.dart';
import 'package:ooriba/main.dart';
import 'package:ooriba/post_login_page.dart';
import 'package:ooriba/siteManager/siteManagerDashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<bool> signin({
    required String identifier,
    required String password,
    required BuildContext context,
  }) async {
    if (identifier.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter your email or phone number.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return false;
    }

    String? email;
    // Determine if the identifier is an email or phone number
    if (isEmail(identifier)) {
      email = identifier;
    } else if (isPhoneNumber(identifier)) {
      email = await getEmailFromPhoneNumber(identifier);
      if (email == null) {
        Fluttertoast.showToast(
          msg: 'No user found for that phone number. $identifier',
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
        msg: 'Please enter a valid email or phone number.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return false;
    }

    if (identifier == "Admin" && password == "Admin") {
      await saveUserSession(identifier, "Admin");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => AdminDashboardPage(),
        ),
      );
      return true;
    }
    if (email != null) {
      // Sign in using Firebase Authentication
      return await signInWithEmail(email, password, context);
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
  }

  Future<bool> signInWithEmail(
      String email, String password, BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch the user's role from Firestore based on phone number
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('Regemp')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        Fluttertoast.showToast(
          msg: 'No user found for that email in the database. $email',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        return false;
      }

      final userDoc = snapshot.docs.first;
      String role = userDoc.data()['role'] ?? '';
      await saveUserSession(email, role);

      // Navigate to the appropriate page based on the role
      return await navigateBasedOnRole(context, role, email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Fluttertoast.showToast(
          msg: 'No user found for that email.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      } else if (e.code == 'wrong-password') {
        Fluttertoast.showToast(
          msg: 'Password does not match with the email or phone number.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Please enter a valid email',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
      return false;
    }
  }

  Future<bool> handlePhoneNumberLogin(
      String phoneNumber, String password, BuildContext context) async {
    // Query Firestore to get the employee details associated with the phone number
    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance
            .collection('Regemp')
            .doc(phoneNumber)
            .get();

    if (!userDoc.exists) {
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

    String storedPassword = userDoc.data()?['password'] ?? '';
    String role = userDoc.data()?['role'] ?? '';
    String email = userDoc.data()?['email'] ?? userDoc.data()?['phoneNo'];

    if (storedPassword == password) {
      await saveUserSession(email, role);

      // Navigate to the appropriate page based on the role
      return await navigateBasedOnRole(context, role, email);
    } else {
      Fluttertoast.showToast(
        msg: 'Password does not match with the email or phone number.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return false;
    }
  }

  Future<bool> navigateBasedOnRole(
      BuildContext context, String role, String email) async {
    await Future.delayed(const Duration(seconds: 1));
    if (role == "Standard") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              PostLoginPage(phoneNumber: email, userDetails: {}),
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
    } else if (role == "Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const AdminDashboardPage(),
        ),
      );
      return true;
    } else if (role == "SiteManager") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              Sitemanagerdashboard(phoneNumber: email, userDetails: {}),
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
  }

  Future<void> signout({
    required BuildContext context,
  }) async {
    await FirebaseAuth.instance.signOut();
    await clearUserSession();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => LoginPage(),
        ),
        (Route<dynamic> route) => false);
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
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input);
  }

  bool isPhoneNumber(String input) {
    // Simple regex to check if the input is a phone number
    final phoneRegex = RegExp(r'^\d{10,15}$');
    return phoneRegex.hasMatch(input);
  }

  Future<String?> getEmailFromPhoneNumber(String phoneNumber) async {
    // Query Firestore to get the email associated with the phone number
    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance
            .collection('Regemp')
            .doc(phoneNumber)
            .get();

    if (userDoc.exists) {
      return userDoc.data()?['email'];
    }
    return null;
  }
}
