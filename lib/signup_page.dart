import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ooriba/services/employeeService.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dob;
  final _phoneNumber = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _panNo = TextEditingController();
  final _residentialAddress = TextEditingController();
  final _permanentAddress = TextEditingController();
  final _password = TextEditingController();
  File? dpImage, supportImage, adhaarImage;
  final EmployeeService _employeeService = EmployeeService();

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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final firstName = _firstName.text;
      final middleName = _middleName.text;
      final lastName = _lastName.text;
      final email = _email.text;
      final password = _password.text;
      final panNo = _panNo.text;
      final resAdd = _residentialAddress.text;
      final perAdd = _permanentAddress.text;
      final phoneNo = _phoneNumber.text;
      final dob = DateFormat.yMd().format(_dob!);

      // Ensure all images are selected
      if (dpImage == null || adhaarImage == null || supportImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload all required images')),
        );
        return;
      }

      await _employeeService.addEmployee(
        firstName,
        middleName,
        lastName,
        email,
        password,
        panNo,
        resAdd,
        perAdd,
        phoneNo,
        dob,
        dpImage!,
        adhaarImage!,
        supportImage!,
        context: context,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signed up successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400, // Limit the width for larger screens
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
                        'Sign Up',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
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
                      const SizedBox(height: 20),
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
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
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
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                                  r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!RegExp(
                                  r'^(?=.*[A-Z])(?=.*[!@#$&*])(?=.*[0-9]).{8,}$')
                              .hasMatch(value)) {
                            return 'Password must contain at least one uppercase letter, one symbol, and one number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneNumber,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Phone number must be exactly 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            final age = DateTime.now().year - pickedDate.year;
                            if (age < 18) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'You must be at least 18 years old')),
                              );
                              return;
                            }
                            setState(() {
                              _dob = pickedDate;
                            });
                          }
                        },
                        controller: TextEditingController(
                          text: _dob != null
                              ? "${_dob!.day}/${_dob!.month}/${_dob!.year}"
                              : '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your date of birth';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _panNo,
                        decoration: const InputDecoration(
                          labelText: 'Pan Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your PAN number';
                          }
                          if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid PAN number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _residentialAddress,
                        decoration: const InputDecoration(
                          labelText: 'Residential Address',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your residential address';
                          }
                          if (value.length > 100) {
                            return 'Residential address cannot exceed 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _permanentAddress,
                        decoration: const InputDecoration(
                          labelText: 'Permanent Address',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your permanent address';
                          }
                          if (value.length > 100) {
                            return 'Permanent address cannot exceed 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _pickImage(1),
                        child: const Text('Upload Adhaar Card Copy'),
                      ),
                      adhaarImage == null
                          ? const Text('No Adhaar Card Copy Uploaded.')
                          : Image.file(adhaarImage!, height: 100, width: 100),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _pickImage(2),
                        child: const Text('Upload Profile Picture'),
                      ),
                      dpImage == null
                          ? const Text('No profile picture selected.')
                          : Image.file(dpImage!, height: 100, width: 100),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _pickImage(3),
                        child: const Text('Upload Supporting Document'),
                      ),
                      supportImage == null
                          ? const Text('No Document selected.')
                          : Image.file(supportImage!, height: 100, width: 100),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Sign Up'),
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
