import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AddEmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addEmployee(
    String firstName,
    String middleName,
    String lastName,
    String? email,
    String? panNo,
    String residentialAddress,
    String permanentAddress,
    String phoneNumber,
    String dob,
    String aadharNo,
    String password, // Added password parameter
    File? dpImage,
    File? adhaarImage,
    File? supportImage,
    BuildContext context,
  ) async {
    try {
      // Upload images to Firebase Storage
      String? dpImageUrl = await _uploadImage(dpImage, 'dpImages/$phoneNumber');
      String? adhaarImageUrl =
          await _uploadImage(adhaarImage, 'aadhaarImages/$phoneNumber');
      String? supportImageUrl =
          await _uploadImage(supportImage, 'supportImages/$phoneNumber');

      // Save employee data to Firestore with phone number as document ID
      await _firestore.collection('Regemp').doc(phoneNumber).set({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'email': email,
        'panNo': panNo,
        'residentialAddress': residentialAddress,
        'permanentAddress': permanentAddress,
        'phoneNumber': phoneNumber,
        'dob': dob,
        'aadharNo': aadharNo,
        'password': password, // Store password in Firestore
        'dpImageUrl': dpImageUrl,
        'adhaarImageUrl': adhaarImageUrl,
        'supportImageUrl': supportImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add employee: $e');
    }
  }

  Future<String?> _uploadImage(File? image, String path) async {
    if (image == null) return null;

    try {
      TaskSnapshot snapshot = await _storage.ref().child(path).putFile(image);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
