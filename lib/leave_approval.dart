// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:ooriba_s3/services/retrieveDataByEmployeeId.dart';
// import 'services/leave_service.dart'; // Import the leave service

// class LeaveApprovalPage extends StatefulWidget {
//   @override
//   _LeaveApprovalPageState createState() => _LeaveApprovalPageState();
// }

// class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
//   final LeaveService _leaveService = LeaveService();
//   bool isLoading = false;
//   bool hasError = false;
//   String? employeeName;
//   List<Map<String, dynamic>> leaveRequests = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchAllLeaveRequests();
//   }

//   void fetchAllLeaveRequests() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//     try {
//       List<Map<String, dynamic>> requests =
//           await _leaveService.fetchAllLeaveRequests();
//       setState(() {
//         leaveRequests = requests;
//       });
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   String formatDate(Timestamp timestamp) {
//     DateTime dateTime = timestamp.toDate();
//     return '${_getOrdinal(dateTime.day)} ${DateFormat('MMMM yyyy').format(dateTime)}';
//   }

//   String _getOrdinal(int day) {
//     if (day % 10 == 1 && day != 11) {
//       return '${day}st';
//     } else if (day % 10 == 2 && day != 12) {
//       return '${day}nd';
//     } else if (day % 10 == 3 && day != 13) {
//       return '${day}rd';
//     } else {
//       return '${day}th';
//     }
//   }
//   Future<Map<String, dynamic>> getEmployeeDetails(employeeId)async {
//      final FirestoreService firestoreService = FirestoreService();
//     Map<String, dynamic>? employeeData = await firestoreService.getEmployeeById(employeeId);
//     if(employeeData!=null){
//       setState(() {
//          employeeName=employeeData["firstName"]+" "+employeeData["lastName"];
//       });
//     }
//     print("Not found");
//     return {'employeeId': employeeId, 'name': 'Unknown'};
//   }

//   Widget buildLeaveRequestItem(Map<String, dynamic> leaveDetails) {
//      String employeeId = leaveDetails['employeeId'] ?? 'Unknown';
//      getEmployeeDetails(employeeId);
//      print("object");
//     // String name = leaveDetails['name'] ?? 'Anwesha Dash';
//     String name = employeeName ?? 'Anwesha Dash';
//     String leaveType = leaveDetails['leaveType'] ?? 'Unknown';
//     String fromDate = leaveDetails['fromDate'] != null
//         ? formatDate(leaveDetails['fromDate'] as Timestamp)
//         : 'N/A';
//     String toDate = leaveDetails['toDate'] != null
//         ? formatDate(leaveDetails['toDate'] as Timestamp)
//         : 'N/A';
//     double numberOfDays = leaveDetails['numberOfDays'] ?? 0.0;
//     String leaveReason = leaveDetails['leaveReason'] ?? 'No reason provided';

//     return Container(
//       width: 300, // Adjust the width as needed
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0), // Reduced padding
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     backgroundImage: NetworkImage(
//                         'https://via.placeholder.com/150'), // Placeholder image
//                     radius: 25.0, // Reduced radius
//                   ),
//                   SizedBox(width: 8.0), // Reduced spacing
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(name,
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14.0)), // Reduced font size
//                         Text('$employeeId',
//                             style:
//                                 TextStyle(fontSize: 12.0)), // Reduced font size
//                       ],
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('$leaveType',
//                           style:
//                               TextStyle(fontSize: 12.0)), // Reduced font size
//                       Text('$numberOfDays Days',
//                           style:
//                               TextStyle(fontSize: 12.0)), // Reduced font size
//                     ],
//                   ),
//                 ],
//               ),
//               SizedBox(height: 8.0), // Reduced spacing
//               Text('$leaveReason',
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12.0)), // Reduced font size
//               Text('$fromDate - $toDate',
//                   style: TextStyle(fontSize: 12.0)), // Reduced font size
//               SizedBox(height: 8.0), // Reduced spacing
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () async {
//                       await _leaveService.updateLeaveStatus(
//                           employeeId: employeeId,
//                           fromDateStr: fromDate,
//                           isApproved: true);
//                       fetchAllLeaveRequests();
//                     },
//                     child: Text('Approve', style: TextStyle(fontSize: 12.0)),
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(
//                           horizontal: 8.0, vertical: 4.0), // Reduced padding
//                       backgroundColor: Colors.green,
//                     ),
//                   ),
//                   SizedBox(width: 8.0), // Reduced spacing
//                   ElevatedButton(
//                     onPressed: () async {
//                       await _leaveService.updateLeaveStatus(
//                           employeeId: employeeId,
//                           fromDateStr: fromDate,
//                           isApproved: false);
//                       fetchAllLeaveRequests();
//                     },
//                     child: Text('Deny', style: TextStyle(fontSize: 12.0)),
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(
//                           horizontal: 8.0, vertical: 4.0), // Reduced padding
//                       backgroundColor: Colors.red,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Leave Approval'),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : hasError
//               ? Center(
//                   child: Text(
//                       'Failed to fetch leave requests. Please try again later.',
//                       style: TextStyle(color: Colors.red)))
//               : ListView.builder(
//                   itemCount: leaveRequests.length,
//                   itemBuilder: (context, index) {
//                     return buildLeaveRequestItem(leaveRequests[index]);
//                   },
//                 ),
//     );
//   }
// }

// void main() => runApp(MaterialApp(
//       home: LeaveApprovalPage(),
//     ));
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ooriba/services/retrieveDataByEmployeeId.dart';
import 'services/leave_service.dart'; // Import the leave service

class LeaveApprovalPage extends StatefulWidget {
  @override
  _LeaveApprovalPageState createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
  final LeaveService _leaveService = LeaveService();
  bool isLoading = false;
  bool hasError = false;
  List<Map<String, dynamic>> leaveRequests = [];

  @override
  void initState() {
    super.initState();
    fetchAllLeaveRequests();
  }

  void fetchAllLeaveRequests() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      List<Map<String, dynamic>> requests =
          await _leaveService.fetchAllLeaveRequests();
      setState(() {
        leaveRequests = requests;
      });
    } catch (e) {
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${_getOrdinal(dateTime.day)} ${DateFormat('MMMM yyyy').format(dateTime)}';
  }

  String _getOrdinal(int day) {
    if (day % 10 == 1 && day != 11) {
      return '${day}st';
    } else if (day % 10 == 2 && day != 12) {
      return '${day}nd';
    } else if (day % 10 == 3 && day != 13) {
      return '${day}rd';
    } else {
      return '${day}th';
    }
  }

  Future<Map<String, dynamic>> getEmployeeDetails(String employeeId) async {
    final FirestoreService firestoreService = FirestoreService();
    Map<String, dynamic>? employeeData =
        await firestoreService.getEmployeeById(employeeId);
    if (employeeData != null) {
      return employeeData;
    } else {
      return {'employeeId': employeeId, 'name': 'Unknown'};
    }
  }

  Widget buildLeaveRequestItem(Map<String, dynamic> leaveDetails) {
    String employeeId = leaveDetails['employeeId'] ?? 'Unknown';
    String leaveType = leaveDetails['leaveType'] ?? 'Unknown';
    String fromDate = leaveDetails['fromDate'] != null
        ? formatDate(leaveDetails['fromDate'] as Timestamp)
        : 'N/A';
    String toDate = leaveDetails['toDate'] != null
        ? formatDate(leaveDetails['toDate'] as Timestamp)
        : 'N/A';
    double numberOfDays = leaveDetails['numberOfDays'] ?? 0.0;
    String leaveReason = leaveDetails['leaveReason'] ?? 'No reason provided';

    return FutureBuilder<Map<String, dynamic>>(
      future: getEmployeeDetails(employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error fetching employee details');
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Text('Employee data not found');
        } else {
          Map<String, dynamic> employeeData = snapshot.data!;
          String employeeName =
              '${employeeData['firstName']} ${employeeData['lastName']}';
          String employeeRole = employeeData['role'] ?? 'Role not specified';
          String employeeDepartment =
              employeeData['department'] ?? 'Department not specified';
          String employeeDp =
              employeeData['dpImageUrl'] ?? 'https://via.placeholder.com/150';
          // Add more fields as needed

          return Container(
            width: 300, // Adjust the width as needed
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              NetworkImage(employeeDp), // Placeholder image
                          radius: 25.0, // Reduced radius
                        ),
                        SizedBox(width: 8.0), // Reduced spacing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(employeeName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.0)), // Reduced font size
                              Text('$employeeId',
                                  style: TextStyle(
                                      fontSize: 12.0)), // Reduced font size
                              Text(employeeRole,
                                  style:
                                      TextStyle(fontSize: 12.0)), // Role field
                              // Text(employeeDepartment,
                              //     style:
                              //         TextStyle(fontSize: 12.0)), // Department field
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$leaveType',
                                style: TextStyle(
                                    fontSize: 12.0)), // Reduced font size
                            Text('$numberOfDays Days',
                                style: TextStyle(
                                    fontSize: 12.0)), // Reduced font size
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0), // Reduced spacing
                    Text('$leaveReason',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0)), // Reduced font size
                    Text('$fromDate - $toDate',
                        style: TextStyle(fontSize: 12.0)), // Reduced font size
                    SizedBox(height: 8.0), // Reduced spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await _leaveService.updateLeaveStatus(
                                employeeId: employeeId,
                                fromDateStr: fromDate,
                                isApproved: true);
                            fetchAllLeaveRequests();
                          },
                          child:
                              Text('Approve', style: TextStyle(fontSize: 12.0)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0), // Reduced padding
                            backgroundColor: Colors.green,
                          ),
                        ),
                        SizedBox(width: 8.0), // Reduced spacing
                        ElevatedButton(
                          onPressed: () async {
                            await _leaveService.updateLeaveStatus(
                                employeeId: employeeId,
                                fromDateStr: fromDate,
                                isApproved: false);
                            fetchAllLeaveRequests();
                          },
                          child: Text('Deny', style: TextStyle(fontSize: 12.0)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0), // Reduced padding
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Approval'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Text(
                      'Failed to fetch leave requests. Please try again later.',
                      style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: leaveRequests.length,
                  itemBuilder: (context, index) {
                    return buildLeaveRequestItem(leaveRequests[index]);
                  },
                ),
    );
  }
}

void main() => runApp(MaterialApp(
      home: LeaveApprovalPage(),
    ));
