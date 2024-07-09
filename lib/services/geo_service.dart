import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeoService {
  // Set a fixed landmark position (update with your desired coordinates)
  final double landmarkLatitude = 16.487026724481314;  // landmark latitude
  final double landmarkLongitude = 80.5028066313203;  // landmark longitude

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please enable Your Location Service');
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              'Location permissions are permanently denied, we cannot request permissions.');
      throw Exception('Location permissions are permanently denied.');
    }

    // When we reach here, permissions are granted and we can access the position
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
  }

  Future<String> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      return "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
    } catch (e) {
      throw Exception('Error getting address: $e');
    }
  }

  Future<double> getDistanceToLandmark(Position position) async {
    try {
      return Geolocator.distanceBetween(
          position.latitude, position.longitude, landmarkLatitude, landmarkLongitude);
    } catch (e) {
      throw Exception('Error calculating distance: $e');
    }
  }

  Future<bool> isWithin50m(Position position) async {
    double distance = await getDistanceToLandmark(position);
    return distance <= 50;
  }
}
