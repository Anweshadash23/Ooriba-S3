import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ooriba/employee_signup_success.dart';
import 'package:ooriba/services/add_employee_service.dart';
import 'dart:io';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  _AddEmployeePageState createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dob;
  final _phoneNumber = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _panNo = TextEditingController();
  final _residentialAddress = TextEditingController();
  final _permanentAddress = TextEditingController();
  final _aadharNo = TextEditingController();
  File? dpImage, supportImage, adhaarImage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AddEmployeeService _employeeService = AddEmployeeService();

  Future<void> _pickImage(int x) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (x == 2) {
          dpImage = File(pickedFile.path);
        }
        if (x == 1) {
          adhaarImage = File(pickedFile.path);
        }
        if (x == 3) {
          supportImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<User?> _createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user: $e')),
      );
      return null;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final firstName = _firstName.text;
      final middleName = _middleName.text;
      final lastName = _lastName.text;
      final email = _email.text.isNotEmpty ? _email.text : null;
      final password = _password.text;
      var panNo = _panNo.text.isNotEmpty ? _panNo.text.toUpperCase() : null;
      final resAdd = _residentialAddress.text;
      final perAdd = _permanentAddress.text;
      final phoneNumber = _phoneNumber.text;
      final dob = DateFormat('dd/MM/yyyy').format(_dob!);
      var aadharNo = _aadharNo.text.replaceAll(' ', '');

      try {
        // Create user in Firebase Authentication
        final User? user =
            await _createUserWithEmailAndPassword(email!, password);

        if (user != null) {
          // Add employee data to Firestore
          await _employeeService.addEmployee(
            firstName,
            middleName,
            lastName,
            email,
            panNo,
            resAdd,
            perAdd,
            phoneNumber,
            dob,
            aadharNo,
            password,
            dpImage,
            adhaarImage,
            supportImage,
            context,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Failed to create user in Firebase Authentication')),
          );
        }
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add employee: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out the form correctly')),
      );
    }
  }

  Widget _buildMandatoryText(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(color: Colors.black),
        ),
        const Text(
          '*',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Add Employee',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      LabelWithStar(label: 'First Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          if (value.length > 50) {
                            return 'First name cannot exceed 50 characters';
                          }
                          if (RegExp(r'[^a-zA-Z.\s]').hasMatch(value)) {
                            return 'First name can only contain letters and dot(.)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _middleName,
                        decoration: const InputDecoration(
                          labelText: 'Middle Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value!.length > 50) {
                            return 'Middle name cannot exceed 50 characters';
                          }
                          if (RegExp(r'[^a-zA-Z.\s]').hasMatch(value)) {
                            return 'Middle name can only contain letters and dot(.)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabelWithStar(label: 'Last Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          if (value.length > 50) {
                            return 'Last name cannot exceed 50 characters';
                          }
                          if (RegExp(r'[^a-zA-Z.\s]').hasMatch(value)) {
                            return 'Last name can only contain letters and dot(.)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(
                                    r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabelWithStar(label: 'Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$')
                              .hasMatch(value)) {
                            return 'Password must contain an uppercase letter, a number, and a special character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabelWithStar(label: 'Phone Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneNumber,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length != 10) {
                            return 'Phone number must be exactly 10 digits';
                          }
                          if (RegExp(r'[^0-9]').hasMatch(value)) {
                            return 'Phone number can only contain digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabelWithStar(label: 'Residential Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _residentialAddress,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your residential address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabelWithStar(label: 'Permanent Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _permanentAddress,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your permanent address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              _dob = selectedDate;
                            });
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabelWithStar(label: 'Date of Birth'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _dob == null
                                        ? 'Date of Birth'
                                        : DateFormat('dd/MM/yyyy')
                                            .format(_dob!),
                                    style: TextStyle(
                                      color: _dob == null
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _panNo,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length != 10) {
                              return 'PAN number must be exactly 10 characters';
                            }
                            if (RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
                              return 'PAN number can only contain letters and digits';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabelWithStar(label: 'Aadhaar Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _aadharNo,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Aadhaar number';
                          }
                          if (value.length != 12 &&
                              value.replaceAll(' ', '').length != 12) {
                            return 'Aadhaar number must be exactly 12 digits';
                          }
                          if (RegExp(r'[^0-9]').hasMatch(value)) {
                            return 'Aadhaar number can only contain digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => _pickImage(1),
                        child: const Text('Upload Aadhaar Image'),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => _pickImage(2),
                        child: const Text('Upload Profile Picture'),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => _pickImage(3),
                        child: const Text('Upload Supporting Document'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LabelWithStar extends StatelessWidget {
  final String label;
  const LabelWithStar({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black),
        ),
        const Text(
          '*',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      ],
    );
  }
}
