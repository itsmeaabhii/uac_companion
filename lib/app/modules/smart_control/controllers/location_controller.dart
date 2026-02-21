import 'package:fl_location/fl_location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:uac_companion/app/modules/smart_control/controllers/smart_controls_controller.dart';
import 'package:uac_companion/app/routes/app_routes.dart';

class LocationController extends GetxController {
  static LocationController get to => Get.find();

  final RxInt selectedIndex = (-1).obs;
  final List<Map<String, dynamic>> options = [
    {"label": "Ring at Location", "type": 1},
    {"label": "Cancel at Location", "type": 2},
    {"label": "Ring Away from Location", "type": 3},
    {"label": "Cancel Away from Location", "type": 4},
  ];

  // Fallback location (New Delhi) if user location is unavailable
  static final LatLng fallbackLatLng = LatLng(28.6139, 77.2090);
  final MapController mapController = MapController();
  var pickerLatLng = fallbackLatLng.obs;
  var currentUserLocation = Rxn<LatLng>();
  var isLoadingLocation = false.obs;

  /// Fetch user's current location
  Future<void> fetchCurrentLocation() async {
    isLoadingLocation.value = true;
    
    try {
      // Check if location service is enabled
      if (!await FlLocation.isLocationServicesEnabled) {
        Get.snackbar(
          'Location Services Disabled',
          'Please enable location services',
          snackPosition: SnackPosition.BOTTOM,
        );
        currentUserLocation.value = fallbackLatLng;
        isLoadingLocation.value = false;
        return;
      }

      // Check location permission
      var permission = await FlLocation.checkLocationPermission();
      
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Location Permission Denied',
          'Using default location (New Delhi)',
          snackPosition: SnackPosition.BOTTOM,
        );
        currentUserLocation.value = fallbackLatLng;
        isLoadingLocation.value = false;
        return;
      }

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await FlLocation.requestLocationPermission();
        
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          Get.snackbar(
            'Location Permission Denied',
            'Using default location (New Delhi)',
            snackPosition: SnackPosition.BOTTOM,
          );
          currentUserLocation.value = fallbackLatLng;
          isLoadingLocation.value = false;
          return;
        }
      }

      // Get current location
      final location = await FlLocation.getLocation(
        accuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      if (location.latitude != 0.0 && location.longitude != 0.0) {
        currentUserLocation.value = LatLng(location.latitude, location.longitude);
      } else {
        currentUserLocation.value = fallbackLatLng;
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Could not fetch location. Using default location.',
        snackPosition: SnackPosition.BOTTOM,
      );
      currentUserLocation.value = fallbackLatLng;
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void onPickerScreenReady() {
    if (mapController.camera.center != pickerLatLng.value) {
      mapController.move(pickerLatLng.value, 13);
    }
  }

  Future<void> onSelectCondition(int index) async {
    // Fetch current location before opening picker
    await fetchCurrentLocation();
    
    // Use current user location or fallback
    pickerLatLng.value = currentUserLocation.value ?? fallbackLatLng;

    final result = await Get.toNamed(AppRoutes.locationPicker);

    if (result is LatLng) {
      final selectedType = options[index]["type"] as int;
      //! check for location type on UAC
      final locationString ="${result.latitude},${result.longitude}";
      selectedIndex.value = index;

      SmartControlsController.to.updateLocationCondition(
        true,
        selectedType,
        locationString,
      );
      Get.back(result: true);
    }
  }

  void onTapMap(tapPosition, latLng) {
    pickerLatLng.value = latLng;
  }

  void confirmSelection() {
    Get.back(result: pickerLatLng.value);
  }
}