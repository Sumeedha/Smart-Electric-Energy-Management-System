import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef MessageCallback = void Function(String topic, String payload);

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;

  MqttService._internal() {
    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.keepAlivePeriod = 60;
    client.autoReconnect = false;
    client.logging(on: true);
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = (String topic) => print('✅ Subscribed to: $topic');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .keepAliveFor(60)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMessage;
  }

  final String broker = 'test.mosquitto.org'; // More stable broker
  final int port = 1883;
  final String clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
  late MqttServerClient client;
  bool isConnected = false;
  final List<String> subscribedTopics = [];
  MessageCallback? onMessageReceived;
  bool _isReconnecting = false;
  final StreamController<MqttConnectionState> _connectionController =
  StreamController<MqttConnectionState>.broadcast();

  // A map for per-topic callbacks.
  final Map<String, MessageCallback> _callbacks = {};

  Stream<MqttConnectionState> get connectionStream => _connectionController.stream;

  /// Connect to the broker and subscribe to a list of topics using the global callback.
  Future<void> connectAndSubscribe({
    required List<String> topics,
    required MessageCallback onMessageReceived,
  }) async {
    this.onMessageReceived = onMessageReceived;
    if (isConnected) {
      print('⚠️ Already connected to MQTT broker.');
      return;
    }

    try {
      print('🔄 Connecting to MQTT broker...');
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        isConnected = true;
        _connectionController.add(MqttConnectionState.connected);
        print('✅ Successfully connected to MQTT broker.');
        _subscribeToTopics(topics);
        _listenToMessages();
      } else {
        throw Exception('MQTT Connection failed: ${client.connectionStatus?.state}');
      }
    } catch (e) {
      print('🚨 MQTT Connection Error: $e');
      _attemptReconnect();
    }
  }

  /// Subscribe to a list of topics using the global callback.
  void _subscribeToTopics(List<String> topics) {
    for (String topic in topics) {
      if (!subscribedTopics.contains(topic)) {
        client.subscribe(topic, MqttQos.atMostOnce);
        subscribedTopics.add(topic);
        print('📡 Subscribed to: $topic');
      }
    }
  }

  /// New subscribe method that registers a per-topic callback.
  void subscribe(String topic, MessageCallback callback) {
    _callbacks[topic] = callback;
    if (!subscribedTopics.contains(topic)) {
      client.subscribe(topic, MqttQos.atMostOnce);
      subscribedTopics.add(topic);
      print('📡 Subscribed to: $topic');
    }
  }

  void _listenToMessages() {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      if (messages != null) {
        for (var message in messages) {
          final recMessage = message.payload as MqttPublishMessage?;
          if (recMessage != null && recMessage.payload.message != null) {
            final payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message!);
            print('📩 Received: "$payload" from ${message.topic}');
            // Check if a specific callback exists for this topic.
            if (_callbacks.containsKey(message.topic)) {
              _callbacks[message.topic]?.call(message.topic, payload);
            } else {
              // Fallback to the global callback.
              onMessageReceived?.call(message.topic, payload);
            }
          }
        }
      }
    });
  }

  void publishMessage(String topic, String message) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 Sent: "$message" to $topic');
    } else {
      print('⚠️ Cannot publish. MQTT Client is not connected.');
    }
  }

  void _onDisconnected() {
    if (isConnected) {
      print('❌ Unexpected MQTT Disconnection.');
      _attemptReconnect();
    }
    isConnected = false;
    _connectionController.add(MqttConnectionState.disconnected);
  }

  void _onConnected() {
    isConnected = true;
    _connectionController.add(MqttConnectionState.connected);
    print('✅ Reconnected. Re-subscribing to topics...');
    _subscribeToTopics(subscribedTopics);
  }

  void disconnect() {
    if (isConnected) {
      client.disconnect();
      isConnected = false;
      subscribedTopics.clear();
      _connectionController.add(MqttConnectionState.disconnected);
      print('🔌 Disconnected from MQTT broker.');
    } else {
      print('⚠️ Client was not connected.');
    }
  }

  Future<void> _attemptReconnect() async {
    if (!_isReconnecting) {
      _isReconnecting = true;
      int retryDelay = 3;
      for (int i = 1; i <= 5; i++) {
        print('🔄 Reconnecting in $retryDelay seconds... (Attempt $i)');
        await Future.delayed(Duration(seconds: retryDelay));
        retryDelay *= 2;

        if (!isConnected) {
          print('⚠️ Retrying MQTT connection...');
          await connectAndSubscribe(
            topics: subscribedTopics,
            onMessageReceived: onMessageReceived ??
                    (t, p) => print('📩 Reconnected message from $t: $p'),
          );
          if (isConnected) {
            print('✅ Reconnection successful.');
            _isReconnecting = false;
            return;
          }
        }
      }
      print('❌ MQTT Reconnection failed after multiple attempts.');
      _isReconnecting = false;
    }
  }

  void dispose() {
    disconnect();
    _connectionController.close();
  }
}
