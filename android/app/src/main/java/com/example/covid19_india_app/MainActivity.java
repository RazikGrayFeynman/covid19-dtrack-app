package com.example.covid19_india_app;

import java.util.UUID;
import java.util.Arrays;
import java.util.List;
import java.nio.ByteBuffer;

import android.os.ParcelUuid;
import androidx.annotation.NonNull;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanSettings;
import android.bluetooth.le.BluetoothLeScanner;

public class MainActivity extends FlutterActivity {
  private static final String METHODCHANNEL = "bluetoothManager/methodChannel1";
  private static final String EVENTCHANNEL = "events";
  private static final BluetoothManager bluetoothManager = new BluetoothManager();

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    new MethodChannel(flutterEngine.getDartExecutor(), METHODCHANNEL)
    .setMethodCallHandler(
      (call, result) -> {
        if(call.method.equals("startBluetoothAdvertising")) {
          bluetoothManager.startAdvertising(result);
        }
      }
    );
    
    new EventChannel(flutterEngine.getDartExecutor(), EVENTCHANNEL).setStreamHandler(
      new EventChannel.StreamHandler() {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
          bluetoothManager.startScanning(events);
        }

        @Override
        public void onCancel(Object arguments) {

        }
      }
    );

    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}

class DataConverter {
  public static byte[] hexStringToByteArray(String s) {
    int len = s.length();
    byte[] data = new byte[len / 2];
    for (int i = 0; i < len; i += 2) {
        data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                             + Character.digit(s.charAt(i+1), 16));
    }
    return data;
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
    byte[] data = DataConverter.hexStringToByteArray("7629497b20bb5e8f");
    AdvertiseData advertiseData = new AdvertiseData.Builder()
      .setIncludeDeviceName(false)
      .addServiceUuid(uuid)
      .addServiceData(uuid, data)
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
          result.error("ERR", "ERR", null);
      }
    };
    advertiser.startAdvertising(settings, advertiseData, callback);
  }

  void startScanning(EventChannel.EventSink events) {
    BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
    BluetoothLeScanner scanner = adapter.getBluetoothLeScanner();
    ParcelUuid uuid = new ParcelUuid(UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb"));
    ScanFilter filter = new ScanFilter.Builder()
      .setServiceUuid(uuid)
      .build();
    List<ScanFilter> filterList = Arrays.asList(new ScanFilter[]{filter});
    ScanSettings settings = new ScanSettings.Builder()
      .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
      .setScanMode(ScanSettings.SCAN_MODE_BALANCED)
      .build();
    ScanCallback callback = new ScanCallback() {
      @Override
      public void onScanResult(int callbackType, ScanResult result) {
        byte[] serviceData = result.getScanRecord().getServiceData(uuid);
        if (serviceData != null) {
          events.success(serviceData);
        }
      }

      @Override
      public void onScanFailed(int errorCode) {
      }
    };
    scanner.startScan(filterList, settings, callback);
  }
}