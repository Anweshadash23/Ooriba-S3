// import 'dart:io';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ooriba/services/retrieveDataByPhoneNumber.dart';
import 'package:ooriba/services/retrieveFromDates_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:csv/csv.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'dart:convert';
// import 'dart:html' as html;

class DatePickerButton extends StatefulWidget {
  const DatePickerButton({super.key});

  @override
  _DatePickerButtonState createState() => _DatePickerButtonState();
}

class _DatePickerButtonState extends State<DatePickerButton> {
  DateTime? _selectedDate;
  Map<String, Map<String, String>> _data = {};
  List<Map<String, dynamic>> _allEmployees = [];
  bool _sortOrder =
      true; // true for ascending (absent first), false for descending (present first)
  String _selectedLocation = 'Default Location'; // Track the selected location
  final List<String> _locations = [
    'Default Location'
  ]; // List of locations including 'All'
  void removeLocationn(String location) {
    _locations.removeWhere((element) => element == location);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Set to today's date by default
    _fetchAllEmployees();
    _fetchData(DateFormat('yyyy-MM-dd')
        .format(_selectedDate!)); // Fetch today's data by default
  }

  void _fetchAllEmployees() async {
    FirestoreService firestoreService = FirestoreService();
    _allEmployees = await firestoreService.getAllEmployees();
    // Extract distinct locations
    _locations.addAll(
        _allEmployees.map((e) => e['location'] ?? '').toSet().cast<String>());
    removeLocationn('');
    setState(() {});
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _fetchData(String date) async {
    DateService service = DateService();
    FirestoreService firestoreService = FirestoreService();

    // Fetch attendance data for the selected date
    Map<String, Map<String, String>> data = await service.getDataByDate(date);

    Map<String, Map<String, String>> attendanceData = {};

    for (String phoneNumber in data.keys) {
      var employeeData =
          await firestoreService.getEmployeeByPhoneNumber(phoneNumber);
      if (employeeData != null) {
        attendanceData[phoneNumber] = data[phoneNumber]!;
      }
    }

    setState(() {
      _data = attendanceData;
      _sortEmployees(); // Sort employees after fetching data
    });
  }

  void _sortEmployees() {
    _allEmployees.sort((a, b) {
      bool aPresent = _data.containsKey(a['phoneNo']);
      bool bPresent = _data.containsKey(b['phoneNo']);
      if (_sortOrder) {
        return aPresent ? 1 : -1;
      } else {
        return aPresent ? -1 : 1;
      }
    });
  }

  List<Map<String, dynamic>> _filterEmployeesByLocation() {
    return _allEmployees
        .where((e) =>
            (_selectedLocation == 'Default Location' ||
                e['location'] == _selectedLocation) &&
            e['role'] == 'Standard')
        .toList();
  }

  Future<String> getImageUrl(String phoneNumber) async {
    // Construct the path to the image in Firebase Storage
    String imagePath = 'authImage/$phoneNumber.jpg';

    try {
      // Get the download URL for the image
      final ref = FirebaseStorage.instance.ref().child(imagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error fetching image for $phoneNumber: $e');
      return '';
    }
  }

  Future<void> _downloadCsv() async {
    List<Map<String, dynamic>> filteredEmployees = _filterEmployeesByLocation();

    // Build CSV content
    StringBuffer csvContent = StringBuffer();
    csvContent
        .writeln("Date, ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}");
    csvContent
        .writeln('EmployeeId,Name,Location,Check-in,Check-out,Status,Phone No');

    for (var employee in filteredEmployees) {
      String phoneNo = employee['phoneNo'];
      String empId = employee['employeeId'] ?? 'Null';
      String name =
          employee['firstName'] + " " + employee['lastName'] ?? 'Null';
      String location = employee['location'] ?? '';
      bool isPresent = _data.containsKey(phoneNo);
      Map<String, String> phoneData =
          isPresent ? _data[phoneNo]! : {'checkIn': 'N/A', 'checkOut': 'N/A'};
      String checkIn = phoneData['checkIn']!;
      String checkOut = phoneData['checkOut']!;
      String status = isPresent ? 'present' : 'absent';

      csvContent.writeln(
          '$empId,$name,$location,$checkIn,$checkOut,$status,$phoneNo');
    }

    // Request storage permission
    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {
      // Get the downloads directory
      Directory? directory = await getExternalStorageDirectory();
      String? downloadPath;

      if (Platform.isAndroid) {
        downloadPath =
            '/storage/emulated/0/Download'; // Path to the Download folder on Android
      } else {
        downloadPath = directory?.path;
      }

      if (downloadPath != null) {
        String path =
            '$downloadPath/attendance_${DateFormat('yyyyMMdd').format(_selectedDate!)}.csv';

        // Save the CSV file
        File file = File(path);
        await file.writeAsString(csvContent.toString());

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('CSV saved to $path')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to access storage directory')));
      }
    } else if (await Permission.storage.isDenied ||
        await Permission.manageExternalStorage.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')));
    } else if (await Permission.storage.isPermanentlyDenied ||
        await Permission.manageExternalStorage.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredEmployees = _filterEmployeesByLocation();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  _selectDate(context);
                },
                child: Text(
                    ' ${_selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : 'Select a date'}'),
              ),
              DropdownButton<String>(
                value: _selectedLocation,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue!;
                  });
                },
                items: _locations.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              IconButton(
                icon: Icon(
                    _sortOrder ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortOrder = !_sortOrder;
                    _sortEmployees();
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                String phoneNo = filteredEmployees[index]['phoneNo'];
                String firstName = filteredEmployees[index]['firstName'] ?? '';
                String lastName = filteredEmployees[index]['lastName'] ?? '';
                String location = filteredEmployees[index]['location'] ?? '';
                bool isPresent = _data.containsKey(phoneNo);
                Map<String, String> phoneData = isPresent
                    ? _data[phoneNo]!
                    : {'checkIn': 'N/A', 'checkOut': 'N/A'};

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('$firstName $lastName $phoneNo'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location: $location'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child:
                                    Text('Check-in: ${phoneData['checkIn']}')),
                            Expanded(
                                child: Text(
                                    'Check-out: ${phoneData['checkOut']}')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Status: ',
                                style: TextStyle(color: Colors.black),
                              ),
                              TextSpan(
                                text: isPresent ? 'Present' : 'Absent',
                                style: TextStyle(
                                    color:
                                        isPresent ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: isPresent
                        ? FutureBuilder<String>(
                            future: getImageUrl(phoneNo),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Text('No image');
                              } else {
                                return InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        content: Image.network(snapshot.data!),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Close'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    snapshot.data!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.fill,
                                  ),
                                );
                              }
                            },
                          )
                        : const Icon(Icons.image_not_supported, size: 60),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
