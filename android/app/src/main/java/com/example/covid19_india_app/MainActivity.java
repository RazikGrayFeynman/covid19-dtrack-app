package com.example.covid19_india_app;

import java.util.UUID;

import android.os.ParcelUuid;
import androidx.annotation.NonNull;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.BluetoothLeScanner;

public class MainActivity extends FlutterActivity {
  private static final String channel = "bluetoothManager/channel1";
  private static final BluetoothManager bluetoothManager = new BluetoothManager();
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), channel)
    .setMethodCallHandler(
      (call, result) -> {
        if(call.method.equals("startBluetoothAdvertising")) {
          bluetoothManager.startAdvertising(result);
        }
        else if(call.method.equals("startBluetoothScanning")) {
          bluetoothManager.startScanning(result);
        }
      }
    );
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}

class BluetoothManager {
  void startAdvertising(MethodChannel.Result result) {
    BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
    BluetoothLeAdvertiser advertiser = adapter.getBluetoothLeAdvertiser();
    if(advertiser == null) {
      result.error("BLE", "Advertiser not available", null);
      return;
    }
    AdvertiseSettings settings = new AdvertiseSettings.Builder()
      .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
      .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
      .setConnectable(false)
      .build();
    ParcelUuid uuid = new ParcelUuid(UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb"));
    AdvertiseData advertiseData = new AdvertiseData.Builder()
      .setIncludeDeviceName(false)
      .addServiceUuid(uuid)
      .build();
    AdvertiseCallback callback = new AdvertiseCallback() {
      @Override
      public void onStartSuccess(AdvertiseSettings settingsInEffect) {
          super.onStartSuccess(settingsInEffect);
          result.success(null);
      }
  
      @Override
      public void onStartFailure(int errorCode) {
          super.onStartFailure(errorCode);
      }
    };
    advertiser.startAdvertising(settings, advertiseData, callback);
  }

  void startScanning(MethodChannel.Result result) {
    BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
    BluetoothLeScanner scanner = adapter.getBluetoothLeScanner();
    ScanCallback callback = new ScanCallback() {
      @Override
      public void onScanResult(int callbackType, ScanResult result) {
        Log.e("BLE", "found something");
        Log.e("BLE", result.getScanRecord().getServiceUuids().get(0).toString());
      }

      @Override
      public void onScanFailed(int errorCode) {
        Log.e("BLE", "Scanning onScanFailed: " + errorCode);
      }
    };
    scanner.startScan(callback);
    result.success(null);
  }
}