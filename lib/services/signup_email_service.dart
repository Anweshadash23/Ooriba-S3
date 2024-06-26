import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpEmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getEmployeeDetails(String email) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('Employee').doc(email).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        throw Exception('No employee found with this email.');
      }
    } catch (e) {
      throw Exception('Failed to fetch employee details: $e');
    }
  }

  Future<void> sendSignUpEmail(String email) async {
    final employeeData = await getEmployeeDetails(email);

    const serviceId = 'service_z0soilk';
    const templateId = 'template_q66bo0j';
    const userId = 'ylxnV-iUDuMz0I74O';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'firstName': employeeData['firstName'],
            'lastName': employeeData['lastName'],
            'email': employeeData['email'],
            'to_email': 'anweshadash423@gmail.com',
            'reply_to': 'anweshadash04@gmail.com',
            // 'dob': employeeData['dob'],
          },
        }));

    if (response.statusCode != 200) {
      throw Exception('Failed to send sign up email: ${response.body}');
    }
  }
}
