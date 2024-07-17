import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
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
    _fetchEmployeeLeaveDates();
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

  Future<void> searchLeaveRequests() async {
    try {
      DateTime? fromDate = fromDateController.text.isNotEmpty
          ? dateFormat.parse(fromDateController.text)
          : null;
      DateTime? toDate = toDateController.text.isNotEmpty
          ? dateFormat.parse(toDateController.text)
          : null;

      // Fetch leave requests for the specific employeeId within the date range
      List<Map<String, dynamic>> leaveRequests =
          await _leaveService.fetchLeaveRequests(
        employeeId: widget.employeeId!,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Display the filtered leave requests in debug console
      print('Filtered Leave Requests: $leaveRequests');

      // Optionally, you can display the leave requests in UI as needed
      // For simplicity, let's print them in the debug console
      setState(() {
        _filteredLeaveRequests = leaveRequests;
      });
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

  List<Map<String, dynamic>> _filteredLeaveRequests = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _employeeLeaveDates = {};

  Future<void> _fetchEmployeeLeaveDates() async {
    try {
      List<Map<String, dynamic>> leaveRequests =
          await _leaveService.fetchLeaveRequests(
        employeeId: widget.employeeId!,
      );

      Set<DateTime> leaveDates = {};
      for (var request in leaveRequests) {
        DateTime fromDate = (request['fromDate'] as Timestamp).toDate();
        DateTime toDate = (request['toDate'] as Timestamp).toDate();
        for (DateTime date = fromDate;
            date.isBefore(toDate) || date.isAtSameMomentAs(toDate);
            date = date.add(Duration(days: 1))) {
          leaveDates.add(date);
        }
      }

      print('Leave Dates: $leaveDates'); // Debug statement

      setState(() {
        _employeeLeaveDates = leaveDates;
      });
    } catch (e) {
      print('Error fetching leave dates: $e');
    }
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
              SizedBox(height: 20.0), // Added space before search button
              Center(
                // Centered Search Button
                child: ElevatedButton(
                  onPressed: () async {
                    await searchLeaveRequests();
                  },
                  child: Text('Search'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(120, 40), // Adjusted button size
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              if (_filteredLeaveRequests.isNotEmpty)
                ..._filteredLeaveRequests.map((leaveRequest) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${leaveRequest['employeeId']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text('${leaveRequest['leaveReason']}'),
                                SizedBox(height: 4.0),
                                Text(
                                  '${dateFormat.format((leaveRequest['fromDate'] as Timestamp).toDate())} - ${dateFormat.format((leaveRequest['toDate'] as Timestamp).toDate())}',
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('${leaveRequest['leaveType']}'),
                              SizedBox(height: 4.0),
                              Text('${leaveRequest['numberOfDays']} days'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              if (_filteredLeaveRequests.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      'Please select the date range to see the leave history',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
              TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay =
                        focusedDay; // update `_focusedDay` here as well
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    bool isOnLeave = _employeeLeaveDates.any((leaveDate) =>
                        leaveDate.year == day.year &&
                        leaveDate.month == day.month &&
                        leaveDate.day == day.day);
                    if (isOnLeave) {
                      return Container(
                        margin: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false, // Hide the 2 weeks button
                  titleCentered: true, // Center the title
                  formatButtonShowsNext: false,
                ),
              )
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
