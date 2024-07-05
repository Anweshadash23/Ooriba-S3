import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeIdGenerator {
  static const int _idLength = 3;

  Future<String> generateEmployeeId(String location) async {
    final String prefix;
    switch (location) {
      case 'Berhampur':
        prefix = 'OOB';
        break;
      case 'Jeypore':
        prefix = 'OOJ';
        break;
      case 'Rayagada':
        prefix = 'OOR';
        break;
      default:
        throw ArgumentError('Invalid location: $location');
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('Regemp')
        .where('employeeId', isGreaterThanOrEqualTo: prefix)
        .where('employeeId', isLessThan: _getNextPrefix(prefix))
        .orderBy('employeeId', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return '$prefix${_formatId(1)}';
    } else {
      final lastId = querySnapshot.docs.first.get('employeeId') as String;
      final numericPart = int.tryParse(lastId.replaceFirst(prefix, '')) ?? 0;
      return '$prefix${_formatId(numericPart + 1)}';
    }
  }

  String _formatId(int id) {
    return id.toString().padLeft(_idLength, '0');
  }

  String _getNextPrefix(String prefix) {
    final prefixCode = prefix.codeUnitAt(2);
    final nextPrefixCode = prefixCode + 1;
    return prefix.substring(0, 2) + String.fromCharCode(nextPrefixCode);
  }
}
