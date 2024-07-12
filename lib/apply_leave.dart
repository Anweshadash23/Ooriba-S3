import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplyLeavePage extends StatefulWidget {
  @override
  _ApplyLeavePageState createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Earned Leave',
    'Partial Leave'
  ];
  String selectedLeaveType = 'Sick Leave'; // Default value

  TextEditingController employeeIdSearchController = TextEditingController();
  TextEditingController employeeIdController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  TextEditingController leaveReasonController = TextEditingController();
  TextEditingController numberOfDaysController = TextEditingController();

  Map<String, dynamic>? leaveDetails;

  DateFormat dateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    numberOfDaysController.text = '0';
  }

  void calculateDays() {
    if (fromDateController.text.isNotEmpty &&
        toDateController.text.isNotEmpty) {
      DateTime from = dateFormat.parse(fromDateController.text);
      DateTime to = dateFormat.parse(toDateController.text);
      int days = to.difference(from).inDays + 1; // Including the start date
      setState(() {
        numberOfDaysController.text = days.toString();
      });
    }
  }

  Future<void> applyLeave({
    required String employeeId,
    required String leaveType,
    required DateTime? fromDate,
    required DateTime? toDate,
    required double numberOfDays,
    required String? leaveReason,
  }) async {
    try {
      String fromDateStr =
          fromDate != null ? fromDate.toIso8601String().split('T').first : '';

      await _firestore
          .collection('leave')
          .doc('accept')
          .collection(employeeId)
          .doc(fromDateStr)
          .set({
        'employeeId': employeeId,
        'leaveType': leaveType,
        'fromDate': fromDate,
        'toDate': toDate,
        'numberOfDays': numberOfDays,
        'leaveReason': leaveReason,
        'isApproved': true, // Set isApproved to true as required
        'count': FieldValue.increment(1), // Increment the leave count
      });

      // Increment the leave count for the employee in LeaveCount collection
      await _firestore.collection('LeaveCount').doc(employeeId).set({
        'fromDate': fromDate,
        'count': FieldValue.increment(1), // Increment count
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error applying leave: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> fetchAcceptedLeaveDetails(
      String employeeId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('leave')
          .doc('accept')
          .collection(employeeId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching accepted leave details: $e');
      throw e;
    }
  }

  Widget _buildLabelWithStar(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(color: Colors.black),
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveDetails() {
    if (leaveDetails == null) {
      return Container(); // Empty container if no leave details found
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Employee ID: ${leaveDetails!['employeeId']}'),
          Text('Leave Type: ${leaveDetails!['leaveType']}'),
          Text(
              'From Date: ${dateFormat.format((leaveDetails!['fromDate'] as Timestamp).toDate())}'),
          Text(
              'To Date: ${dateFormat.format((leaveDetails!['toDate'] as Timestamp).toDate())}'),
          Text('Number of Days: ${leaveDetails!['numberOfDays']}'),
          Text('Leave Reason: ${leaveDetails!['leaveReason']}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Application'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: employeeIdSearchController,
              decoration: InputDecoration(
                labelText: 'Search Employee ID',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () async {
                    if (employeeIdSearchController.text.isNotEmpty) {
                      try {
                        Map<String, dynamic>? details =
                            await fetchAcceptedLeaveDetails(
                          employeeIdSearchController.text,
                        );
                        setState(() {
                          leaveDetails = details;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('Failed to fetch leave details: $e')));
                      }
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20.0),
            if (leaveDetails != null) ...[
              _buildLeaveDetails(),
            ],
            if (leaveDetails == null) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: employeeIdController,
                      decoration: InputDecoration(
                          label: _buildLabelWithStar('Employee ID')),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an employee ID';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.0),
                    DropdownButtonFormField(
                      value: selectedLeaveType,
                      items: leaveTypes.map((String type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLeaveType = value.toString();
                          if (selectedLeaveType == 'Partial Leave') {
                            numberOfDaysController.text = '0.5';
                            fromDateController.text = '';
                            toDateController.text = '';
                          } else {
                            numberOfDaysController.text = '0';
                          }
                        });
                      },
                      decoration: InputDecoration(
                          label: _buildLabelWithStar('Leave Type')),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a leave type';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.0),
                    if (selectedLeaveType != 'Partial Leave') ...[
                      TextFormField(
                        controller: fromDateController,
                        decoration: InputDecoration(
                            label: _buildLabelWithStar('From Date')),
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate:
                                DateTime.now().subtract(Duration(days: 365)),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              fromDateController.text =
                                  dateFormat.format(pickedDate);
                              calculateDays();
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a from date';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12.0),
                      TextFormField(
                        controller: toDateController,
                        decoration: InputDecoration(
                            label: _buildLabelWithStar('To Date')),
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate:
                                DateTime.now().subtract(Duration(days: 365)),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              toDateController.text =
                                  dateFormat.format(pickedDate);
                              calculateDays();
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a to date';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12.0),
                    ],
                    TextFormField(
                      controller: numberOfDaysController,
                      decoration: InputDecoration(labelText: 'Number of Days'),
                      readOnly: true,
                    ),
                    SizedBox(height: 12.0),
                    TextFormField(
                      controller: leaveReasonController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(labelText: 'Leave Reason'),
                    ),
                    SizedBox(height: 12.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            try {
                              await applyLeave(
                                employeeId: employeeIdController.text,
                                leaveType: selectedLeaveType,
                                fromDate: selectedLeaveType == 'Partial Leave'
                                    ? null
                                    : dateFormat.parse(fromDateController.text),
                                toDate: selectedLeaveType == 'Partial Leave'
                                    ? null
                                    : dateFormat.parse(toDateController.text),
                                numberOfDays:
                                    double.parse(numberOfDaysController.text),
                                leaveReason: leaveReasonController.text,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Leave applied successfully')));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Failed to apply leave: $e')));
                            }
                          }
                        },
                        child: Text('Apply'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(120, 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(
      home: ApplyLeavePage(),
    ));
