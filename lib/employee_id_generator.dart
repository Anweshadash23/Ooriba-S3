import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeIdGenerator {
  Future<String> generateEmployeeId(String location) async {
    // Fetch location details from Firestore collection "location"
    DocumentReference locationRef =
        FirebaseFirestore.instance.collection('location').doc(location);

    DocumentSnapshot locationDoc = await locationRef.get();

    if (locationDoc.exists) {
      // Cast data to Map<String, dynamic>
      Map<String, dynamic> locationData =
          locationDoc.data() as Map<String, dynamic>;

      // Get prefix and current count
      String prefix = locationData['prefix'];
      int count;

      // Check if count field exists
      if (locationData.containsKey('count')) {
        count = locationData['count'];
      } else {
        count = 0;
      }

      // Increment count
      count++;

      // Update count in Firestore
      await locationRef.update({'count': count});

      // Generate employeeId with format: prefix + count (e.g., JEY001)
      String employeeId = '$prefix${count.toString().padLeft(3, '0')}';
      return employeeId;
    } else {
      throw Exception('Location details not found');
    }
  }
}
