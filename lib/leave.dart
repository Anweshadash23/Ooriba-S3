import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/leave_service.dart'; // Import the leave service

class LeavePage extends StatefulWidget {
  final String? employeeId;

  const LeavePage({super.key, required this.employeeId});
  @override
  _LeavePageState createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final _formKey = GlobalKey<FormState>();
  late String empid;
  final LeaveService _leaveService =
      LeaveService(); // Instantiate the leave service

  List<String> leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Earned Leave',
    'Partial Leave'
  ];
  String selectedLeaveType = 'Sick Leave'; // Default value

  TextEditingController employeeIdController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  TextEditingController leaveReasonController = TextEditingController();
  TextEditingController numberOfDaysController = TextEditingController();

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

  void fetchLeaveRequests() async {
    try {
      // Fetch all leave requests for the current employeeId
      List<Map<String, dynamic>> leaveRequests =
          await _leaveService.fetchAllLeaveRequests();

      // Display the fetched leave requests in debug console
      print('Fetched Leave Requests: $leaveRequests');

      // Optionally, you can display the leave requests in UI as needed
      // For simplicity, let's print them in the debug console
    } catch (e) {
      print('Error fetching leave requests: $e');
      // Handle error as needed
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Application'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0), // Reduced padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: TextEditingController(text: widget.employeeId),
                decoration:
                    InputDecoration(label: _buildLabelWithStar('Employee ID')),
                enabled: false,
              ),

              SizedBox(height: 12.0), // Reduced spacing
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
                decoration:
                    InputDecoration(label: _buildLabelWithStar('Leave Type')),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a leave type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.0), // Reduced spacing
              if (selectedLeaveType != 'Partial Leave') ...[
                TextFormField(
                  controller: fromDateController,
                  decoration:
                      InputDecoration(label: _buildLabelWithStar('From Date')),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        fromDateController.text = dateFormat.format(pickedDate);
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
                SizedBox(height: 12.0), // Reduced spacing
                TextFormField(
                  controller: toDateController,
                  decoration:
                      InputDecoration(label: _buildLabelWithStar('To Date')),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        toDateController.text = dateFormat.format(pickedDate);
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
                SizedBox(height: 12.0), // Reduced spacing
              ],
              TextFormField(
                controller: numberOfDaysController,
                decoration: InputDecoration(labelText: 'Number of Days'),
                readOnly: true,
              ),
              SizedBox(height: 12.0), // Reduced spacing
              TextFormField(
                controller: leaveReasonController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(labelText: 'Leave Reason'),
              ),
              SizedBox(height: 12.0), // Reduced spacing
              Center(
                // Centered Apply Button
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      try {
                        if (widget.employeeId == null) {
                          empid = "null";
                        } else {
                          empid = widget.employeeId!;
                        }
                        await _leaveService.applyLeave(
                          employeeId: empid,
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Leave applied successfully')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Failed to apply leave: $e')));
                      }
                    }
                  },
                  child: Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(120, 40), // Adjusted button size
                  ),
                ),
              ),
              SizedBox(height: 20.0), // Added space before leave details
              FutureBuilder(
                future: _leaveService.fetchAllLeaveRequests(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No leave requests found.');
                    } else {
                      // Display fetched leave details
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: snapshot.data!.map((leaveRequest) {
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                      'Employee ID: ${leaveRequest['employeeId']}'),
                                  Text(
                                      'Leave Type: ${leaveRequest['leaveType']}'),
                                  Text(
                                      'From Date: ${leaveRequest['fromDate']}'),
                                  Text('To Date: ${leaveRequest['toDate']}'),
                                  Text(
                                      'Number of Days: ${leaveRequest['numberOfDays']}'),
                                  Text(
                                      'Leave Reason: ${leaveRequest['leaveReason']}'),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void main() => runApp(MaterialApp(
        home: LeavePage(employeeId: widget.employeeId),
      ));
}
