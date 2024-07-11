import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:ooriba/facial/DB/DatabaseHelper.dart';
import 'package:ooriba/facial/RecognitionScreenForSite.dart';
import 'package:ooriba/facial/RegistrationScreenForSite.dart';
import 'package:ooriba/services/auth_service.dart';
import 'package:ooriba/services/geo_service.dart';
import 'package:ooriba/services/SiteManager/retrieveDataByEmail.dart'
    as retrieveDataByEmail;
import 'package:ooriba/services/user.dart';

class Sitemanagerdashboard extends StatefulWidget {
  final String phoneNumber;
  final Map<String, dynamic> userDetails;

  const Sitemanagerdashboard(
      {super.key, required this.phoneNumber, required this.userDetails});

  @override
  _SitemanagerdashboardState createState() => _SitemanagerdashboardState();
}

class _SitemanagerdashboardState extends State<Sitemanagerdashboard> {
  String? employeeId;
  String? employeeName;
  String? employeePhoneNumber;
  String? dpImageUrl;
  DateTime? lastLoginTime;
  final UserFirestoreService firestoreService = UserFirestoreService();
  late DatabaseHelper dbHelper;
  bool isRegistered = false;
  bool isLoading = true;
  final GeoService geoService = GeoService();
  bool isWithinRange = false;
  bool isLoadingForLocation = false;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    fetchEmployeeData();
    _checkIfFaceIsRegistered();
    _checkLocation();
  }

  Future<void> fetchEmployeeData() async {
    await _fetchEmployeeDetails(widget.phoneNumber);
    await _fetchLastLoginTime(widget.phoneNumber);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkIfFaceIsRegistered() async {
    await dbHelper.init();
    final allRows = await dbHelper.queryAllRows();
    setState(() {
      isRegistered = allRows.isNotEmpty;
    });
  }

  void _checkLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      Position position = await geoService.determinePosition();
      bool withinRange = await geoService.isWithin50m(position);

      setState(() {
        isWithinRange = withinRange;
        isLoading = false;
      });

      Fluttertoast.showToast(
          msg: withinRange
              ? "You are at the location"
              : "You are not at the location");
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatTime(DateTime? time) {
    if (time == null) return " ";
    // return "${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}";
    return DateFormat.jm().format(time);
  }

  Future<void> _fetchEmployeeDetails(String phoneNumber) async {
    retrieveDataByEmail.FirestoreService firestoreService =
        retrieveDataByEmail.FirestoreService();
    Map<String, dynamic>? employeeData = await firestoreService
        .getEmployeeByEmailOrPhoneNo(phoneNumber, "Regemp");

    if (employeeData != null) {
      setState(() {
        employeeId = employeeData['employeeId'];
        employeeName = employeeData['firstName'];
        employeePhoneNumber = employeeData['phoneNo'];
        dpImageUrl = employeeData['dpImageUrl'];
      });
    } else {
      print(
          'Employee details not found for email or Phone Number (retriving): $phoneNumber');
    }
  }

  Future<void> _fetchLastLoginTime(String phoneNumber) async {
    try {
      DocumentSnapshot docSnapshot =
          await firestoreService.getLastLoginTime(phoneNumber);

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        var lastLoginTimestamp = data['lastLoginTime'];

        if (lastLoginTimestamp != null) {
          setState(() {
            lastLoginTime = (lastLoginTimestamp as Timestamp).toDate();
          });
        } else {
          print('Last login time is null for email: $phoneNumber');
          await _updateLastLoginTime(phoneNumber);
        }
      } else {
        print('Document not found for email: $phoneNumber');
        await _createAndSaveLastLoginTime(phoneNumber);
      }
    } catch (e) {
      print('Error fetching last login time: $e');
      if (e is FirebaseException && e.code == 'not-found') {
        await _createAndSaveLastLoginTime(phoneNumber);
      }
    }
  }

  Future<void> _createAndSaveLastLoginTime(String phoneNumber) async {
    DateTime now = DateTime.now();
    await firestoreService.createLastLoginTime(phoneNumber, now);
    setState(() {
      lastLoginTime = now;
    });
  }

  Future<void> _updateLastLoginTime(String phoneNumber) async {
    DateTime now = DateTime.now();
    await firestoreService.saveLastLoginTime(phoneNumber, now);
    setState(() {
      lastLoginTime = now;
    });
  }

  Future<void> _saveLastLoginTime() async {
    DateTime now = DateTime.now();
    await firestoreService.saveLastLoginTime(widget.phoneNumber, now);
  }

  Future<String> getImageUrl(String employeeId) async {
    String imagePath = 'authImage/$employeeId.jpg';
    try {
      final ref = FirebaseStorage.instance.ref().child(imagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error fetching image for $employeeId: $e');
      return '';
    }
  }

  String formatTimeWithoutSeconds(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/a';
    }
    // return DateFormat('dd-MM-yyyy   HH:mm').format(dateTime);
    return DateFormat.yMMMMd('en_US').add_Hm().format(dateTime);
  }

  void navigateToFaceRecognitionScreen() async {
    // final result =
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecognitionScreen()),
    );

    // if (result == true) {
    //   if (isCheckedIn) {
    //     _checkOut();
    //   } else {
    //     _checkIn();
    //   }
    // }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0, // Remove spacing between title and leading widget
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context)
                    .openDrawer(); // Open drawer on menu icon tap
              },
            );
          },
        ),
        title: Row(
          children: [
            if (dpImageUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(dpImageUrl!),
              ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employeeName != null
                        ? 'Welcome, Site-Manager'
                        : "Loading in Site",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  if (lastLoginTime != null)
                    Text(
                      'Last login: ${formatTimeWithoutSeconds(lastLoginTime)}',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _saveLastLoginTime();
              await AuthService().signout(context: context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                // Handle Dashboard tap
              },
            ),
            ListTile(
              leading: Icon(Icons.tag_faces_outlined),
              title: Text('Register'),
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.event_available),
              title: Text('Attendance'),
              onTap: () {
                // Handle Attendance tap
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Handle Settings tap
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await _saveLastLoginTime();
                await AuthService().signout(context: context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: isWithinRange
              ? () {
                  navigateToFaceRecognitionScreen();
                }
              : null,
          child: const Text('Recognize'),
        ),
      ),
    );
  }
}
