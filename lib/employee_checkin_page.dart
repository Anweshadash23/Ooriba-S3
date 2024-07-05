// EmailJS
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ooriba/services/auth_service.dart';
import 'package:ooriba/services/updateEmployee.dart';
import 'package:ooriba/services/retrieveDataByPhoneNumber.dart'
    as retrieveDataByPhoneNumber; // Updated import

class EmployeeCheckInPage extends StatefulWidget {
  final String empname;
  final String empphoneNumber; // Updated property

  const EmployeeCheckInPage({
    super.key,
    required this.empname,
    required this.empphoneNumber,
  });

  @override
  _EmployeeCheckInPageState createState() => _EmployeeCheckInPageState();
}

class CheckInOutRecord {
  final DateTime date;
  bool isCheckedIn;
  DateTime? checkInTime;
  DateTime? checkOutTime;

  CheckInOutRecord({
    required this.date,
    this.isCheckedIn = false,
    this.checkInTime,
    this.checkOutTime,
  });
}

class _EmployeeCheckInPageState extends State<EmployeeCheckInPage> {
  String? employeeId;
  String? employeeName;
  late DateTime dataDate;
  late List<CheckInOutRecord> checkInOutRecords;
  late String _phoneNumber; // Updated property

  @override
  void initState() {
    super.initState();
    _phoneNumber = widget.empphoneNumber; // Initialize with phone number
    checkInOutRecords = _generateCheckInOutRecords();
    _fetchEmployeeDetails(widget.empphoneNumber); // Call with phone number
  }

  String formatTimeWithoutSeconds(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A'; // Return 'N/A' if dateTime is null
    }
    return DateFormat('yyyy-MM-dd HH:mm')
        .format(dateTime); // Format without seconds
  }

  Future<void> _fetchEmployeeDetails(String phoneNumber) async {
    retrieveDataByPhoneNumber.FirestoreService firestoreService =
        retrieveDataByPhoneNumber.FirestoreService();
    Map<String, dynamic>? employeeData =
        await firestoreService.getEmployeeByPhoneNumber(phoneNumber);

    if (employeeData != null) {
      setState(() {
        employeeId = employeeData['employeeId'];
        employeeName = employeeData['firstName'];
        // employeeName = employeeData['firstName'] + ' ' + employeeData['lastName'];
      });
    }
  }

  List<CheckInOutRecord> _generateCheckInOutRecords() {
    // Generate records for the last 7 days
    List<CheckInOutRecord> records = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < 1; i++) {
      DateTime date = now.subtract(Duration(days: i));
      // Dummy logic to alternate check-in and check-out for demonstration
      bool isCheckedIn = i.isOdd;
      DateTime? checkInTime =
          isCheckedIn ? date.add(const Duration(hours: 8)) : null;
      DateTime? checkOutTime =
          isCheckedIn ? null : date.add(const Duration(hours: 8));

      records.add(CheckInOutRecord(
        date: date,
        isCheckedIn: isCheckedIn,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
      ));
    }
    return records;
  }

  void _toggleCheckInOut(int index) async {
    final FirestoreService firestoreService = FirestoreService();
    void addData() async {
      if (widget.empname.isNotEmpty) {
        setState(() {});

        await firestoreService.addCheckInOutData(
          widget.empphoneNumber, // Use phone number instead of email
          checkInOutRecords[index].checkInTime!,
          checkInOutRecords[index].checkOutTime!,
          dataDate,
        );

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a first name')),
        );
      }
    }

    setState(() {
      DateTime now = DateTime.now();
      checkInOutRecords[index].isCheckedIn =
          !checkInOutRecords[index].isCheckedIn;
      dataDate = now.subtract(Duration(days: index));
      if (checkInOutRecords[index].isCheckedIn) {
        checkInOutRecords[index].checkInTime = DateTime.now();
        checkInOutRecords[index].checkOutTime = null;

        _sendCheckInEmail(
          widget.empname,
          widget.empphoneNumber,
          checkInOutRecords[index].checkInTime!,
        );
      } else {
        checkInOutRecords[index].checkOutTime = DateTime.now();
        addData();
        _sendCheckOutEmail(
          widget.empname,
          widget.empphoneNumber,
          checkInOutRecords[index].checkOutTime!,
        );
      }
    });
    //update into database
  }

  // EmailJS Integration
  Future<void> _sendCheckInEmail(
      String empname, String empphoneNumber, DateTime checkInTime) async {
    const serviceId = 'service_qe69w28';
    const templateId = 'template_1owmygk';
    const userId = 'lMYaM2NpLYjm2qSWI';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http:localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'empname': empname,
          'empphoneNumber': empphoneNumber,
          'check_in_time': checkInTime.toIso8601String(),
        }
      }),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Check-in email sent successfully');
      }
    } else {
      if (kDebugMode) {
        print('Failed to send check-in email: ${response.body}');
      }
    }
  }

  Future<void> _sendCheckOutEmail(
      String empname, String empphoneNumber, DateTime checkOutTime) async {
    const serviceId = 'service_qe69w28';
    const templateId = 'template_drhybtc';
    const userId = 'lMYaM2NpLYjm2qSWI';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'empphoneNumber': empphoneNumber,
          'empname': empname,
          'check_out_time': checkOutTime.toIso8601String(),
        }
      }),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Check-out email sent successfully');
      }
    } else {
      if (kDebugMode) {
        print('Failed to send check-out email: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${employeeId != null && employeeName != null ? '$employeeName-$employeeId' : widget.empphoneNumber}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signout(context: context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: checkInOutRecords.length,
        itemBuilder: (context, index) {
          bool isCheckedIn = checkInOutRecords[index].isCheckedIn;
          return ListTile(
            title: Text(
              'Date: ${checkInOutRecords[index].date.toLocal().toString().split(' ')[0]}',
            ),
            subtitle: isCheckedIn
                ? Text(
                    'Checked in at: ${formatTimeWithoutSeconds(checkInOutRecords[index].checkInTime)}')
                : Text(
                    'Checked out at: ${formatTimeWithoutSeconds(checkInOutRecords[index].checkOutTime)}'),
            trailing: ElevatedButton(
              onPressed: () => _toggleCheckInOut(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCheckedIn
                    ? Colors.green
                    : Colors.orange, // Set button color
              ),
              child: Text(isCheckedIn ? 'Check Out' : 'Check In'),
            ),
          );
        },
      ),
    );
  }
}
