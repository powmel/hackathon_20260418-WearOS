import 'dart:convert';

import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:shared_models/shared_models.dart';

class WearSyncService {
  WearSyncService();

  final FlutterWearOsConnectivity _wear = FlutterWearOsConnectivity();
  bool _configured = false;

  Future<void> init() async {
    if (_configured) return;
    _wear.configureWearableAPI();
    _configured = true;
  }

  Future<void> sendScoreUpdate({
    required int focusScore,
    required int usageMinutes,
    required int fullness,
  }) async {
    final msg = SyncMessage(
      type: SyncType.scoreUpdate,
      payload: {
        'focusScore': focusScore,
        'usageMinutes': usageMinutes,
        'fullness': fullness,
      },
      timestamp: DateTime.now(),
    );
    await _sendToAllDevices(SyncPaths.scorePath, msg.encode());
  }

  Future<void> sendPetState({
    required int focusScore,
    required int usageMinutes,
    required int fullness,
    required String mood,
    required String outfit,
  }) async {
    final msg = SyncMessage(
      type: SyncType.petStateUpdate,
      payload: {
        'focusScore': focusScore,
        'usageMinutes': usageMinutes,
        'fullness': fullness,
        'mood': mood,
        'outfit': outfit,
      },
      timestamp: DateTime.now(),
    );
    await _sendToAllDevices(SyncPaths.petStatePath, msg.encode());
  }

  Future<void> sendNotification({
    required String title,
    required String body,
  }) async {
    final msg = SyncMessage(
      type: SyncType.notificationTrigger,
      payload: {'title': title, 'body': body},
      timestamp: DateTime.now(),
    );
    await _sendToAllDevices(SyncPaths.notifyPath, msg.encode());
  }

  Future<void> _sendToAllDevices(String path, String data) async {
    try {
      final devices = await _wear.getConnectedDevices();
      for (final device in devices) {
        await _wear.sendMessage(
          utf8.encode(data),
          deviceId: device.id,
          path: path,
        );
      }
    } catch (e) {
      // Wear OS not connected - silently ignore for demo
    }
  }
}
