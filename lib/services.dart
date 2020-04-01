import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'database.dart';

class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  static final BluetoothManager _bluetoothManager = BluetoothManager();
  static final LocationManager _locationManager = LocationManager();

  ServiceManager._internal();

  factory ServiceManager() {
    return _instance;
  }

  Future<void> startAllServices() async {
    await _locationManager.checkLocationService();
    await _bluetoothManager.startAdvertise();
    await _bluetoothManager.startScanning();
  }
}

class BluetoothManager {
  static final channel = MethodChannel('bluetoothManager/methodChannel1');

  startAdvertise() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await channel.invokeMethod("startBluetoothAdvertising");
    } 
    else if (defaultTargetPlatform == TargetPlatform.iOS) {
      print("not implemented");
    }
  }

  startScanning() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      EventChannel e = EventChannel('events');
      var s = e.receiveBroadcastStream();
      await s.forEach((e) async {
        var newDevice = DevicesSeen(e);
        newDevice.addToDatabase();
      });
    }
    else if (defaultTargetPlatform == TargetPlatform.iOS) {
      print("not implemented");
    }
  }
}

class LocationManager {
  checkLocationService() async {
    var location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
    }
  }
}