// import 'dart:io';
// // ignore: unused_import
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;
// import 'package:ooriba_s3/employee_checkin_page.dart'; // Import the EmployeeCheckInPage
// import 'package:ooriba_s3/services/retrieveDataByEmail.dart'; // Import the FirestoreService
// import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
// import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core

// class Recognition {
//   final Rect location;
//   final String name;
//   final double distance;

//   Recognition({required this.location, required this.name, required this.distance});
// }

// class Recognizer {
//   Recognizer();

//   // Define any methods or properties needed for your Recognizer class
//   Recognition recognize(img.Image image, Rect faceRect) {
//     // Perform recognition logic here
//     // This is just a placeholder method, replace it with your actual implementation
//     return Recognition(location: Rect.zero, name: '', distance: 0.0); // Placeholder return value, replace with actual return value
//   }
// }

// class RecognitionScreen extends StatefulWidget {
//   final String email;
//   // ignore: use_super_parameters
//   const RecognitionScreen({Key? key, required this.email}) : super(key: key);

//   @override
//   State<RecognitionScreen> createState() => _HomePageState();
// }

// class _HomePageState extends State<RecognitionScreen> {
//   // Declare variables
//   late ImagePicker imagePicker;
//   File? _image;

//   // Declare detector
//   late FaceDetector faceDetector;

//   // Declare face recognizer
//   late Recognizer recognizer;

//   // Declare FirestoreService
//   final FirestoreService firestore_Service = FirestoreService();

//   @override
//   void initState() {
//     super.initState();
//     imagePicker = ImagePicker();

//     // Initialize face detector
//     final options = FaceDetectorOptions();
//     faceDetector = FaceDetector(options: options);

//     // Initialize face recognizer
//     recognizer = Recognizer();

//     // Initialize Firebase
//     Firebase.initializeApp();
//   }

//   // Capture image using camera
//   _imgFromCamera() async {
//     XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         doFaceDetection();
//       });
//     }
//   }

//   // Face detection code
//   List<Face> faces = [];
//   doFaceDetection() async {
//     recognitions.clear();
//     // Remove rotation of camera images
//     _image = await removeRotation(_image!);

//     image = await _image?.readAsBytes();
//     image = await decodeImageFromList(image);

//     // Passing input to face detector and getting detected faces
//     InputImage inputImage = InputImage.fromFile(_image!);
//     faces = await faceDetector.processImage(inputImage);
//     for (Face face in faces) {
//       Rect faceRect = face.boundingBox;
//       num left = faceRect.left < 0 ? 0 : faceRect.left;
//       num top = faceRect.top < 0 ? 0 : faceRect.top;
//       num right = faceRect.right > image.width ? image.width - 1 : faceRect.right;
//       num bottom = faceRect.bottom > image.height ? image.height - 1 : faceRect.bottom;
//       num width = right - left;
//       num height = bottom - top;

//       // Crop face
//       final bytes = _image!.readAsBytesSync();
//       img.Image? faceImg = img.decodeImage(bytes);
//       img.Image faceImg2 = img.copyCrop(faceImg!, x: left.toInt(), y: top.toInt(), width: width.toInt(), height: height.toInt());

//       Recognition recognition = recognizer.recognize(faceImg2, faceRect);
//       recognitions.add(recognition);
//     }
//     drawRectangleAroundFaces();
//   }

//   // Remove rotation of camera images
//   removeRotation(File inputImage) async {
//     final img.Image? capturedImage = img.decodeImage(await File(inputImage.path).readAsBytes());
//     final img.Image orientedImage = img.bakeOrientation(capturedImage!);
//     return await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
//   }

//   // Draw rectangles
//   var image;
//   drawRectangleAroundFaces() async {
//     image = await _image?.readAsBytes();
//     image = await decodeImageFromList(image);
//     setState(() {
//       recognitions;
//       image;
//       faces;
//     });
//   }

//   Future<void> uploadImageToFirebase(File image, String email) async {
//     try {
//       // Define the path for the image in Firebase Storage
//       String imagePath = 'authImage/$email.jpg';

//       // Get a reference to the Firebase Storage
//       Reference storageRef = FirebaseStorage.instance.ref().child(imagePath);

//       // Upload the image file
//       await storageRef.putFile(image);
//     } catch (e) {
//       print("Error uploading image to Firebase Storage: $e");
//     }
//   }

//   List<Recognition> recognitions = [];

//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           image != null
//               ? Container(
//                   margin: const EdgeInsets.only(top: 60, left: 30, right: 30, bottom: 0),
//                   child: FittedBox(
//                     child: SizedBox(
//                       width: image.width.toDouble(),
//                       height: image.width.toDouble(),
//                       child: CustomPaint(
//                         painter: FacePainter(facesList: recognitions, imageFile: image),
//                       ),
//                     ),
//                   ),
//                 )
//               : Container(
//                   margin: const EdgeInsets.only(top: 100),
//                   child: Image.asset(
//                     "assets/images/logo.png",
//                     width: screenWidth - 100,
//                     height: screenWidth - 100,
//                   ),
//                 ),
//           Container(
//             height: 50,
//           ),
//           Container(
//             margin: const EdgeInsets.only(bottom: 50),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Card(
//                   shape: const RoundedRectangleBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(200))),
//                   child: InkWell(
//                     onTap: () {
//                       _imgFromCamera();
//                     },
//                     child: SizedBox(
//                       width: screenWidth / 2 - 70,
//                       height: screenWidth / 2 - 70,
//                       child: Icon(Icons.camera,
//                           color: Colors.blue, size: screenWidth / 7),
//                     ),
//                   ),
//                 ),
//                 // Add the Next button
//                 if (_image != null)
//                   Card(
//                     shape: const RoundedRectangleBorder(
//                         borderRadius: BorderRadius.all(Radius.circular(200))),
//                     child: InkWell(
//                       onTap: () async {
//                         // Upload the image to Firebase Storage
//                         await uploadImageToFirebase(_image!, widget.email);

//                         // Fetch employee data
//                         Map<String, dynamic>? employeeData = await firestore_Service.searchEmployee(email: widget.email);
//                         String firstName = employeeData != null ? employeeData['firstName'] ?? '' : '';

//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => EmployeeCheckInPage(
//                               empname: firstName,
//                               empemail: widget.email, // Use the email passed to RecognitionScreen
//                             ),
//                           ),
//                         );
//                       },
//                       child: SizedBox(
//                         width: screenWidth / 2 - 70,
//                         height: screenWidth / 2 - 70,
//                         child: Icon(Icons.arrow_forward,
//                             color: Colors.blue, size: screenWidth / 7),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class FacePainter extends CustomPainter {
//   List<Recognition> facesList;
//   dynamic imageFile;
//   FacePainter({required this.facesList, @required this.imageFile});

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (imageFile != null) {
//       canvas.drawImage(imageFile, Offset.zero, Paint());
//     }

//     Paint p = Paint();
//     p.color = Colors.red;
//     p.style = PaintingStyle.stroke;
//     p.strokeWidth = 3;

//     for (Recognition rectangle in facesList) {
//       canvas.drawRect(rectangle.location, p);

//       TextSpan span = TextSpan(
//           style: const TextStyle(color: Colors.white, fontSize: 30),
//           text: "${rectangle.name}  ${rectangle.distance.toStringAsFixed(2)}");
//       TextPainter tp = TextPainter(
//           text: span,
//           textAlign: TextAlign.left,
//           textDirection: TextDirection.ltr);
//       tp.layout();
//       tp.paint(canvas, Offset(rectangle.location.left, rectangle.location.top));
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return true;
//   }
// }
