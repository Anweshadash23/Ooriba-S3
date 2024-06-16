import 'package:cloud_firestore/cloud_firestore.dart';

class RegisteredService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerEmployee(
      String email, Map<String, dynamic> employeeData) async {
    try {
      // Store in 'Regemp' collection
      await _firestore.collection('Regemp').doc(email).set({
        ...employeeData,
        'accepted': true,
        'timestamp': Timestamp.now(),
      });
      print('Employee accepted and registered successfully in Regemp!');
    } catch (e) {
      print('Error accepting employee: $e');
      // Handle any errors here
    }
  }
}
