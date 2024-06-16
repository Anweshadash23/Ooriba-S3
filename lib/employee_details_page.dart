import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ooriba/registered_service.dart';
import 'package:ooriba/services/reject_service.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> employeeData;

  EmployeeDetailsPage({required this.employeeData});

  @override
  _EmployeeDetailsPageState createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  late Map<String, dynamic> employeeData;
  bool isEditing = false;
  bool isAccepted = false;
  final RegisteredService _registeredService = RegisteredService();
  final RejectService _rejectService = RejectService();

  @override
  void initState() {
    super.initState();
    employeeData = Map<String, dynamic>.from(widget.employeeData);
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _saveDetails() async {
    try {
      print('Saving data: ${employeeData['email']} -> $employeeData');
      await FirebaseFirestore.instance
          .collection('Regemp')
          .doc(employeeData['email'])
          .set(employeeData);

      // Delete the employee from the "Employee" collection
      await FirebaseFirestore.instance
          .collection('Employee')
          .doc(employeeData['email'])
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Employee details updated and deleted from the Employee collection successfully')),
      );
      setState(() {
        isEditing = false;
      });
    } catch (e) {
      print('Error saving employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update employee details: $e')),
      );
    }
  }

  void _acceptDetails() {
    setState(() {
      isAccepted = true;
      isEditing = true;
    });
  }

  Future<void> _showRejectPopup() async {
    String? reason;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must fill the reason and press a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reject Reason'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                  'Please provide a reason for rejecting the employee details:'),
              TextField(
                onChanged: (value) {
                  reason = value;
                },
                decoration: InputDecoration(
                  labelText: 'Reason',
                  errorText: reason == null || reason!.isEmpty
                      ? 'Reason is required'
                      : null,
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () async {
                if (reason != null && reason!.isNotEmpty) {
                  try {
                    await _rejectService.rejectEmployee(employeeData, reason!);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Employee details rejected and saved successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Failed to reject employee details: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _rejectChanges() async {
    await _showRejectPopup();
    setState(() {
      isEditing = false;
      employeeData = Map<String, dynamic>.from(widget.employeeData);
    });
    print('Changes rejected');
  }

  Widget _buildDetailRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: isEditing
                ? TextField(
                    controller:
                        TextEditingController(text: employeeData[key] ?? ''),
                    onChanged: (newValue) {
                      employeeData[key] = newValue;
                    },
                  )
                : Text(employeeData[key] ?? ''),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${employeeData['firstName']} ${employeeData['lastName']}'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveDetails,
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildDetailRow('First Name', 'firstName'),
                    _buildDetailRow('Middle Name', 'middleName'),
                    _buildDetailRow('Last Name', 'lastName'),
                    _buildDetailRow('Email', 'email'),
                    _buildDetailRow('Phone Number', 'phoneNo'),
                    _buildDetailRow('Date of Birth', 'dob'),
                    _buildDetailRow('Permanent Address', 'permanentAddress'),
                    _buildDetailRow(
                        'Residential Address', 'residentialAddress'),
                    _buildDetailRow('Adhaar URL', 'adhaarUrl'),
                    _buildDetailRow('DP Image URL', 'dpImageUrl'),
                    _buildDetailRow('Support URL', 'supportUrl'),
                    // New fields
                    _buildDetailRow('Department', 'department'),
                    _buildDetailRow('Designation', 'designation'),
                    _buildDetailRow('Employee Type', 'employeeType'),
                    _buildDetailRow('Joining Date', 'joiningDate'),
                    _buildDetailRow('Relocation Amount', 'relocationAmount'),
                    _buildDetailRow('Bank Name', 'bankName'),
                    _buildDetailRow('Account Number', 'accountNumber'),
                    _buildDetailRow('IFSC Code', 'ifscCode'),
                    _buildDetailRow('Location', 'location'),
                    // Add more details as needed
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: _rejectChanges,
                  child: Text('Reject'),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: isAccepted
                      ? (isEditing ? _saveDetails : _toggleEdit)
                      : _acceptDetails,
                  child: Text(
                      isAccepted ? (isEditing ? 'Save' : 'Edit') : 'Accept'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
