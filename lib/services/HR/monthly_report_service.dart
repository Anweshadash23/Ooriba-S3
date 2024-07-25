import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchAllEmployeeData() async {
    try {
      // Fetch employee data from Regemp collection
      QuerySnapshot regempSnapshot =
          await _firestore.collection('Regemp').get();
      List<QueryDocumentSnapshot> regempDocs = regempSnapshot.docs;

      // Fetch leave count data from LeaveCount collection
      QuerySnapshot leaveCountSnapshot =
          await _firestore.collection('LeaveCount').get();
      List<QueryDocumentSnapshot> leaveCountDocs = leaveCountSnapshot.docs;

      // Create a map for leave counts
      Map<String, int> leaveCounts = {
        for (var doc in leaveCountDocs) doc.id: doc.get('count')
      };

      // Initialize employees map
      Map<String, Map<String, dynamic>> employees = {
        for (var doc in regempDocs)
          doc.get('employeeId'): {
            'employeeId': doc.get('employeeId'),
            'name': '${doc.get('firstName')} ${doc.get('lastName')}',
            'location': doc.get('location'),
            'joiningDate': (doc.get('joiningDate') as Timestamp)
                .toDate()
                .toIso8601String(),
            'phoneNo': doc.get('phoneNo'),
            'workingDays': 0,
            'leaveCount': leaveCounts[doc.get('employeeId')] ?? 0,
          }
      };

      // Fetch attendance data from Dates collection
      QuerySnapshot datesSnapshot = await _firestore.collection('Dates').get();
      List<QueryDocumentSnapshot> datesDocs = datesSnapshot.docs;

      // Calculate working days
      for (var doc in datesDocs) {
        Map<String, dynamic> attendance = doc.data() as Map<String, dynamic>;
        for (String employeeId in attendance.keys) {
          if (attendance[employeeId]['checkIn'] != null) {
            employees[employeeId]?['workingDays'] += 1;
          }
        }
      }

      return employees.values.toList();
    } catch (e) {
      print('Error fetching employee data: $e');
      return [];
    }
  }
}
