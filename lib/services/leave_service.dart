import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> applyLeave({
    required String employeeId,
    required String leaveType,
    required DateTime? fromDate,
    required DateTime? toDate,
    required double numberOfDays,
    required String? leaveReason,
  }) async {
    try {
      String fromDateStr =
          fromDate != null ? fromDate.toIso8601String().split('T').first : '';

      await _firestore
          .collection('leave')
          .doc('request')
          .collection(employeeId)
          .doc(fromDateStr)
          .set({
        'employeeId': employeeId,
        'leaveType': leaveType,
        'fromDate': fromDate,
        'toDate': toDate,
        'numberOfDays': numberOfDays,
        'leaveReason': leaveReason,
        'isApproved': null, // Initialize isApproved as null
      });
    } catch (e) {
      print('Error applying leave: $e');
      throw e;
    }
  }

  Future<void> updateLeaveStatus({
    required String employeeId,
    required String fromDateStr,
    required bool isApproved,
  }) async {
    try {
      // Update the leave status in the request collection
      await _firestore
          .collection('leave')
          .doc('request')
          .collection(employeeId)
          .doc(fromDateStr)
          .update({
        'isApproved': isApproved,
      });

      // Fetch the leave details
      DocumentSnapshot<Map<String, dynamic>> leaveDoc = await _firestore
          .collection('leave')
          .doc('request')
          .collection(employeeId)
          .doc(fromDateStr)
          .get();

      if (leaveDoc.exists) {
        Map<String, dynamic> leaveData = leaveDoc.data()!;

        // If the leave is approved, copy the leave details to the "accept" collection
        if (isApproved) {
          await _firestore
              .collection('leave')
              .doc('accept')
              .collection(employeeId)
              .doc(fromDateStr)
              .set({
            'employeeId': employeeId,
            'leaveType': leaveData['leaveType'],
            'fromDate': leaveData['fromDate'],
            'toDate': leaveData['toDate'],
            'numberOfDays': leaveData['numberOfDays'],
            'leaveReason': leaveData['leaveReason'],
            'isApproved': isApproved,
          });
        } else {
          // If the leave is denied, copy the leave details to the "reject" collection
          await _firestore
              .collection('leave')
              .doc('reject')
              .collection(employeeId)
              .doc(fromDateStr)
              .set({
            'employeeId': employeeId,
            'leaveType': leaveData['leaveType'],
            'fromDate': leaveData['fromDate'],
            'toDate': leaveData['toDate'],
            'numberOfDays': leaveData['numberOfDays'],
            'leaveReason': leaveData['leaveReason'],
            'isApproved': isApproved,
          });
        }
      }
    } catch (e) {
      print('Error updating leave status: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> fetchLeaveDetails(
      String employeeId, String fromDateStr) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('leave')
          .doc('request')
          .collection(employeeId)
          .doc(fromDateStr)
          .get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      print('Error fetching leave details: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllLeaveRequests() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collectionGroup('employeeId').get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['employeeId'] = doc.reference.parent.parent?.id ?? 'Unknown';
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching all leave requests: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> fetchLeaveRequestsByEmployeeId(
      String employeeId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('leave')
          .doc('request')
          .collection(employeeId)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['employeeId'] = employeeId;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching leave requests by employee ID: $e');
      throw e;
    }
  }
}
