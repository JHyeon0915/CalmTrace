import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_feedback_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'notification_service.dart';

/// EMOTIV Cortex API Constants
class EmotivConstants {
  // Request IDs
  static const int getUserLoggedInRequestId = 1;
  static const int loginRequestId = 2;
  static const int logoutRequestId = 3;
  static const int authorizeRequestId = 4;
  static const int getUserInfoRequestId = 5;
  static const int getLicenseInfoRequestId = 6;
  static const int queryHeadsetRequestId = 7;
  static const int controlDeviceRequestId = 8;
  static const int createSessionRequestId = 9;
  static const int updateSessionRequestId = 10;
  static const int subscribeDataRequestId = 11;
  static const int unsubscribeDataRequestId = 12;

  // Warning codes
  static const int headsetIsConnected = 104;
  static const int headsetIsDisconnected = 102;

  static final String clientId =
      dotenv.env['EMOTIV_API_KEY'] ?? 'YOUR_CLIENT_ID';
  static final String clientSecret =
      dotenv.env['EMOTIV_API_SECRET'] ?? 'YOUR_CLIENT_SECRET';
  static const String licenseId = '';
  static const int debitNumber = 1;
  static const String cortexUrl = 'wss://localhost:6868';
}

/// EEG data point with timestamp
class EEGDataPoint {
  final Map<String, double> channels;
  final DateTime timestamp;
  final double? theta;
  final double? alpha;
  final double? betaL;
  final double? betaH;
  final double? gamma;

  EEGDataPoint({
    required this.channels,
    required this.timestamp,
    this.theta,
    this.alpha,
    this.betaL,
    this.betaH,
    this.gamma,
  });

  double? get stressIndicator {
    if (alpha == null || betaH == null || alpha == 0) return null;
    return (betaH! + (gamma ?? 0)) / alpha!;
  }

  double? get relaxationIndicator {
    if (alpha == null || betaH == null || betaH == 0) return null;
    return (alpha! + (theta ?? 0)) / betaH!;
  }

  @override
  String toString() =>
      'EEG(channels: ${channels.length}, stress: ${stressIndicator?.toStringAsFixed(2)})';
}

/// Performance metrics from EMOTIV
class EmotivMetrics {
  final double? engagement;
  final double? excitement;
  final double? stress;
  final double? relaxation;
  final double? interest;
  final double? focus;
  final DateTime timestamp;

  EmotivMetrics({
    this.engagement,
    this.excitement,
    this.stress,
    this.relaxation,
    this.interest,
    this.focus,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'engagement': engagement,
    'excitement': excitement,
    'stress': stress,
    'relaxation': relaxation,
    'interest': interest,
    'focus': focus,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() =>
      'EmotivMetrics(stress: ${stress?.toStringAsFixed(2)}, '
      'relaxation: ${relaxation?.toStringAsFixed(2)}, '
      'focus: ${focus?.toStringAsFixed(2)})';
}

/// Headset info
class EmotivHeadset {
  final String id;
  final bool isVirtual;
  String status;

  EmotivHeadset({
    required this.id,
    required this.isVirtual,
    required this.status,
  });

  factory EmotivHeadset.fromJson(Map<String, dynamic> json) => EmotivHeadset(
    id: json['id'] ?? '',
    isVirtual: json['isVirtual'] ?? false,
    status: json['status'] ?? 'unknown',
  );

  bool get isConnected => status == 'connected';

  @override
  String toString() => 'Headset($id, virtual: $isVirtual, status: $status)';
}

/// Connection status
enum EmotivConnectionStatus {
  disconnected,
  initializing,
  authenticating,
  connected,
  streaming,
  error,
}

extension EmotivConnectionStatusExtension on EmotivConnectionStatus {
  String get label {
    switch (this) {
      case EmotivConnectionStatus.disconnected:
        return 'Disconnected';
      case EmotivConnectionStatus.initializing:
        return 'Initializing...';
      case EmotivConnectionStatus.authenticating:
        return 'Authenticating...';
      case EmotivConnectionStatus.connected:
        return 'Connected';
      case EmotivConnectionStatus.streaming:
        return 'Streaming';
      case EmotivConnectionStatus.error:
        return 'Error';
    }
  }

  bool get isConnected =>
      this == EmotivConnectionStatus.connected ||
      this == EmotivConnectionStatus.streaming;
}

/// EMOTIV Cortex Service using WebSocket (JSON-RPC 2.0)
class EmotivService {
  static final EmotivService _instance = EmotivService._internal();
  factory EmotivService() => _instance;
  EmotivService._internal();

  final DeviceFeedbackService _feedbackService = DeviceFeedbackService();
  final NotificationService _notificationService = NotificationService();

  // WebSocket
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  bool _wsConnected = false;

  // State
  EmotivConnectionStatus _status = EmotivConnectionStatus.disconnected;
  EmotivConnectionStatus get status => _status;

  String? _cortexToken;
  String? _sessionId;
  String? _activeHeadsetId;
  String? _userName;
  List<EmotivHeadset> _headsets = [];
  List<EmotivHeadset> get headsets => _headsets;

  /// The global BuildContext used to trigger in-app feedback.
  /// Set this from your root widget (e.g. in main app navigator).
  BuildContext? appContext;

  EmotivHeadset? get connectedHeadset {
    try {
      return _headsets.firstWhere((h) => h.id == _activeHeadsetId);
    } catch (_) {
      return null;
    }
  }

  // Mock mode
  bool _useMockData = false;
  bool get useMockData => _useMockData;
  Timer? _mockDataTimer;

  // Stream controllers
  final _statusController =
      StreamController<EmotivConnectionStatus>.broadcast();
  Stream<EmotivConnectionStatus> get statusStream => _statusController.stream;

  final _eegDataController = StreamController<EEGDataPoint>.broadcast();
  Stream<EEGDataPoint> get eegDataStream => _eegDataController.stream;

  final _metricsController = StreamController<EmotivMetrics>.broadcast();
  Stream<EmotivMetrics> get metricsStream => _metricsController.stream;

  final _headsetController = StreamController<List<EmotivHeadset>>.broadcast();
  Stream<List<EmotivHeadset>> get headsetStream => _headsetController.stream;

  // ─────────────────────────────────────────────
  // Initialization & WebSocket connection
  // ─────────────────────────────────────────────

  Future<bool> initialize() async {
    debugPrint('🧠 [EmotivService] Initializing Cortex via WebSocket...');
    _updateStatus(EmotivConnectionStatus.initializing);

    try {
      // Android requires location permission for Bluetooth
      if (Platform.isAndroid) {
        final locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          debugPrint('❌ [EmotivService] Location permission denied');
          _updateStatus(EmotivConnectionStatus.error);
          return false;
        }
      }

      final connected = await _connectWebSocket();
      if (!connected) {
        _updateStatus(EmotivConnectionStatus.error);
        return false;
      }

      _updateStatus(EmotivConnectionStatus.disconnected);
      return true;
    } catch (e) {
      debugPrint('❌ [EmotivService] Initialization error: $e');
      _updateStatus(EmotivConnectionStatus.error);
      return false;
    }
  }

  /// Open the WebSocket connection to Cortex
  Future<bool> _connectWebSocket() async {
    try {
      debugPrint(
        '🔌 [EmotivService] Connecting to ${EmotivConstants.cortexUrl}...',
      );

      // EMOTIV uses a self-signed certificate.
      // Create a custom HttpClient that trusts it for development.
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          debugPrint(
            '⚠️ [EmotivService] Accepting self-signed cert from $host:$port',
          );
          return true;
        };

      _channel = IOWebSocketChannel.connect(
        Uri.parse(EmotivConstants.cortexUrl),
        customClient: httpClient,
      );

      // Wait briefly to detect immediate connection failure
      await Future.delayed(const Duration(milliseconds: 500));

      _wsSubscription = _channel!.stream.listen(
        _onWebSocketMessage,
        onError: _onWebSocketError,
        onDone: _onWebSocketDone,
      );

      _wsConnected = true;
      debugPrint('✅ [EmotivService] WebSocket connected');
      return true;
    } catch (e) {
      debugPrint('❌ [EmotivService] WebSocket connection failed: $e');
      return false;
    }
  }

  /// Handle incoming WebSocket messages
  void _onWebSocketMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;

      if (data.containsKey('id') && data.containsKey('result')) {
        _handleResponse(data);
        return;
      }

      if (data.containsKey('id') && data.containsKey('error')) {
        _handleErrorResponse(data);
        return;
      }

      if (data.containsKey('warning')) {
        _handleWarning(data['warning'] as Map<String, dynamic>);
        return;
      }

      // Data stream event (has "eeg", "met", "pow", etc.)
      _handleDataStream(data);
    } catch (e) {
      debugPrint('❌ [EmotivService] Failed to parse message: $e\nRaw: $raw');
    }
  }

  void _onWebSocketError(dynamic error) {
    debugPrint('❌ [EmotivService] WebSocket error: $error');
    _wsConnected = false;
    _updateStatus(EmotivConnectionStatus.error);
  }

  void _onWebSocketDone() {
    debugPrint('🔌 [EmotivService] WebSocket closed');
    _wsConnected = false;
    if (_status != EmotivConnectionStatus.disconnected) {
      _updateStatus(EmotivConnectionStatus.disconnected);
    }
  }

  // ─────────────────────────────────────────────
  // Message handlers
  // ─────────────────────────────────────────────

  void _handleResponse(Map<String, dynamic> data) {
    final id = data['id'] as int?;
    final result = data['result'];

    debugPrint('📨 [EmotivService] Response for request $id');

    switch (id) {
      case EmotivConstants.getUserLoggedInRequestId:
        if (result is List && result.isNotEmpty) {
          _userName = result[0]['username'] as String?;
          debugPrint('👤 [EmotivService] User logged in: $_userName');
        }
        break;

      case EmotivConstants.loginRequestId:
        _userName = result['username'] as String?;
        debugPrint('✅ [EmotivService] Login successful: $_userName');
        break;

      case EmotivConstants.logoutRequestId:
        _userName = null;
        debugPrint('👋 [EmotivService] Logged out');
        break;

      case EmotivConstants.authorizeRequestId:
        _cortexToken = result['cortexToken'] as String?;
        debugPrint('🔑 [EmotivService] Got cortex token');
        if (_cortexToken != null) {
          _updateStatus(EmotivConnectionStatus.connected);
        }
        break;

      case EmotivConstants.queryHeadsetRequestId:
        if (result is List) {
          _headsets = result
              .map((h) => EmotivHeadset.fromJson(h as Map<String, dynamic>))
              .toList();
          debugPrint('📡 [EmotivService] Found ${_headsets.length} headset(s)');
          _headsetController.add(_headsets);
        }
        break;

      case EmotivConstants.createSessionRequestId:
        if (result is Map<String, dynamic>) {
          _sessionId = result['id'] as String?;
          debugPrint('📝 [EmotivService] Session created: $_sessionId');
        }
        break;

      case EmotivConstants.subscribeDataRequestId:
        debugPrint('✅ [EmotivService] Subscribed to data streams');
        _updateStatus(EmotivConnectionStatus.streaming);
        break;

      case EmotivConstants.updateSessionRequestId:
        debugPrint('📝 [EmotivService] Session updated');
        break;

      default:
        debugPrint('📨 [EmotivService] Unhandled response for request $id');
    }
  }

  void _handleErrorResponse(Map<String, dynamic> data) {
    final id = data['id'];
    final error = data['error'] as Map<String, dynamic>?;
    final code = error?['code'];
    final message = error?['message'];
    debugPrint('❌ [EmotivService] Request $id error [$code]: $message');
  }

  /// Handles headset connect/disconnect warnings and triggers the
  /// appropriate user-facing feedback (vibration, ring, notification, or none)
  /// based on the user's saved DeviceFeedbackType preference.
  void _handleWarning(Map<String, dynamic> warning) {
    final code = warning['code'] as int?;
    final message = warning['message'];
    debugPrint('⚠️ [EmotivService] Warning $code: $message');

    switch (code) {
      case EmotivConstants.headsetIsConnected:
        final headsetId = (message is Map) ? message['headsetId'] : null;
        _activeHeadsetId = headsetId as String?;
        debugPrint('🎧 [EmotivService] Headset connected: $_activeHeadsetId');
        queryHeadsets();

        // ── Trigger user feedback for headset connection ──
        _onHeadsetConnectionEvent(connected: true);
        break;

      case EmotivConstants.headsetIsDisconnected:
        debugPrint('🔌 [EmotivService] Headset disconnected');
        _activeHeadsetId = null;
        queryHeadsets();

        // ── Trigger user feedback for headset disconnection ──
        _onHeadsetConnectionEvent(connected: false);
        break;
    }
  }

  /// Dispatches the correct feedback action based on the user's preference.
  Future<void> _onHeadsetConnectionEvent({required bool connected}) async {
    final ctx = appContext;
    final feedbackType = await _feedbackService.getFeedbackType();

    if (feedbackType == DeviceFeedbackType.notification) {
      // Special case: show a local push instead of the snackbar banner
      final title = connected
          ? '🧠 EMOTIV Headset Connected'
          : '🔌 EMOTIV Headset Disconnected';
      final body = connected
          ? 'Your headset is ready. CalmTrace can now track your EEG.'
          : 'Your headset was disconnected from CalmTrace.';
      await _notificationService.showLocalNotification(
        title: title,
        body: body,
      );
    } else if (ctx != null && ctx.mounted) {
      // vibration, ring, none — all handled by existing triggerFeedback
      await _feedbackService.triggerFeedback(ctx);
    }
  }

  void _handleDataStream(Map<String, dynamic> data) {
    if (data.containsKey('eeg')) _processEEGData(data['eeg']);
    if (data.containsKey('met')) _processMetricsData(data['met']);
    if (data.containsKey('pow')) _processBandPowerData(data['pow']);
  }

  void _processEEGData(dynamic eegData) {
    if (eegData is! List) return;

    const channelNames = [
      'AF3',
      'F7',
      'F3',
      'FC5',
      'T7',
      'P7',
      'O1',
      'O2',
      'P8',
      'T8',
      'FC6',
      'F4',
      'F8',
      'AF4',
    ];

    final channels = <String, double>{};
    for (int i = 0; i < min(channelNames.length, eegData.length - 2); i++) {
      if (eegData[i + 2] is num) {
        channels[channelNames[i]] = (eegData[i + 2] as num).toDouble();
      }
    }

    _eegDataController.add(
      EEGDataPoint(channels: channels, timestamp: DateTime.now()),
    );
  }

  void _processMetricsData(dynamic metData) {
    if (metData is! List || metData.length < 12) return;

    final metrics = EmotivMetrics(
      engagement: (metData[0] as num?)?.toDouble(),
      excitement: (metData[2] as num?)?.toDouble(),
      interest: (metData[4] as num?)?.toDouble(),
      stress: (metData[6] as num?)?.toDouble(),
      relaxation: (metData[8] as num?)?.toDouble(),
      focus: (metData[10] as num?)?.toDouble(),
      timestamp: DateTime.now(),
    );

    _metricsController.add(metrics);
    debugPrint('📊 [EmotivService] Metrics: $metrics');
  }

  void _processBandPowerData(dynamic powData) {
    debugPrint('📊 [EmotivService] Band power data received');
  }

  // ─────────────────────────────────────────────
  // Send requests
  // ─────────────────────────────────────────────

  void sendRequestToCortex(String json) {
    if (!_wsConnected || _channel == null) {
      debugPrint('❌ [EmotivService] Cannot send — WebSocket not connected');
      return;
    }
    debugPrint('📤 [EmotivService] Sending: $json');
    _channel!.sink.add(json);
  }

  // ─────────────────────────────────────────────
  // API calls
  // ─────────────────────────────────────────────

  Future<void> checkUserLogin() async {
    sendRequestToCortex(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': EmotivConstants.getUserLoggedInRequestId,
        'method': 'getUserLogin',
      }),
    );
  }

  /// Authorize and get cortex token
  Future<void> authorize() async {
    debugPrint('🔐 [EmotivService] Authorizing...');

    final params = <String, dynamic>{
      'clientId': EmotivConstants.clientId,
      'clientSecret': EmotivConstants.clientSecret,
      'debit': EmotivConstants.debitNumber,
    };

    if (EmotivConstants.licenseId.isNotEmpty) {
      params['license'] = EmotivConstants.licenseId;
    }

    sendRequestToCortex(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': EmotivConstants.authorizeRequestId,
        'method': 'authorize',
        'params': params,
      }),
    );
  }

  void logout() {
    if (_userName == null) return;
    sendRequestToCortex(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': EmotivConstants.logoutRequestId,
        'method': 'logout',
        'params': {'username': _userName},
      }),
    );
  }

  void queryHeadsets() {
    debugPrint('🔍 [EmotivService] Querying headsets...');
    sendRequestToCortex(
      jsonEncode({
        'id': EmotivConstants.queryHeadsetRequestId,
        'jsonrpc': '2.0',
        'method': 'queryHeadsets',
      }),
    );
  }

  Future<void> connectHeadset(String headsetId, BuildContext? context) async {
    debugPrint('🔗 [EmotivService] Connecting to headset: $headsetId');
    sendRequestToCortex(
      jsonEncode({
        'id': EmotivConstants.controlDeviceRequestId,
        'jsonrpc': '2.0',
        'method': 'controlDevice',
        'params': {'command': 'connect', 'headset': headsetId},
      }),
    );
    // Note: actual feedback fires in _onHeadsetConnectionEvent
    // when the server confirms with warning code 104.
  }

  void disconnectHeadset(String headsetId) {
    debugPrint('🔌 [EmotivService] Disconnecting headset: $headsetId');
    sendRequestToCortex(
      jsonEncode({
        'id': EmotivConstants.controlDeviceRequestId,
        'jsonrpc': '2.0',
        'method': 'controlDevice',
        'params': {'command': 'disconnect', 'headset': headsetId},
      }),
    );
  }

  Future<void> createSession() async {
    if (_cortexToken == null || _activeHeadsetId == null) {
      debugPrint(
        '❌ [EmotivService] Cannot create session — missing token or headset',
      );
      return;
    }

    debugPrint('📝 [EmotivService] Creating session...');
    sendRequestToCortex(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': EmotivConstants.createSessionRequestId,
        'method': 'createSession',
        'params': {
          'cortexToken': _cortexToken,
          'headset': _activeHeadsetId,
          'status': 'active',
        },
      }),
    );
  }

  void subscribeData({
    bool eeg = true,
    bool metrics = true,
    bool bandPower = false,
    bool motion = false,
  }) {
    if (_cortexToken == null || _sessionId == null) {
      debugPrint(
        '❌ [EmotivService] Cannot subscribe — missing token or session',
      );
      return;
    }

    final streams = <String>[
      if (eeg) 'eeg',
      if (metrics) 'met',
      if (bandPower) 'pow',
      if (motion) 'mot',
    ];

    debugPrint('📊 [EmotivService] Subscribing to: $streams');
    sendRequestToCortex(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': EmotivConstants.subscribeDataRequestId,
        'method': 'subscribe',
        'params': {
          'cortexToken': _cortexToken,
          'session': _sessionId,
          'streams': streams,
        },
      }),
    );
  }

  void unsubscribeData({List<String>? streams}) {
    if (_cortexToken == null || _sessionId == null) return;

    sendRequestToCortex(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': EmotivConstants.unsubscribeDataRequestId,
        'method': 'unsubscribe',
        'params': {
          'cortexToken': _cortexToken,
          'session': _sessionId,
          'streams': streams ?? ['eeg', 'met', 'pow'],
        },
      }),
    );
  }

  void closeSession() {
    if (_cortexToken == null || _sessionId == null) return;
    debugPrint('📝 [EmotivService] Closing session...');
    sendRequestToCortex(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': EmotivConstants.updateSessionRequestId,
        'method': 'updateSession',
        'params': {
          'cortexToken': _cortexToken,
          'session': _sessionId,
          'status': 'close',
        },
      }),
    );

    _sessionId = null;
    _updateStatus(EmotivConnectionStatus.connected);
  }

  // ─────────────────────────────────────────────
  // Full connection flow
  // ─────────────────────────────────────────────

  Future<bool> fullConnect(BuildContext context) async {
    appContext = context;
    final initialized = await initialize();
    if (!initialized) return false;

    await checkUserLogin();
    await Future.delayed(const Duration(seconds: 1));

    await authorize();
    await Future.delayed(const Duration(seconds: 2));

    queryHeadsets();
    return true;
  }

  // ─────────────────────────────────────────────
  // Mock mode
  // ─────────────────────────────────────────────

  Future<bool> connectMock(BuildContext? context) async {
    debugPrint('🎭 [EmotivService] Connecting with mock data...');
    if (context != null) appContext = context;

    _useMockData = true;
    _activeHeadsetId = 'MOCK-EPOC-001';
    _headsets = [
      EmotivHeadset(id: 'MOCK-EPOC-001', isVirtual: true, status: 'connected'),
    ];
    _headsetController.add(_headsets);
    _updateStatus(EmotivConnectionStatus.connected);

    // Simulate the connection event feedback for mock mode too
    await _onHeadsetConnectionEvent(connected: true);

    debugPrint('✅ [EmotivService] Mock connection established');
    return true;
  }

  void startMockStreaming() {
    if (!_useMockData) return;

    debugPrint('🎭 [EmotivService] Starting mock data stream...');
    _updateStatus(EmotivConnectionStatus.streaming);

    _mockDataTimer?.cancel();
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final random = Random();
      final now = DateTime.now();

      final eegData = EEGDataPoint(
        channels: {
          'AF3': random.nextDouble() * 100,
          'F7': random.nextDouble() * 100,
          'F3': random.nextDouble() * 100,
          'FC5': random.nextDouble() * 100,
          'T7': random.nextDouble() * 100,
          'P7': random.nextDouble() * 100,
          'O1': random.nextDouble() * 100,
          'O2': random.nextDouble() * 100,
          'P8': random.nextDouble() * 100,
          'T8': random.nextDouble() * 100,
          'FC6': random.nextDouble() * 100,
          'F4': random.nextDouble() * 100,
          'F8': random.nextDouble() * 100,
          'AF4': random.nextDouble() * 100,
        },
        timestamp: now,
        theta: 5 + random.nextDouble() * 10,
        alpha: 8 + random.nextDouble() * 15,
        betaL: 12 + random.nextDouble() * 8,
        betaH: 18 + random.nextDouble() * 12,
        gamma: 30 + random.nextDouble() * 10,
      );
      _eegDataController.add(eegData);

      if (now.second % 2 == 0 && now.millisecond < 500) {
        _metricsController.add(
          EmotivMetrics(
            engagement: 0.4 + random.nextDouble() * 0.4,
            excitement: 0.3 + random.nextDouble() * 0.3,
            stress: 0.2 + random.nextDouble() * 0.5,
            relaxation: 0.3 + random.nextDouble() * 0.4,
            interest: 0.4 + random.nextDouble() * 0.3,
            focus: 0.5 + random.nextDouble() * 0.3,
            timestamp: now,
          ),
        );
      }
    });
  }

  void stopMockStreaming() {
    _mockDataTimer?.cancel();
    _mockDataTimer = null;
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  void _updateStatus(EmotivConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
    debugPrint('🧠 [EmotivService] Status → ${newStatus.label}');
  }

  String getSetupInstructions() => '''
To connect your EMOTIV headset:

1. Install EMOTIV App on your computer (Cortex runs on desktop)
2. Create an account at emotiv.com
3. Register a Cortex App at emotiv.com/developer
4. Add credentials to .env as EMOTIV_API_KEY and EMOTIV_API_SECRET
5. Launch EMOTIV App — starts the Cortex server on localhost:6868
6. Pair your headset via the EMOTIV App
7. Run CalmTrace and connect

Supported headsets: EPOC X, EPOC+, EPOC Flex, INSIGHT, INSIGHT 2.0, MN8
''';

  // ─────────────────────────────────────────────
  // Disconnect & dispose
  // ─────────────────────────────────────────────

  Future<void> disconnect() async {
    debugPrint('🔌 [EmotivService] Disconnecting...');

    stopMockStreaming();

    if (_sessionId != null) closeSession();
    if (_activeHeadsetId != null && !_useMockData) {
      disconnectHeadset(_activeHeadsetId!);
    }

    await _wsSubscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _wsConnected = false;

    _cortexToken = null;
    _sessionId = null;
    _activeHeadsetId = null;
    _useMockData = false;
    _headsets = [];

    _updateStatus(EmotivConnectionStatus.disconnected);
  }

  void dispose() {
    stopMockStreaming();
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _statusController.close();
    _eegDataController.close();
    _metricsController.close();
    _headsetController.close();
  }
}
