import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class SocketService {
  StompClient? _client;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Connect to WebSocket
  void connect({
    required Function() onConnect,
    Function(String)? onError,
  }) {
    _client = StompClient(
      config: StompConfig(
        url: AppConstants.wsUrl,
        onConnect: (StompFrame frame) {
          _isConnected = true;
          print('✅ WebSocket connected');
          onConnect();
        },
        onWebSocketError: (dynamic error) {
          _isConnected = false;
          print('❌ WebSocket error: $error');
          onError?.call(error.toString());
        },
        onStompError: (StompFrame frame) {
          _isConnected = false;
          print('❌ STOMP error: ${frame.body}');
          onError?.call(frame.body ?? 'Unknown STOMP error');
        },
        onDisconnect: (frame) {
          _isConnected = false;
          print('🔌 WebSocket disconnected');
        },
        // Auto-reconnect on connection drop
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _client?.activate();
  }

  // Subscribe to auction updates
  void subscribeToAuction({
    required int auctionId,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    if (!_isConnected || _client == null) {
      print('⚠️ Cannot subscribe: WebSocket not connected');
      return;
    }

    final destination = '/topic/auctions/$auctionId';

    _client?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            print('📨 Received update: $data');
            onUpdate(data);
          } catch (e) {
            print('❌ Failed to parse message: $e');
          }
        }
      },
    );

    print('✅ Subscribed to $destination');
  }

  // Unsubscribe from auction
  void unsubscribeFromAuction(int auctionId) {
    final destination = '/topic/auctions/$auctionId';
    // Note: stomp_dart_client doesn't provide direct unsubscribe by destination
    // It auto-unsubscribes when client deactivates
    print('📡 Unsubscribed from $destination (on disconnect)');
  }

  // Disconnect
  void disconnect() {
    _client?.deactivate();
    _isConnected = false;
    print('🔌 WebSocket disconnected manually');
  }
}
