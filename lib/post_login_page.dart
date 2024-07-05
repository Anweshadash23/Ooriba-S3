import 'package:flutter/material.dart';
import 'package:ooriba/facial/DB/DatabaseHelper.dart';
import 'package:ooriba/facial/HomeScreen.dart';
import 'package:ooriba/facial/RegistrationScreen.dart';
import 'package:ooriba/services/auth_service.dart';
import 'package:ooriba/services/retrieveDataByPhoneNumber.dart';

class PostLoginPage extends StatefulWidget {
  final String phoneNumber;
  final Map<String, dynamic> userDetails;

  const PostLoginPage(
      {super.key, required this.phoneNumber, required this.userDetails});

  @override
  _PostLoginPageState createState() => _PostLoginPageState();
}

class _PostLoginPageState extends State<PostLoginPage> {
  final FirestoreService firestoreService = FirestoreService();
  late DatabaseHelper dbHelper;
  bool isRegistered = false;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _checkIfFaceIsRegistered();
  }

  Future<void> _checkIfFaceIsRegistered() async {
    await dbHelper.init();
    final allRows = await dbHelper.queryAllRows();
    setState(() {
      isRegistered = allRows.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ooriba-S3'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signout(context: context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (isRegistered) {
                  Map<String, dynamic>? employeeData = await firestoreService
                      .searchEmployee(phoneNumber: widget.phoneNumber);
                  String firstName = employeeData != null
                      ? employeeData['firstName'] ?? ''
                      : '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          HomeScreen(phoneNumber: widget.phoneNumber),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen()),
                  );
                }
              },
              child: Text(isRegistered
                  ? 'Attendance'
                  : 'Register for Facial Authentication'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
