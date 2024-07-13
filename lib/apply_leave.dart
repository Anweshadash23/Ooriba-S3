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

  List<Map<String, dynamic>> searchResults = [];
  bool showSearchResults = false;

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

  // Future<Map<String, dynamic>?> fetchAcceptedLeaveDetails(
  //     String employeeId) async {
  //   try {
  //     if (employeeId.isEmpty) {
  //       return null; // Handle empty employeeId case
  //     }

  //     QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
  //         .collection('leave')
  //         .doc('accept')
  //         .collection(employeeId)
  //         .get();

  //     if (querySnapshot.docs.isNotEmpty) {
  //       return querySnapshot.docs.first.data();
  //     } else {
  //       return null;
  //     }
  //   } catch (e) {
  //     print('Error fetching accepted leave details: $e');
  //     throw e;
  //   }
  // }

  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('Regemp')
          .where('firstName', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('firstName',
              isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .get();

      List<Map<String, dynamic>> employees =
          querySnapshot.docs.map((doc) => doc.data()).toList();

      if (employees.isEmpty) {
        querySnapshot = await _firestore
            .collection('Regemp')
            .where('lastName', isGreaterThanOrEqualTo: query.toLowerCase())
            .where('lastName',
                isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
            .get();

        employees = querySnapshot.docs.map((doc) => doc.data()).toList();
      }

      if (employees.isEmpty) {
        querySnapshot = await _firestore
            .collection('Regemp')
            .where('employeeId', isEqualTo: query.toUpperCase())
            .get();

        employees = querySnapshot.docs.map((doc) => doc.data()).toList();
      }

      return employees;
    } catch (e) {
      print('Error searching employees: $e');
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

  Widget _buildSearchResults() {
    if (!showSearchResults) return Container();

    return Column(
      children: searchResults.map((result) {
        String fullName = '${result['firstName']} ${result['lastName']}';
        String employeeId = result['employeeId'];

        return ListTile(
          title: Text(fullName),
          subtitle: Text(employeeId),
          onTap: () {
            setState(() {
              employeeIdController.text = employeeId;
              showSearchResults = false;
              searchResults = [];
            });
          },
        );
      }).toList(),
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
                labelText: 'Search Employee ID or Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () async {
                    if (employeeIdSearchController.text.isNotEmpty) {
                      try {
                        List<Map<String, dynamic>> results =
                            await searchEmployees(
                                employeeIdSearchController.text);
                        setState(() {
                          searchResults = results;
                          showSearchResults = true;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('Failed to fetch search results: $e')));
                      }
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20.0),
            _buildSearchResults(),
            if (!showSearchResults) ...[
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
                    TextFormField(
                      controller: fromDateController,
                      decoration: InputDecoration(
                        label: _buildLabelWithStar('From Date'),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                fromDateController.text =
                                    dateFormat.format(pickedDate);
                                calculateDays();
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a from date';
                        }
                        return null;
                      },
                      readOnly: true,
                    ),
                    SizedBox(height: 12.0),
                    if (selectedLeaveType != 'Partial Leave')
                      TextFormField(
                        controller: toDateController,
                        decoration: InputDecoration(
                          label: _buildLabelWithStar('To Date'),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  toDateController.text =
                                      dateFormat.format(pickedDate);
                                  calculateDays();
                                });
                              }
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a to date';
                          }
                          return null;
                        },
                        readOnly: true,
                      ),
                    SizedBox(height: 12.0),
                    TextFormField(
                      controller: numberOfDaysController,
                      decoration: InputDecoration(
                        label: _buildLabelWithStar('Number of Days'),
                        suffixIcon: Icon(Icons.event_note),
                      ),
                      readOnly: true,
                    ),
                    SizedBox(height: 12.0),
                    TextFormField(
                      controller: leaveReasonController,
                      decoration: InputDecoration(label: Text('Leave Reason')),
                    ),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            DateTime fromDate =
                                dateFormat.parse(fromDateController.text);
                            DateTime? toDate;
                            if (toDateController.text.isNotEmpty) {
                              toDate = dateFormat.parse(toDateController.text);
                            }

                            await applyLeave(
                              employeeId: employeeIdController.text,
                              leaveType: selectedLeaveType,
                              fromDate: fromDate,
                              toDate: toDate,
                              numberOfDays:
                                  double.parse(numberOfDaysController.text),
                              leaveReason: leaveReasonController.text,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Leave applied successfully')));

                            // Clear form fields
                            employeeIdController.clear();
                            fromDateController.clear();
                            toDateController.clear();
                            leaveReasonController.clear();
                            numberOfDaysController.text = '0';

                            setState(() {
                              leaveDetails =
                                  null; // Clear previous leave details
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Failed to apply leave: $e')));
                          }
                        }
                      },
                      child: Text('Apply Leave'),
                    ),
                    // SizedBox(height: 20.0),
                    // FutureBuilder<Map<String, dynamic>?>(
                    //   future:
                    //       fetchAcceptedLeaveDetails(employeeIdController.text),
                    //   builder: (context, snapshot) {
                    //     if (snapshot.connectionState ==
                    //         ConnectionState.waiting) {
                    //       return CircularProgressIndicator();
                    //     }
                    //     if (snapshot.hasError) {
                    //       return Text('Error: ${snapshot.error}');
                    //     }
                    //     if (snapshot.hasData && snapshot.data != null) {
                    //       leaveDetails = snapshot.data!;
                    //       return _buildLeaveDetails();
                    //     } else {
                    //       return Text('No accepted leave details found.');
                    //     }
                    //   },
                    // ),
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
