import 'dart:convert';

class SyncMessage {
  const SyncMessage({
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  final SyncType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  String encode() => jsonEncode({
        'type': type.name,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
      });

  factory SyncMessage.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return SyncMessage(
      type: SyncType.values.byName(json['type'] as String),
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

enum SyncType {
  scoreUpdate,
  usageUpdate,
  petStateUpdate,
  feedCommand,
  outfitCommand,
  notificationTrigger,
}
