import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registered_service.dart';
import 'services/reject_service.dart';
import 'employee_id_generator.dart';

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
  final _formKey = GlobalKey<FormState>();
  final EmployeeIdGenerator _idGenerator = EmployeeIdGenerator();
  TextEditingController _joiningDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    employeeData = Map<String, dynamic>.from(widget.employeeData);
    _joiningDateController.text = employeeData['joiningDate'] ?? '';
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Generate a new employee ID
        final employeeId = await _idGenerator.generateEmployeeId();
        employeeData['employeeId'] = employeeId;

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
  }

  void _acceptDetails() {
    setState(() {
      isAccepted = true;
      isEditing = true;
      employeeData['status'] = 'Active';
      employeeData['role'] = 'Standard';
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateAadharNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'Enter a valid 12-digit Aadhar number';
    }
    return null;
  }

  String? _validatePanNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
      return 'Enter a valid PAN number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'minimum length 6';
    }
    if (!RegExp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
        .hasMatch(value)) {
      return 'uppercase,lowercase,num,special character.';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    DateTime dob = DateTime.parse(value);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    if (age < 18) {
      return 'Age must be at least 18 years';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = employeeData['joiningDate'] != null
        ? DateTime.parse(employeeData['joiningDate'])
        : DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        _joiningDateController.text = picked.toIso8601String().split('T')[0];
        employeeData['joiningDate'] = _joiningDateController.text;
      });
    }
  }

  Widget _buildDetailRow(String label, String key,
      {bool isNumber = false,
      bool isEmail = false,
      String? Function(String?)? validator}) {
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
                ? TextFormField(
                    controller:
                        TextEditingController(text: employeeData[key] ?? ''),
                    onChanged: (newValue) {
                      employeeData[key] = newValue;
                    },
                    keyboardType: isNumber
                        ? TextInputType.number
                        : isEmail
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                    validator: validator,
                  )
                : Text(employeeData[key] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, String key, List<String> options) {
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
                ? DropdownButtonFormField<String>(
                    value: employeeData[key],
                    onChanged: (String? newValue) {
                      setState(() {
                        employeeData[key] = newValue!;
                      });
                    },
                    items:
                        options.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    validator: (value) {
                      // Remove mandatory validation for dropdowns
                      return null;
                    },
                  )
                : Text(employeeData[key] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop(); // Close the details page
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            _buildCategory(
              'Personal Information',
              [
                _buildDetailRow('First Name', 'firstName', validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                }),
                _buildDetailRow('Middle Name', 'middleName'),
                _buildDetailRow('Last Name', 'lastName', validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                }),
                _buildDetailRow('Email', 'email',
                    isEmail: true, validator: _validateEmail),
                _buildDetailRow('Phone Number', 'phoneNo',
                    isNumber: true, validator: _validatePhoneNumber),
                _buildDetailRow('Date of Birth', 'dob',
                    validator: _validateDateOfBirth),
                _buildDetailRow('Permanent Address', 'permanentAddress',
                    validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Permanent address is required';
                  }
                  return null;
                }),
                _buildDetailRow('Residential Address', 'residentialAddress',
                    validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Residential address is required';
                  }
                  return null;
                }),
                _buildDetailRow('Aadhar Number', 'aadharNo',
                    validator: _validateAadharNumber),
                _buildDetailRow('PAN Number', 'panNo',
                    validator: _validatePanNumber),
                _buildDetailRow('DP Image URL', 'dpImageUrl'),
                _buildDetailRow('Aadhar Image URL', 'aadharImageUrl'),
                _buildDetailRow('Support URL', 'supportUrl'),
              ],
            ),
            _buildCategory('Job Description', [
              _buildDropdownRow('Department', 'department', [
                'Sales',
                'Services',
                'Spares',
                'Administration',
                'Board of Directors'
              ]),
              _buildDropdownRow('Designation', 'designation', [
                'Manager',
                'Senior Engineer',
                'Junior Engineer',
                'Technician',
                'Executive'
              ]),
              _buildDropdownRow(
                  'Employee Type', 'employeeType', ['On-site', 'Off-site']),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Joining Date: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: isEditing
                          ? TextFormField(
                              controller: _joiningDateController,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Joining date is required';
                                }
                                return null;
                              },
                            )
                          : Text(employeeData['joiningDate'] ?? ''),
                    ),
                  ],
                ),
              ),
              _buildDropdownRow(
                  'Location', 'location', ['Jaypore', 'Berhampur', 'Raigada']),
            ]),
            _buildCategory('Bank Details', [
              _buildDetailRow('Bank Name', 'bankName'),
              _buildDetailRow('Account Number', 'accountNumber',
                  isNumber: true),
              _buildDetailRow('IFSC Code', 'ifscCode'),
            ]),
            _buildCategory('Employee Status', [
              _buildDropdownRow('Status', 'status', [
                'Active',
                'Inactive',
                'On Hold',
              ]),
              _buildDropdownRow('Role', 'role', ['Standard', 'HR']),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
              child:
                  Text(isAccepted ? (isEditing ? 'Save' : 'Edit') : 'Accept'),
            ),
          ],
        ),
      ),
    );
  }
}
