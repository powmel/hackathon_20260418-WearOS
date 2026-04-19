import 'dart:async';
import 'dart:convert';

import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:shared_models/shared_models.dart';

class WearSyncReceiver {
  WearSyncReceiver();

  final FlutterWearOsConnectivity _wear = FlutterWearOsConnectivity();
  final _controller = StreamController<SyncMessage>.broadcast();

  Stream<SyncMessage> get messages => _controller.stream;

  Future<void> init() async {
    _wear.configureWearableAPI();
    _listenMessages(SyncPaths.scorePath);
    _listenMessages(SyncPaths.petStatePath);
    _listenMessages(SyncPaths.notifyPath);
    _listenMessages(SyncPaths.feedCommandPath);
    _listenMessages(SyncPaths.outfitCommandPath);
  }

  void _listenMessages(String path) {
    _wear.messageReceived(pathURI: Uri.parse(path)).listen((msg) {
      try {
        final decoded = utf8.decode(msg.data);
        final syncMsg = SyncMessage.decode(decoded);
        _controller.add(syncMsg);
      } catch (_) {}
    });
  }

  Future<void> sendToPhone({
    required String path,
    required SyncMessage message,
  }) async {
    try {
      final devices = await _wear.getConnectedDevices();
      final data = utf8.encode(message.encode());
      for (final device in devices) {
        await _wear.sendMessage(data, deviceId: device.id, path: path);
      }
    } catch (_) {}
  }

  void dispose() {
    _controller.close();
  }
}
