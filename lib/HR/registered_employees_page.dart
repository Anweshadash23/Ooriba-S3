import 'dart:io';
import 'package:ooriba/services/admin/retrieveLocation_service.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ooriba/services/admin/department_service.dart';
import 'package:ooriba/services/designation_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class RegisteredEmployeesPage extends StatefulWidget {
  const RegisteredEmployeesPage({super.key});

  @override
  _RegisteredEmployeesPageState createState() =>
      _RegisteredEmployeesPageState();
}

class _RegisteredEmployeesPageState extends State<RegisteredEmployeesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Employees'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Regemp').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No registered employees found'));
          }

          final employees = snapshot.data!.docs;
          final filteredEmployees = employees.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['role'] != 'HR';
          }).toList();

          if (filteredEmployees.isEmpty) {
            return const Center(child: Text('No registered employees found'));
          }

          return ListView.builder(
            itemCount: filteredEmployees.length,
            itemBuilder: (context, index) {
              final data =
                  filteredEmployees[index].data() as Map<String, dynamic>;
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

  const EmployeeCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30.0,
                  backgroundColor: Colors.purple[100],
                  backgroundImage: data['dpImageUrl'] != null &&
                          data['dpImageUrl'].isNotEmpty
                      ? NetworkImage(data['dpImageUrl'])
                      : null,
                  child:
                      data['dpImageUrl'] == null || data['dpImageUrl'].isEmpty
                          ? Text(
                              '${data['firstName'][0]}${data['lastName'][0]}',
                              style: const TextStyle(
                                fontSize: 24.0,
                                color: Colors.white,
                              ),
                            )
                          : null,
                ),
                //   radius: 30.0,
                //   backgroundColor: Colors.purple[100],
                //   child: Text(
                //     '${data['firstName'][0]}${data['lastName'][0]}',
                //     style: TextStyle(
                //       fontSize: 24.0,
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
                const SizedBox(width: 16.0),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${data['firstName']} ${data['lastName']}',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text('Phone: ${data['phoneNo']}'),
                      Text('Email: ${data['email']}'),
                      Text('Employee Type: ${data['employeeType']}'),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16.0),
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
                  child: const Text(
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

  const EmployeeDetailsDialog({super.key, required this.data});

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
  // late TextEditingController _passwordController;
  late TextEditingController _permanentAddressController;
  late TextEditingController _residentialAddressController;
  late TextEditingController _dobController;
  late TextEditingController _dpImageUrlController;
  late TextEditingController _supportUrlController;
  late TextEditingController _aadharNoController;
  late TextEditingController _aadharImageUrlController;
  late TextEditingController _joiningDateController;
  late TextEditingController _employeeIdController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;

  String _selectedDepartment = '';
  String _selectedDesignation = '';
  String _selectedLocation = '';
  String _selectedStatus = '';
  String _selectedRole = '';
  String _selectedEmployeeType = '';

  final Map<String, String> _validationErrors = {};
  final DesignationService _designationService = DesignationService();
  final DepartmentService _departmentService = DepartmentService();
  final LocationService _locationService = LocationService();

  List<String> _departments = [];
  List<String> _designations = [];
  List<String> _locations = [];
  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.data['firstName']);
    _lastNameController = TextEditingController(text: widget.data['lastName']);
    _phoneController = TextEditingController(text: widget.data['phoneNo']);
    _emailController = TextEditingController(text: widget.data['email']);
    _panController = TextEditingController(text: widget.data['panNo']);
    // _passwordController = TextEditingController(text: widget.data['password']);
    _permanentAddressController =
        TextEditingController(text: widget.data['permanentAddress']);
    _residentialAddressController =
        TextEditingController(text: widget.data['residentialAddress']);
    _dobController = TextEditingController(text: widget.data['dob']);
    _dpImageUrlController =
        TextEditingController(text: widget.data['dpImageUrl']);
    _supportUrlController =
        TextEditingController(text: widget.data['supportUrl']);
    _aadharNoController =
        TextEditingController(text: widget.data['aadharNo'] ?? '');
    _aadharImageUrlController =
        TextEditingController(text: widget.data['aadharImageUrl'] ?? '');
    _joiningDateController =
        TextEditingController(text: widget.data['joiningDate']);
    _employeeIdController =
        TextEditingController(text: widget.data['employeeId']);
    _bankNameController = TextEditingController(text: widget.data['bankName']);
    _accountNumberController =
        TextEditingController(text: widget.data['accountNumber']);
    _ifscCodeController = TextEditingController(text: widget.data['ifscCode']);
    _selectedDepartment = widget.data['department'] ?? '';
    _selectedDesignation = widget.data['designation'] ?? '';
    _selectedLocation = widget.data['location'] ?? '';
    _selectedStatus = widget.data['status'] ?? '';
    _selectedRole = widget.data['role'] ?? '';
    _selectedEmployeeType = widget.data['employeeType'] ?? '';

    _fetchData();
  }

  Future<void> _fetchData() async {
    final departments = await _departmentService.getDepartments();
    final designations = await _designationService.getDesignations();
    final locations = await _locationService.getAllLocations();
    setState(() {
      _departments = departments;
      _designations = designations;
      _locations = locations;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _panController.dispose();
    // _passwordController.dispose();
    _permanentAddressController.dispose();
    _residentialAddressController.dispose();
    _dobController.dispose();
    _dpImageUrlController.dispose();
    _supportUrlController.dispose();
    _aadharNoController.dispose();
    _aadharImageUrlController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final pan = _panController.text.trim();
    // final password = _passwordController.text.trim();
    final permanentAddress = _permanentAddressController.text.trim();
    final residentialAddress = _residentialAddressController.text.trim();
    final dob = _dobController.text.trim();
    final aadharNo = _aadharNoController.text.trim();

    _validationErrors.clear();

    // Validate required fields
    if (firstName.isEmpty) {
      _validationErrors['firstName'] = 'First name is required';
    }
    if (lastName.isEmpty) {
      _validationErrors['lastName'] = 'Last name is required';
    }
    if (phone.isEmpty) {
      _validationErrors['phone'] = 'Phone number is required';
    }
    if (permanentAddress.isEmpty) {
      _validationErrors['permanentAddress'] = 'Permanent address is required';
    }
    if (residentialAddress.isEmpty) {
      _validationErrors['residentialAddress'] =
          'Residential address is required';
    }
    if (dob.isEmpty) {
      _validationErrors['dob'] = 'Date of birth is required';
    }

    // Validate email if provided
    if (email.isNotEmpty) {
      String? emailError = _validateEmail(email);
      if (emailError != null) {
        _validationErrors['email'] = emailError;
      }
    }

    // Validate phone number
    if (phone.isNotEmpty) {
      String? phoneError = _validatePhoneNumber(phone);
      if (phoneError != null) {
        _validationErrors['phone'] = phoneError;
      }
    }

    // Validate aadhar number if provided
    if (aadharNo.isNotEmpty) {
      String? aadharError = _validateAadharNumber(aadharNo);
      if (aadharError != null) {
        _validationErrors['aadharNo'] = aadharError;
      }
    }

    // Validate PAN number if provided
    if (pan.isNotEmpty) {
      String? panError = _validatePanNumber(pan);
      if (panError != null) {
        _validationErrors['pan'] = panError;
      }
    }

    // Validate date of birth
    if (dob.isNotEmpty) {
      String? dobError = _validateDateOfBirth(dob);
      if (dobError != null) {
        _validationErrors['dob'] = dobError;
      }
    }

    return _validationErrors.isEmpty;
  }

  String? _validateEmail(String? value) {
    if (value != null &&
        value.isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
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
    if (value != null &&
        value.isNotEmpty &&
        !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
      return 'Enter a valid PAN number';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }

    // Validate format dd/mm/yyyy
    final dateFormat = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateFormat.hasMatch(value)) {
      return 'Enter a valid date format (dd/mm/yyyy)';
    }

    try {
      // Convert to DateTime
      final parts = value.split('/');
      final dob = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      // Validate age
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }

      if (age < 18) {
        return 'Age must be at least 18 years';
      }
    } catch (e) {
      return 'Invalid date';
    }

    return null;
  }

  Future<void> _captureImage(String key) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = path.basename(file.path);
      final destination = 'employee_images/$fileName';

      try {
        final ref = FirebaseStorage.instance.ref(destination);
        await ref.putFile(file);
        final downloadURL = await ref.getDownloadURL();

        setState(() {
          if (key == 'dpImageUrl') {
            _dpImageUrlController.text = downloadURL;
          } else if (key == 'aadharImageUrl') {
            _aadharImageUrlController.text = downloadURL;
          } else if (key == 'supportUrl') {
            _supportUrlController.text = downloadURL;
          }
        });
      } catch (e) {
        // Handle errors
        print('Failed to upload image: $e');
      }
    }
  }

  Future<void> _captureAttachment(String key) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = path.basename(file.path);
      final destination = 'employee_attachments/$fileName';

      try {
        final ref = FirebaseStorage.instance.ref(destination);
        await ref.putFile(file);
        final downloadURL = await ref.getDownloadURL();

        setState(() {
          if (key == 'supportUrl') {
            _supportUrlController.text = downloadURL;
          }
        });
      } catch (e) {
        // Handle errors
        print('Failed to upload attachment: $e');
      }
    }
  }

  Future<void> _downloadImage(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('File downloaded to $filePath');
    } catch (e) {
      print('Failed to download image: $e');
    }
  }

  Widget _buildImageRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 120,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            width: 100, // Fixed width
            height: 100, // Fixed height
            child: _dpImageUrlController.text.isNotEmpty &&
                        key == 'dpImageUrl' ||
                    _aadharImageUrlController.text.isNotEmpty &&
                        key == 'aadharImageUrl'
                ? FadeInImage.assetNetwork(
                    placeholder:
                        'assets/placeholder_image.png', // Placeholder image asset path
                    image: key == 'dpImageUrl'
                        ? _dpImageUrlController.text
                        : _aadharImageUrlController
                            .text, // Image URL from controller
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: ElevatedButton(
                      onPressed: () => _captureImage(key),
                      child: Text('Capture Image'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(30, 40), // Adjust the size as needed
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 120,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            child: _supportUrlController.text.isNotEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () async {
                        final url = _supportUrlController.text;
                        final fileName =
                            url.split('/').last; // Extract file name from URL
                        await _downloadImage(url, fileName); // Download image
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(100, 40), // Adjust the size as needed
                      ),
                      child: Text('Download'),
                    ),
                  )
                : Center(
                    child: ElevatedButton(
                      onPressed: () => _captureAttachment(key),
                      child: Text('Upload Attachment'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(100, 40), // Adjust the size as needed
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildRow('First Name', _firstNameController),
              _buildRow('Last Name', _lastNameController),
              _buildRow('Phone Number', _phoneController),
              _buildRow('Email', _emailController),
              _buildRow('PAN Number', _panController),
              // _buildRow('Password', _passwordController, obscureText: true),
              _buildRow('Permanent Address', _permanentAddressController),
              _buildRow('Residential Address', _residentialAddressController),
              _buildRow('Date of Birth', _dobController),
              const SizedBox(height: 8.0),
              _buildImageRow('Profile Picture', 'dpImageUrl'),
              _buildAttachmentRow('Aadhar Image', 'aadharImageUrl'),
              _buildAttachmentRow('Support Attachment', 'supportUrl'),
              _buildRow('Joining Date', _joiningDateController),
              _buildRow('employeeId', _employeeIdController),
              _buildRow('Bank Name', _bankNameController),
              _buildRow('Account Number', _accountNumberController),
              _buildRow('IFSC Code', _ifscCodeController),
              _buildDropdown('Department', _selectedDepartment, _departments),
              _buildDropdown(
                  'Designation', _selectedDesignation, _designations),
              _buildDropdown('Location', _selectedLocation, _locations),
              _buildDropdown('Status', _selectedStatus, ['Active', 'Inactive']),
              _buildDropdown(
                  'Role', _selectedRole, ['Standard', 'HR', 'SiteManager']),
              _buildDropdown('Employee Type', _selectedEmployeeType,
                  ['On-site', 'Off-site']),
              if (_validationErrors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _validationErrors.entries.map((entry) {
                      return Text(
                        entry.value,
                        style: const TextStyle(color: Colors.red),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      if (_isEditing) {
                        if (_validateInputs()) {
                          // Save the updated data to Firestore
                          FirebaseFirestore.instance
                              .collection('Regemp')
                              .doc(widget.data['id'])
                              .update({
                            'firstName': _firstNameController.text.trim(),
                            'lastName': _lastNameController.text.trim(),
                            'phoneNo': _phoneController.text.trim(),
                            'email': _emailController.text.trim(),
                            'panNo': _panController.text.trim(),
                            // 'password': _passwordController.text.trim(),
                            'permanentAddress':
                                _permanentAddressController.text.trim(),
                            'residentialAddress':
                                _residentialAddressController.text.trim(),
                            'dob': _dobController.text.trim(),
                            'dpImageUrl': _dpImageUrlController.text.trim(),
                            'supportUrl': _supportUrlController.text.trim(),
                            'aadharNo': _aadharNoController.text.trim(),
                            'aadharImageUrl':
                                _aadharImageUrlController.text.trim(),
                            'joiningDate': _joiningDateController.text.trim(),
                            'employeeId': _employeeIdController.text.trim(),
                            'bankName': _bankNameController.text.trim(),
                            'accountNumber':
                                _accountNumberController.text.trim(),
                            'ifscCode': _ifscCodeController.text.trim(),
                            'department': _selectedDepartment,
                            'designation': _selectedDesignation,
                            'location': _selectedLocation,
                            'status': _selectedStatus,
                            'role': _selectedRole,
                            'employeeType': _selectedEmployeeType,
                          }).then((_) {
                            setState(() {
                              _isEditing = false;
                            });
                          }).catchError((error) {
                            // Handle error
                            print('Failed to update employee: $error');
                          });
                        }
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
                    child: Text(
                      _isEditing ? 'Save' : 'Edit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
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

  Widget _buildRow(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: !_isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String label,
    String? errorText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
      ),
    );
  }

  Widget _buildDropdown(
      String label, String selectedValue, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue.isNotEmpty ? selectedValue : null,
            onChanged: _isEditing
                ? (newValue) {
                    setState(() {
                      switch (label) {
                        case 'Department':
                          _selectedDepartment = newValue!;
                          break;
                        case 'Designation':
                          _selectedDesignation = newValue!;
                          break;
                        case 'Location':
                          _selectedLocation = newValue!;
                          break;
                        case 'Status':
                          _selectedStatus = newValue!;
                          break;
                        case 'Role':
                          _selectedRole = newValue!;
                          break;
                        case 'Employee Type':
                          _selectedEmployeeType = newValue!;
                          break;
                      }
                    });
                  }
                : null,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: RegisteredEmployeesPage(),
  ));
}
