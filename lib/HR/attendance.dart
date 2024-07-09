// // import 'dart:io';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:ooriba_s3/services/retrieveDataByEmail.dart';
// import 'package:ooriba_s3/services/retrieveFromDates_service.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// // import 'package:csv/csv.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:flutter/foundation.dart' show kIsWeb;
// // import 'dart:convert';
// // import 'dart:html' as html;

// class DatePickerButton extends StatefulWidget {
//   @override
//   _DatePickerButtonState createState() => _DatePickerButtonState();
// }

// class _DatePickerButtonState extends State<DatePickerButton> {
//   DateTime? _selectedDate;
//   Map<String, Map<String, String>> _data = {};
//   List<Map<String, dynamic>> _allEmployees = [];
//   bool _sortOrder = true; // true for ascending (absent first), false for descending (present first)
//   String _selectedLocation = 'Default Location'; // Track the selected location
//   List<String> _locations = ['Default Location']; // List of locations including 'All'
//   void removeLocationn(String location) {
//   _locations.removeWhere((element) => element == location);
//   }
//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = DateTime.now(); // Set to today's date by default
//     _fetchAllEmployees();
//     _fetchData(DateFormat('yyyy-MM-dd').format(_selectedDate!)); // Fetch today's data by default

//   }

//   void _fetchAllEmployees() async {
//     FirestoreService firestoreService = FirestoreService();
//     _allEmployees = await firestoreService.getAllEmployees();
//     // Extract distinct locations
//     _locations.addAll(_allEmployees.map((e) => e['location'] ?? '').toSet().cast<String>());
//     removeLocationn('');
//     setState(() {});
//   }

//   void _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2101),
//     );

//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//       _fetchData(DateFormat('yyyy-MM-dd').format(picked));
//     }
//   }

//   void _fetchData(String date) async {
//     DateService service = DateService();
//     FirestoreService firestoreService = FirestoreService();

//     // Fetch attendance data for the selected date
//     Map<String, Map<String, String>> data = await service.getDataByDate(date);

//     Map<String, Map<String, String>> attendanceData = {};

//     for (String email in data.keys) {
//       var employeeData = await firestoreService.getEmployeeByEmail(email);
//       if (employeeData != null) {
//         attendanceData[employeeData["employeeId"]] = data[employeeData["employeeId"]]!;
//       }
//     }

//     setState(() {
//       _data = attendanceData;
//       _sortEmployees(); // Sort employees after fetching data
//     });
//   }

//   void _sortEmployees() {
//     _allEmployees.sort((a, b) {
//       bool aPresent = _data.containsKey(a['email']);
//       bool bPresent = _data.containsKey(b['email']);
//       if (_sortOrder) {
//         return aPresent ? 1 : -1;
//       } else {
//         return aPresent ? -1 : 1;
//       }
//     });
//   }

//   List<Map<String, dynamic>> _filterEmployeesByLocation() {
//     return _allEmployees.where((e) =>
//       (_selectedLocation == 'Default Location' || e['location'] == _selectedLocation) &&
//       e['role'] == 'Standard'
//     ).toList();
//   }

//   Future<String> getImageUrl(String email) async {
//     // Construct the path to the image in Firebase Storage
//     String imagePath = 'authImage/$email.jpg';

//     try {
//       // Get the download URL for the image
//       final ref = FirebaseStorage.instance.ref().child(imagePath);
//       final url = await ref.getDownloadURL();
//       return url;
//     } catch (e) {
//       print('Error fetching image for $email: $e');
//       return '';
//     }
//   }
// Future<void> _downloadCsv() async {
//   List<Map<String, dynamic>> filteredEmployees = _filterEmployeesByLocation();

//   // Build CSV content
//   StringBuffer csvContent = StringBuffer();
//   csvContent.writeln(  "Date, ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}");
//   csvContent.writeln('EmployeeId,Name,Location,Check-in,Check-out,Status,Phone No');

//   for (var employee in filteredEmployees) {
//     String email=employee['email'];
//     String empId= employee['employeeId']?? 'Null';
//     String name = employee['firstName']+" "+employee['lastName'] ?? 'Null';
//     String location = employee['location'] ?? '';
//     String phoneNo=employee['phoneNo']??'Null';
//     bool isPresent = _data.containsKey(email);
//     Map<String, String> emailData = isPresent
//         ? _data[email]!
//         : {'checkIn': 'N/A', 'checkOut': 'N/A'};
//     String checkIn = emailData['checkIn']!;
//     String checkOut = emailData['checkOut']!;
//     String status = isPresent ? 'present' : 'absent';

//     csvContent.writeln('$empId,$name,$location,$checkIn,$checkOut,$status,$phoneNo');
//   }

//   // Request storage permission
//   if (await Permission.storage.request().isGranted || await Permission.manageExternalStorage.request().isGranted) {
//     // Get the downloads directory
//     Directory? directory = await getExternalStorageDirectory();
//     String? downloadPath;

//     if (Platform.isAndroid) {
//       downloadPath = '/storage/emulated/0/Download'; // Path to the Download folder on Android
//     } else {
//       downloadPath = directory?.path;
//     }

//     if (downloadPath != null) {
//       String path = '$downloadPath/attendance_${DateFormat('yyyyMMdd').format(_selectedDate!)}.csv';

//       // Save the CSV file
//       File file = File(path);
//       await file.writeAsString(csvContent.toString());

//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved to $path')));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to access storage directory')));
//     }
//   } else if (await Permission.storage.isDenied || await Permission.manageExternalStorage.isDenied) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Storage permission denied')));
//   } else if (await Permission.storage.isPermanentlyDenied || await Permission.manageExternalStorage.isPermanentlyDenied) {
//     openAppSettings();
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     List<Map<String, dynamic>> filteredEmployees = _filterEmployeesByLocation();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Attendance Page'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.download),
//             onPressed: _downloadCsv,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   _selectDate(context);
//                 },
//                 child: Text(
//                     ' ${_selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : 'Select a date'}'),
//               ),
//               DropdownButton<String>(
//                 value: _selectedLocation,
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedLocation = newValue!;
//                   });
//                 },
//                 items: _locations.map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               IconButton(
//                 icon: Icon(_sortOrder ? Icons.arrow_upward : Icons.arrow_downward),
//                 onPressed: () {
//                   setState(() {
//                     _sortOrder = !_sortOrder;
//                     _sortEmployees();
//                   });
//                 },
//               ),
//             ],
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredEmployees.length,
//               itemBuilder: (context, index) {
//                 String email = filteredEmployees[index]['email'];
//                 String firstName = filteredEmployees[index]['firstName'] ?? '';
//                 String lastName = filteredEmployees[index]['lastName'] ?? '';
//                 String location = filteredEmployees[index]['location'] ?? '';
//                 bool isPresent = _data.containsKey(email);
//                 Map<String, String> emailData = isPresent
//                     ? _data[email]!
//                     : {'checkIn': 'N/A', 'checkOut': 'N/A'};

//                 return Card(
//                   margin:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: ListTile(
//                     title: Text('$firstName $lastName $email'),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Location: $location'),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Expanded(
//                                 child:
//                                     Text('Check-in: ${emailData['checkIn']}')),
//                             Expanded(
//                                 child: Text(
//                                     'Check-out: ${emailData['checkOut']}')),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         RichText(
//                           text: TextSpan(
//                             children: [
//                               const TextSpan(
//                                 text: 'Status: ',
//                                 style: TextStyle(color: Colors.black),
//                               ),
//                               TextSpan(
//                                 text: isPresent ? 'Present' : 'Absent',
//                                 style: TextStyle(
//                                     color:
//                                         isPresent ? Colors.green : Colors.red),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     trailing: isPresent
//                         ? FutureBuilder<String>(
//                             future: getImageUrl(email),
//                             builder: (context, snapshot) {
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return CircularProgressIndicator();
//                               } else if (snapshot.hasError ||
//                                   !snapshot.hasData ||
//                                   snapshot.data!.isEmpty) {
//                                 return Text('No image');
//                               } else {
//                                 return InkWell(
//                                   onTap: () {
//                                     showDialog(
//                                       context: context,
//                                       builder: (context) => AlertDialog(
//                                         content: Image.network(snapshot.data!),
//                                         actions: <Widget>[
//                                           TextButton(
//                                             child: Text('Close'),
//                                             onPressed: () {
//                                               Navigator.of(context).pop();
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                   child: Image.network(
//                                     snapshot.data!,
//                                     width: 60,
//                                     height: 60,
//                                     fit: BoxFit.fill,
//                                   ),
//                                 );
//                               }
//                             },
//                           )
//                         : Icon(Icons.image_not_supported, size: 60),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // void _downloadCsv() async {
// //   List<List<String>> data = [
// //     ['Date', DateFormat('dd-MM-yyyy').format(_selectedDate!)], // Add selected date at the beginning
// //     ['First Name', 'Last Name', 'Email', 'Location', 'Check-in', 'Check-out', 'Status', 'Phone No']
// //   ];
// //   for (var employee in _filterEmployeesByLocation()) {
// //     String email = employee['email'];
// //     String firstName = employee['firstName'] ?? '';
// //     String lastName = employee['lastName'] ?? '';
// //     String location = employee['location'] ?? '';
// //     String phoneNo = employee['phoneNo'] ?? '';
// //     bool isPresent = _data.containsKey(email);
// //     Map<String, String> emailData = isPresent
// //         ? _data[email]!
// //         : {'checkIn': 'N/A', 'checkOut': 'N/A'};
// //     String status = isPresent ? 'present' : 'absent';

// //     data.add([
// //       firstName,
// //       lastName,
// //       email,
// //       location,
// //       emailData['checkIn'] ?? 'N/A',
// //       emailData['checkOut'] ?? 'N/A',
// //       status,
// //       phoneNo
// //     ]);
// //   }

// //   String csvData = const ListToCsvConverter().convert(data);

// //   if (kIsWeb) {
// //     final bytes = utf8.encode(csvData);
// //     final blob = html.Blob([bytes]);
// //     final url = html.Url.createObjectUrlFromBlob(blob);
// //     final anchor = html.AnchorElement(href: url)
// //       ..setAttribute('download', 'attendance_${DateFormat('yyyyMMdd').format(_selectedDate!)}.csv')
// //       ..click();
// //     html.Url.revokeObjectUrl(url);
// //   } else {
// //     final directory = await getApplicationDocumentsDirectory();
// //     final path = '${directory.path}/attendance_${DateFormat('yyyyMMdd').format(_selectedDate!)}.csv';
// //     final file = File(path);
// //     await file.writeAsString(csvData);
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('CSV downloaded to $path')),
// //     );
// //   }
// // }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:ooriba_s3/services/retrieveDataByEmployeeId.dart'; // Updated import
// import 'package:ooriba_s3/services/retrieveFromDates_service.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class DatePickerButton extends StatefulWidget {
//   const DatePickerButton({super.key});

//   @override
//   _DatePickerButtonState createState() => _DatePickerButtonState();
// }

// class _DatePickerButtonState extends State<DatePickerButton> {
//   DateTime? _selectedDate;
//   Map<String, Map<String, String>> _data = {};
//   List<Map<String, dynamic>> _allEmployees = [];
//   bool _sortOrder = true;
//   String _selectedLocation = 'Default Location';
//   final List<String> _locations = ['Default Location'];

//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = DateTime.now();
//     _fetchAllEmployees();
//     _fetchData(DateFormat('yyyy-MM-dd').format(_selectedDate!));
//   }

//   void _fetchAllEmployees() async {
//     FirestoreService firestoreService = FirestoreService();
//     _allEmployees = await firestoreService.getAllEmployees();
//     _locations.addAll(_allEmployees.map((e) => e['location'] ?? '').toSet().cast<String>());
//     _locations.removeWhere((element) => element == '');
//     setState(() {});
//   }

//   void _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2101),
//     );

//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//       _fetchData(DateFormat('yyyy-MM-dd').format(picked));
//     }
//   }

//   void _fetchData(String date) async {
//     DateService service = DateService();
//     Map<String, Map<String, String>> data = await service.getDataByDate(date);
//     setState(() {
//       _data = data;
//       _sortEmployees();
//     });
//   }

//   void _sortEmployees() {
//     _allEmployees.sort((a, b) {
//       bool aPresent = _data.containsKey(a['employeeId']);
//       bool bPresent = _data.containsKey(b['employeeId']);
//       if (_sortOrder) {
//         return aPresent ? 1 : -1;
//       } else {
//         return aPresent ? -1 : 1;
//       }
//     });
//   }

//   List<Map<String, dynamic>> _filterEmployeesByLocation() {
//     return _allEmployees.where((e) =>
//       (_selectedLocation == 'Default Location' || e['location'] == _selectedLocation) &&
//       e['role'] == 'Standard'
//     ).toList();
//   }

//   Future<String> getImageUrl(String employeeId) async {
//     String imagePath = 'authImage/$employeeId.jpg';
//     try {
//       final ref = FirebaseStorage.instance.ref().child(imagePath);
//       final url = await ref.getDownloadURL();
//       return url;
//     } catch (e) {
//       print('Error fetching image for $employeeId: $e');
//       return '';
//     }
//   }

//   Future<void> _downloadCsv() async {
//     List<Map<String, dynamic>> filteredEmployees = _filterEmployeesByLocation();
//     StringBuffer csvContent = StringBuffer();
//     csvContent.writeln("Date, ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}");
//     csvContent.writeln('EmployeeId,Name,Location,Check-in,Check-out,Status,Phone No');

//     for (var employee in filteredEmployees) {
//       String empId = employee['employeeId'] ?? 'Null';
//       String name = '${employee['firstName']} ${employee['lastName']}' ?? 'Null';
//       String location = employee['location'] ?? '';
//       String phoneNo = employee['phoneNo'] ?? 'Null';
//       bool isPresent = _data.containsKey(empId);
//       Map<String, String> empData = isPresent ? _data[empId]! : {'checkIn': 'N/A', 'checkOut': 'N/A'};
//       String checkIn = empData['checkIn']!;
//       String checkOut = empData['checkOut']!;
//       String status = isPresent ? 'present' : 'absent';

//       csvContent.writeln('$empId,$name,$location,$checkIn,$checkOut,$status,$phoneNo');
//     }

//     if (await Permission.storage.request().isGranted || await Permission.manageExternalStorage.request().isGranted) {
//       Directory? directory = await getExternalStorageDirectory();
//       String? downloadPath = Platform.isAndroid ? '/storage/emulated/0/Download' : directory?.path;

//       if (downloadPath != null) {
//         String path = '$downloadPath/attendance_${DateFormat('yyyyMMdd').format(_selectedDate!)}.csv';
//         File file = File(path);
//         await file.writeAsString(csvContent.toString());
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved to $path')));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to access storage directory')));
//       }
//     } else if (await Permission.storage.isDenied || await Permission.manageExternalStorage.isDenied) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission denied')));
//     } else if (await Permission.storage.isPermanentlyDenied || await Permission.manageExternalStorage.isPermanentlyDenied) {
//       openAppSettings();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<Map<String, dynamic>> filteredEmployees = _filterEmployeesByLocation();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Attendance Page'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download),
//             onPressed: _downloadCsv,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   _selectDate(context);
//                 },
//                 child: Text(
//                     ' ${_selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : 'Select a date'}'),
//               ),
//               DropdownButton<String>(
//                 value: _selectedLocation,
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedLocation = newValue!;
//                   });
//                 },
//                 items: _locations.map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               IconButton(
//                 icon: Icon(_sortOrder ? Icons.arrow_upward : Icons.arrow_downward),
//                 onPressed: () {
//                   setState(() {
//                     _sortOrder = !_sortOrder;
//                     _sortEmployees();
//                   });
//                 },
//               ),
//             ],
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredEmployees.length,
//               itemBuilder: (context, index) {
//               String capitalize(String x) {
//                 return "${x[0].toUpperCase()}${x.substring(1)}";
//               }
//                 String employeeId = filteredEmployees[index]['employeeId'];
//                 String firstName = capitalize(filteredEmployees[index]['firstName']) ?? '';
//                 String lastName = filteredEmployees[index]['lastName'] ?? '';
//                 String location = filteredEmployees[index]['location'] ?? '';
//                 bool isPresent = _data.containsKey(employeeId);
//                 Map<String, String> empData = isPresent
//                     ? _data[employeeId]!
//                     : {'checkIn': 'N/A', 'checkOut': 'N/A'};

//                 return Card(
//                   margin:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: ListTile(
//                     title: Text('$firstName : $employeeId'),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Location: $location'),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Expanded(
//                                 child: Text('Check-in: ${empData['checkIn']}')),
//                             Expanded(
//                                 child: Text('Check-out: ${empData['checkOut']}')),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         RichText(
//                           text: TextSpan(
//                             children: [
//                               const TextSpan(
//                                 text: 'Status: ',
//                                 style: TextStyle(color: Colors.black),
//                               ),
//                               TextSpan(
//                                 text: isPresent ? 'Present' : 'Absent',
//                                 style: TextStyle(
//                                     color:
//                                         isPresent ? Colors.green : Colors.red),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     trailing: isPresent
//                         ? FutureBuilder<String>(
//                             future: getImageUrl(employeeId),
//                             builder: (context, snapshot) {
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return const CircularProgressIndicator();
//                               } else if (snapshot.hasError ||
//                                   !snapshot.hasData ||
//                                   snapshot.data!.isEmpty) {
//                                 return const Text('No image');
//                               } else {
//                                 return InkWell(
//                                   onTap: () {
//                                     showDialog(
//                                       context: context,
//                                       builder: (context) => AlertDialog(
//                                         content: Image.network(snapshot.data!),
//                                         actions: <Widget>[
//                                           TextButton(
//                                             child: const Text('Close'),
//                                             onPressed: () {
//                                               Navigator.of(context).pop();
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                   child: Image.network(
//                                     snapshot.data!,
//                                     width: 60,
//                                     height: 60,
//                                     fit: BoxFit.fill,
//                                   ),
//                                 );
//                               }
//                             },
//                           )
//                         : const Icon(Icons.image_not_supported, size: 60),     ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:ooriba/services/retrieveDataByEmployeeId.dart'; // Updated import
import 'package:ooriba/services/retrieveFromDates_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ooriba/services/geo_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class DatePickerButton extends StatefulWidget {
  const DatePickerButton({super.key});

  @override
  _DatePickerButtonState createState() => _DatePickerButtonState();
}

class _DatePickerButtonState extends State<DatePickerButton> {
  DateTime? _selectedDate;
  Map<String, Map<String, String>> _data = {};
  List<Map<String, dynamic>> _allEmployees = [];
  bool _sortOrder = true;
  String _selectedLocation = 'Berhampur';
  final List<String> _locations = [];
  // String _selectedLocation = 'Default Location';
  // final List<String> _locations = ['Default Location'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchAllEmployees();
    _fetchData(DateFormat('yyyy-MM-dd').format(_selectedDate!));
  }

  void _fetchAllEmployees() async {
    FirestoreService firestoreService = FirestoreService();
    _allEmployees = await firestoreService.getAllEmployees();
    _locations.addAll(
        _allEmployees.map((e) => e['location'] ?? '').toSet().cast<String>());
    _locations.removeWhere((element) => element == '');
    setState(() {
      _sortEmployees();
    });
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
    Map<String, Map<String, String>> data = await service.getDataByDate(date);
    setState(() {
      _data = data;
      _sortEmployees();
    });
  }

  void _sortEmployees() {
    _allEmployees.sort((a, b) {
      bool aPresent = _data.containsKey(a['employeeId']);
      bool bPresent = _data.containsKey(b['employeeId']);
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
            (e['location'] == _selectedLocation) &&
            // (_selectedLocation == 'Default Location' || e['location'] == _selectedLocation) &&
            e['role'] == 'Standard')
        .toList();
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

  Future<void> _downloadCsv() async {
    List<Map<String, dynamic>> filteredEmployees = _filterEmployeesByLocation();
    StringBuffer csvContent = StringBuffer();
    csvContent
        .writeln("Date, ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}");
    csvContent.writeln(
        'EmployeeId,Name,Location,Check-in,Check-out,Status,Phone No,Hours');

    for (var employee in filteredEmployees) {
      String empId = employee['employeeId'] ?? 'Null';
      String name =
          '${employee['firstName']} ${employee['lastName']}' ?? 'Null';
      String location = employee['location'] ?? '';
      String phoneNo = employee['phoneNo'] ?? 'Null';
      bool isPresent = _data.containsKey(empId);
      Map<String, String> empData =
          isPresent ? _data[empId]! : {'checkIn': 'N/A', 'checkOut': 'N/A'};
      String checkIn = empData['checkIn']!;
      String checkOut = empData['checkOut']!;
      String status = isPresent ? 'present' : 'absent';
      String Hours = "Upcoming";

      csvContent.writeln(
          '$empId,$name,$location,$checkIn,$checkOut,$status,$phoneNo,$Hours');
    }

    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {
      Directory? directory = await getExternalStorageDirectory();
      String? downloadPath =
          Platform.isAndroid ? '/storage/emulated/0/Download' : directory?.path;

      if (downloadPath != null) {
        String path =
            '$downloadPath/attendance_${DateFormat('yyyyMMdd').format(_selectedDate!)}.csv';
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
//   Future<void> _downloadCsv() async {
//   List<Map<String, dynamic>> filteredEmployees = _filterEmployeesByLocation();
//   StringBuffer csvContent = StringBuffer();
//   csvContent.writeln("Date, ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}");
//   csvContent.writeln('EmployeeId,Name,Location,Check-in,Check-out,Status,Phone No,Hours');

//   for (var employee in filteredEmployees) {
//     String empId = employee['employeeId'] ?? 'Null';
//     String name = '${employee['firstName']} ${employee['lastName']}' ?? 'Null';
//     String location = employee['location'] ?? '';
//     String phoneNo = employee['phoneNo'] ?? 'Null';
//     bool isPresent = _data.containsKey(empId);
//     Map<String, String> empData = isPresent ? _data[empId]! : {'checkIn': 'N/A', 'checkOut': 'N/A'};
//     String checkIn = empData['checkIn']!;
//     String checkOut = empData['checkOut']!;
//     String status = isPresent ? 'present' : 'absent';

//     // Calculate hours
//     int hours = 0;
//     if (checkIn != 'N/A' && checkOut != 'N/A') {
//       try {
//         // Debug output
//         print('Parsing times for employee $empId: checkIn: $checkIn, checkOut: $checkOut');

//         DateTime checkInTime = DateFormat('HH:mm').parse(checkIn);
//         DateTime checkOutTime = DateFormat('HH:mm').parse(checkOut);

//         // Debug output
//         print('Parsed times: checkInTime: $checkInTime, checkOutTime: $checkOutTime');

//         hours = checkOutTime.difference(checkInTime).inHours;

//         // Debug output
//         print('Calculated hours: $hours');
//       } catch (e) {
//         print('Error parsing time for employee $empId: $e');
//       }
//     }

//     csvContent.writeln('$empId,$name,$location,$checkIn,$checkOut,$status,$phoneNo,$hours');
//   }

//   if (await Permission.storage.request().isGranted || await Permission.manageExternalStorage.request().isGranted) {
//     Directory? directory = await getExternalStorageDirectory();
//     String? downloadPath = Platform.isAndroid ? '/storage/emulated/0/Download' : directory?.path;

//     if (downloadPath != null) {
//       String path = '$downloadPath/attendance_${DateFormat('yyyyMMdd').format(_selectedDate!)}.csv';
//       File file = File(path);
//       await file.writeAsString(csvContent.toString());
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved to $path')));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to access storage directory')));
//     }
//   } else if (await Permission.storage.isDenied || await Permission.manageExternalStorage.isDenied) {
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission denied')));
//   } else if (await Permission.storage.isPermanentlyDenied || await Permission.manageExternalStorage.isPermanentlyDenied) {
//     openAppSettings();
//   }
// }
  void _openLocationOnMap(String employeeId) async {
    try {
      GeoService geoService = GeoService();
      Position position = await geoService.determinePosition();

      // You need to fetch latitude and longitude of the employee from your Firestore database
      // Assuming employee details have `latitude` and `longitude` fields
      var employee =
          _allEmployees.firstWhere((e) => e['employeeId'] == employeeId);
      double employeeLatitude = 16.52154568524242;
      double employeeLongitude = 80.52320068916423;

      String googleMapsUrl =
          "https://www.google.com/maps/search/?api=1&query=$employeeLatitude,$employeeLongitude";

      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not launch $googleMapsUrl';
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'Error opening map: $e');
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
                String capitalize(String x) {
                  return "${x[0].toUpperCase()}${x.substring(1)}";
                }

                String employeeId = filteredEmployees[index]['employeeId'];
                String firstName =
                    capitalize(filteredEmployees[index]['firstName']) ?? '';
                String lastName = filteredEmployees[index]['lastName'] ?? '';
                String location = filteredEmployees[index]['location'] ?? '';
                bool isPresent = _data.containsKey(employeeId);
                Map<String, String> empData = isPresent
                    ? _data[employeeId]!
                    : {'checkIn': 'N/A', 'checkOut': 'N/A'};

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('$firstName : $employeeId'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Location: $location'),
                            IconButton(
                              icon: const Icon(Icons.location_on),
                              onPressed: () {
                                _openLocationOnMap(employeeId);
                                // Add your onPressed functionality here, if needed.
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text('Check-in: ${empData['checkIn']}')),
                            Expanded(
                                child:
                                    Text('Check-out: ${empData['checkOut']}')),
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
                            future: getImageUrl(employeeId),
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
