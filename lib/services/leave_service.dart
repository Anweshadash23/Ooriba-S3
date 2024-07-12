// import 'package:cloud_firestore/cloud_firestore.dart';

// class LeaveService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> applyLeave({
//     required String employeeId,
//     required String leaveType,
//     required DateTime? fromDate,
//     required DateTime? toDate,
//     required double numberOfDays,
//     required String? leaveReason,
//   }) async {
//     try {
//       String fromDateStr =
//           fromDate != null ? fromDate.toIso8601String().split('T').first : '';

//       await _firestore
//           .collection('leave')
//           .doc('request')
//           .collection(employeeId)
//           .doc(fromDateStr)
//           .set({
//         'employeeId': employeeId,
//         'leaveType': leaveType,
//         'fromDate': fromDate,
//         'toDate': toDate,
//         'numberOfDays': numberOfDays,
//         'leaveReason': leaveReason,
//         'isApproved': null, // Initialize isApproved as null
//       });
//     } catch (e) {
//       print('Error applying leave: $e');
//       throw e;
//     }
//   }

//   Future<void> updateLeaveStatus({
//     required String employeeId,
//     required String fromDateStr,
//     required bool isApproved,
//   }) async {
//     try {
//       // Update the leave status in the request collection
//       await _firestore
//           .collection('leave')
//           .doc('request')
//           .collection(employeeId)
//           .doc(fromDateStr)
//           .update({
//         'isApproved': isApproved,
//       });

//       // Fetch the leave details
//       DocumentSnapshot<Map<String, dynamic>> leaveDoc = await _firestore
//           .collection('leave')
//           .doc('request')
//           .collection(employeeId)
//           .doc(fromDateStr)
//           .get();

//       if (leaveDoc.exists) {
//         Map<String, dynamic> leaveData = leaveDoc.data()!;

//         // If the leave is approved, copy the leave details to the "accept" collection
//         if (isApproved) {
//           await _firestore
//               .collection('leave')
//               .doc('accept')
//               .collection(employeeId)
//               .doc(fromDateStr)
//               .set({
//             'employeeId': employeeId,
//             'leaveType': leaveData['leaveType'],
//             'fromDate': leaveData['fromDate'],
//             'toDate': leaveData['toDate'],
//             'numberOfDays': leaveData['numberOfDays'],
//             'leaveReason': leaveData['leaveReason'],
//             'isApproved': isApproved,
//           });
//         } else {
//           // If the leave is denied, copy the leave details to the "reject" collection
//           await _firestore
//               .collection('leave')
//               .doc('reject')
//               .collection(employeeId)
//               .doc(fromDateStr)
//               .set({
//             'employeeId': employeeId,
//             'leaveType': leaveData['leaveType'],
//             'fromDate': leaveData['fromDate'],
//             'toDate': leaveData['toDate'],
//             'numberOfDays': leaveData['numberOfDays'],
//             'leaveReason': leaveData['leaveReason'],
//             'isApproved': isApproved,
//           });
//         }
//       }
//     } catch (e) {
//       print('Error updating leave status: $e');
//       throw e;
//     }
//   }

//   Future<Map<String, dynamic>?> fetchLeaveDetails(
//       String employeeId, String fromDateStr) async {
//     try {
//       DocumentSnapshot doc = await _firestore
//           .collection('leave')
//           .doc('request')
//           .collection(employeeId)
//           .doc(fromDateStr)
//           .get();
//       return doc.exists ? doc.data() as Map<String, dynamic>? : null;
//     } catch (e) {
//       print('Error fetching leave details: $e');
//       throw e;
//     }
//   }

//   Future<List<Map<String, dynamic>>> fetchAllLeaveRequests() async {
//     try {
//       QuerySnapshot querySnapshot =
//           await _firestore.collectionGroup('employeeId').get();
//       return querySnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         data['employeeId'] = doc.reference.parent.parent?.id ?? 'Unknown';
//         return data;
//       }).toList();
//     } catch (e) {
//       print('Error fetching all leave requests: $e');
//       throw e;
//     }
//   }

//   Future<List<Map<String, dynamic>>> fetchLeaveRequestsByEmployeeId(
//       String employeeId) async {
//     try {
//       QuerySnapshot querySnapshot = await _firestore
//           .collection('leave')
//           .doc('request')
//           .collection(employeeId)
//           .get();

//       return querySnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         data['employeeId'] = employeeId;
//         return data;
//       }).toList();
//     } catch (e) {
//       print('Error fetching leave requests by employee ID: $e');
//       throw e;
//     }
//   }
// }

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

      await _firestore.collection('LeaveCount').doc(employeeId).set({
        'fromDate': fromDate,
        'count': FieldValue.increment(1), // Initialize count as 1
      }, SetOptions(merge: true));
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
            'employeeId': leaveData['employeeId'],
            'leaveType': leaveData['leaveType'],
            'fromDate': leaveData['fromDate'],
            'toDate': leaveData['toDate'],
            'numberOfDays': leaveData['numberOfDays'],
            'leaveReason': leaveData['leaveReason'],
            'isApproved': true,
          });

          await _firestore.collection('LeaveCount').doc(employeeId).set({
            'fromDate': leaveData['fromDate'],
            'count': FieldValue.increment(
                1), // Increment count in "accept" collection
          }, SetOptions(merge: true));
        } else {
          // If the leave is denied, copy the leave details to the "reject" collection
          await _firestore
              .collection('leave')
              .doc('reject')
              .collection(employeeId)
              .doc(fromDateStr)
              .set({
            'employeeId': leaveData['employeeId'],
            'leaveType': leaveData['leaveType'],
            'fromDate': leaveData['fromDate'],
            'toDate': leaveData['toDate'],
            'numberOfDays': leaveData['numberOfDays'],
            'leaveReason': leaveData['leaveReason'],
            'isApproved': false,
          });

          await _firestore.collection('LeaveCount').doc(employeeId).set({
            'fromDate': leaveData['fromDate'],
            'count': FieldValue.increment(
                1), // Increment count in "reject" collection
          }, SetOptions(merge: true));
        }

        // Remove the leave request from the "request" collection
        await _firestore
            .collection('leave')
            .doc('request')
            .collection(employeeId)
            .doc(fromDateStr)
            .delete();
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
      // Step 1: Fetch all employeeIds from Regemp collection
      QuerySnapshot querySnapshot = await _firestore.collection('Regemp').get();
      List<String> employeeIds = [];
      querySnapshot.docs.forEach((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('employeeId')) {
          String employeeId = data['employeeId'];
          if (employeeId.isNotEmpty) {
            employeeIds.add(employeeId);
          }
        }
      });

      // Step 2: Fetch leave requests for each employeeId using collectionGroup
      List<Map<String, dynamic>> allLeaveRequests = [];
      for (String employeeId in employeeIds) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('leave')
            .doc('request')
            .collection(employeeId)
            .get();

        // Step 3: Map and collect leave request data
        List<Map<String, dynamic>> leaveRequests =
            querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          // Optionally add employeeId to each leave request
          // data['employeeId'] = employeeId;
          return data;
        }).toList();

        allLeaveRequests.addAll(leaveRequests);
      }

      return allLeaveRequests;
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

  Future<Map<String, dynamic>?> fetchLeaveCount(String employeeId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('LeaveCount').doc(employeeId).get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      print('Error fetching leave count: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> fetchAcceptedLeaveDetails(
      String employeeId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('leave')
          .doc('accept')
          .collection(employeeId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching accepted leave details: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> fetchRejectedLeaveDetails(
      String employeeId, String fromDateStr) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot = await _firestore
          .collection('leave')
          .doc('reject')
          .collection(employeeId)
          .doc(fromDateStr)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching rejected leave details: $e');
      throw e;
    }
  }
}
