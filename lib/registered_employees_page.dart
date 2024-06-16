// registered employees button
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisteredEmployeesPage extends StatefulWidget {
  @override
  _RegisteredEmployeesPageState createState() =>
      _RegisteredEmployeesPageState();
}

class _RegisteredEmployeesPageState extends State<RegisteredEmployeesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registered Employees'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Regemp').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No registered employees found'));
          }

          final employees = snapshot.data!.docs;
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final data = employees[index].data() as Map<String, dynamic>;
              return EmployeeCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmployeeCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30.0,
                  backgroundColor: Colors.purple[100],
                  child: Text(
                    '${data['firstName'][0]}${data['lastName'][0]}',
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${data['firstName']} ${data['lastName']}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text('Phone: ${data['phoneNo']}'),
                    Text('Email: ${data['email']}'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return EmployeeDetailsDialog(data: data);
                      },
                    );
                  },
                  child: Text(
                    'View More',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const EmployeeDetailsDialog({Key? key, required this.data}) : super(key: key);

  @override
  _EmployeeDetailsDialogState createState() => _EmployeeDetailsDialogState();
}

class _EmployeeDetailsDialogState extends State<EmployeeDetailsDialog> {
  bool _isEditing = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _panController;
  late TextEditingController _passwordController;
  late TextEditingController _permanentAddressController;
  late TextEditingController _residentialAddressController;
  late TextEditingController _dobController;
  late TextEditingController _dpImageUrlController;
  late TextEditingController _supportUrlController;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.data['firstName']);
    _lastNameController = TextEditingController(text: widget.data['lastName']);
    _phoneController = TextEditingController(text: widget.data['phoneNo']);
    _emailController = TextEditingController(text: widget.data['email']);
    _panController = TextEditingController(text: widget.data['panNo']);
    _passwordController = TextEditingController(text: widget.data['password']);
    _permanentAddressController =
        TextEditingController(text: widget.data['permanentAddress']);
    _residentialAddressController =
        TextEditingController(text: widget.data['residentialAddress']);
    _dobController = TextEditingController(text: widget.data['dob']);
    _dpImageUrlController =
        TextEditingController(text: widget.data['dpImageUrl']);
    _supportUrlController =
        TextEditingController(text: widget.data['supportUrl']);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _panController.dispose();
    _passwordController.dispose();
    _permanentAddressController.dispose();
    _residentialAddressController.dispose();
    _dobController.dispose();
    _dpImageUrlController.dispose();
    _supportUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Employee Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildDetailRow('First Name', _firstNameController.text),
            _buildDetailRow('Last Name', _lastNameController.text),
            _buildDetailRow('Phone', _phoneController.text),
            _buildDetailRow('Email', _emailController.text),
            _buildDetailRow('PAN Number', _panController.text),
            _buildDetailRow('Password', _passwordController.text),
            _buildDetailRow(
                'Permanent Address', _permanentAddressController.text),
            _buildDetailRow(
                'Residential Address', _residentialAddressController.text),
            _buildDetailRow('Date of Birth', _dobController.text),
            _buildDetailRow('Profile Picture', _dpImageUrlController.text),
            _buildDetailRow('Support URL', _supportUrlController.text),
          ],
        ),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
              child: Text(_isEditing ? 'Save' : 'Edit'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save changes to Firestore
                await _saveChanges();
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 120.0, child: Text('$label:')),
          SizedBox(width: 8.0),
          Expanded(
            child: _isEditing
                ? TextFormField(
                    controller: _getController(label),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  TextEditingController _getController(String label) {
    switch (label) {
      case 'First Name':
        return _firstNameController;
      case 'Last Name':
        return _lastNameController;
      case 'Phone':
        return _phoneController;
      case 'Email':
        return _emailController;
      case 'PAN Number':
        return _panController;
      case 'Password':
        return _passwordController;
      case 'Permanent Address':
        return _permanentAddressController;
      case 'Residential Address':
        return _residentialAddressController;
      case 'Date of Birth':
        return _dobController;
      case 'Profile Picture':
        return _dpImageUrlController;
      case 'Support URL':
        return _supportUrlController;
      default:
        throw Exception('Invalid label: $label');
    }
  }

  Future<void> _saveChanges() async {
    // Construct updated data map
    Map<String, dynamic> updatedData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'phoneNo': _phoneController.text,
      'email': _emailController.text,
      'panNo': _panController.text,
      'password': _passwordController.text,
      'permanentAddress': _permanentAddressController.text,
      'residentialAddress': _residentialAddressController.text,
      'dob': _dobController.text,
      'dpImageUrl': _dpImageUrlController.text,
      'supportUrl': _supportUrlController.text,
    };

    // Get the document reference based on email
    DocumentReference documentReference = FirebaseFirestore.instance
        .collection('Regemp')
        .doc(widget.data['email']);

    // Update the document in Firestore
    await documentReference.update(updatedData);

    // Show success message or handle accordingly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Changes saved successfully')),
    );
  }
}
