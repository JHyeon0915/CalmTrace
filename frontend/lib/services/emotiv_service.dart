import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cortex/cortex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_feedback_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  static const String licenseId = ''; // Optional - leave empty if not using
  static const int debitNumber = 1;
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

  /// Calculate stress indicator from band powers
  double? get stressIndicator {
    if (alpha == null || betaH == null || alpha == 0) return null;
    return (betaH! + (gamma ?? 0)) / alpha!;
  }

  /// Calculate relaxation indicator
  double? get relaxationIndicator {
    if (alpha == null || betaH == null || betaH == 0) return null;
    return (alpha! + (theta ?? 0)) / betaH!;
  }

  @override
  String toString() {
    return 'EEG(channels: ${channels.length}, stress: ${stressIndicator?.toStringAsFixed(2)})';
  }
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

  Map<String, dynamic> toJson() {
    return {
      'engagement': engagement,
      'excitement': excitement,
      'stress': stress,
      'relaxation': relaxation,
      'interest': interest,
      'focus': focus,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'EmotivMetrics(stress: ${stress?.toStringAsFixed(2)}, relaxation: ${relaxation?.toStringAsFixed(2)}, focus: ${focus?.toStringAsFixed(2)})';
  }
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

  factory EmotivHeadset.fromJson(Map<String, dynamic> json) {
    return EmotivHeadset(
      id: json['id'] ?? '',
      isVirtual: json['isVirtual'] ?? false,
      status: json['status'] ?? 'unknown',
    );
  }

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

/// EMOTIV Cortex Service using the cortex Flutter plugin
class EmotivService {
  static final EmotivService _instance = EmotivService._internal();
  factory EmotivService() => _instance;
  EmotivService._internal();

  final DeviceFeedbackService _feedbackService = DeviceFeedbackService();

  // State
  EmotivConnectionStatus _status = EmotivConnectionStatus.disconnected;
  EmotivConnectionStatus get status => _status;

  String? _cortexToken;
  String? _sessionId;
  String? _activeHeadsetId;
  String? _userName;
  List<EmotivHeadset> _headsets = [];
  List<EmotivHeadset> get headsets => _headsets;

  EmotivHeadset? get connectedHeadset {
    try {
      return _headsets.firstWhere((h) => h.id == _activeHeadsetId);
    } catch (_) {
      return null;
    }
  }

  // Mock mode for testing
  bool _useMockData = false;
  bool get useMockData => _useMockData;
  Timer? _mockDataTimer;

  // Stream subscriptions for Cortex events
  final List<StreamSubscription> _cortexSubscriptions = [];

  // Stream controllers for app usage
  final _statusController =
      StreamController<EmotivConnectionStatus>.broadcast();
  Stream<EmotivConnectionStatus> get statusStream => _statusController.stream;

  final _eegDataController = StreamController<EEGDataPoint>.broadcast();
  Stream<EEGDataPoint> get eegDataStream => _eegDataController.stream;

  final _metricsController = StreamController<EmotivMetrics>.broadcast();
  Stream<EmotivMetrics> get metricsStream => _metricsController.stream;

  final _headsetController = StreamController<List<EmotivHeadset>>.broadcast();
  Stream<List<EmotivHeadset>> get headsetStream => _headsetController.stream;

  /// Initialize Cortex and set up listeners
  Future<bool> initialize() async {
    debugPrint('🧠 [EmotivService] Initializing Cortex...');
    _updateStatus(EmotivConnectionStatus.initializing);

    try {
      // Request location permission on Android (required for Bluetooth)
      if (Platform.isAndroid) {
        final status = await Permission.location.request();
        debugPrint('📍 [EmotivService] Location permission: $status');

        if (!status.isGranted) {
          debugPrint('❌ [EmotivService] Location permission denied');
          _updateStatus(EmotivConnectionStatus.error);
          return false;
        }
      }

      // Start Cortex
      final result = await startCortex();
      debugPrint('🧠 [EmotivService] Cortex started: $result');

      if (!result) {
        _updateStatus(EmotivConnectionStatus.error);
        return false;
      }

      // Set up event listeners
      _setupEventListeners();

      _updateStatus(EmotivConnectionStatus.disconnected);
      return true;
    } catch (e) {
      debugPrint('❌ [EmotivService] Initialization error: $e');
      _updateStatus(EmotivConnectionStatus.error);
      return false;
    }
  }

  /// Set up listeners for Cortex events
  void _setupEventListeners() {
    // Response events
    _cortexSubscriptions.add(
      responseEvents.listen((event) {
        debugPrint('📨 [EmotivService] Response: ${event.getRequestId()}');
        _handleResponseEvent(event);
      }),
    );

    // Warning events
    _cortexSubscriptions.add(
      warningEvents.listen((event) {
        debugPrint('⚠️ [EmotivService] Warning: ${event.getWarningCode()}');
        _handleWarningEvent(event);
      }),
    );

    // Data stream events
    _cortexSubscriptions.add(
      dataStreamEvents.listen((event) {
        _handleDataStreamEvent(event);
      }),
    );
  }

  /// Handle response events from Cortex
  void _handleResponseEvent(dynamic event) {
    final requestId = event.getRequestId();
    final responseBody = event.getResponseBody();
    final isError = event.isResponseError();

    if (isError) {
      debugPrint('❌ [EmotivService] Request $requestId error');
      return;
    }

    switch (requestId) {
      case EmotivConstants.getUserLoggedInRequestId:
        if (responseBody is List && responseBody.isNotEmpty) {
          _userName = responseBody[0]['username'] as String?;
          debugPrint('👤 [EmotivService] User logged in: $_userName');
        }
        break;

      case EmotivConstants.loginRequestId:
        _userName = responseBody['username'] as String?;
        debugPrint('✅ [EmotivService] Login successful: $_userName');
        break;

      case EmotivConstants.logoutRequestId:
        _userName = null;
        debugPrint('👋 [EmotivService] Logged out');
        break;

      case EmotivConstants.authorizeRequestId:
        _cortexToken = responseBody['cortexToken'] as String?;
        debugPrint('🔑 [EmotivService] Got cortex token');
        if (_cortexToken != null) {
          _updateStatus(EmotivConnectionStatus.connected);
        }
        break;

      case EmotivConstants.queryHeadsetRequestId:
        _headsets = (responseBody as List)
            .map((h) => EmotivHeadset.fromJson(h as Map<String, dynamic>))
            .toList();
        debugPrint('📡 [EmotivService] Found ${_headsets.length} headsets');
        _headsetController.add(_headsets);
        break;

      case EmotivConstants.createSessionRequestId:
        _sessionId = responseBody['id'] as String?;
        debugPrint('📝 [EmotivService] Session created: $_sessionId');
        break;

      case EmotivConstants.subscribeDataRequestId:
        debugPrint('✅ [EmotivService] Subscribed to data streams');
        _updateStatus(EmotivConnectionStatus.streaming);
        break;

      default:
        debugPrint('📨 [EmotivService] Response for request $requestId');
    }
  }

  /// Handle warning events from Cortex
  void _handleWarningEvent(dynamic event) {
    final warningCode = event.getWarningCode();
    final message = event.getWarningMessage();

    switch (warningCode) {
      case EmotivConstants.headsetIsConnected:
        _activeHeadsetId = message['headsetId'] as String?;
        debugPrint('🎧 [EmotivService] Headset connected: $_activeHeadsetId');
        // Refresh headset list
        queryHeadsets();
        break;

      case EmotivConstants.headsetIsDisconnected:
        debugPrint('🔌 [EmotivService] Headset disconnected');
        _activeHeadsetId = null;
        queryHeadsets();
        break;

      default:
        debugPrint('⚠️ [EmotivService] Warning $warningCode: $message');
    }
  }

  /// Handle data stream events from Cortex
  void _handleDataStreamEvent(dynamic event) {
    final data = event.getDataStreamBody();

    if (data is Map<String, dynamic>) {
      // Check for EEG data
      if (data.containsKey('eeg')) {
        _processEEGData(data['eeg']);
      }

      // Check for performance metrics
      if (data.containsKey('met')) {
        _processMetricsData(data['met']);
      }

      // Check for band power
      if (data.containsKey('pow')) {
        _processBandPowerData(data['pow']);
      }
    }
  }

  void _processEEGData(dynamic eegData) {
    if (eegData is! List) return;

    final channelNames = [
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

    final eegPoint = EEGDataPoint(
      channels: channels,
      timestamp: DateTime.now(),
    );

    _eegDataController.add(eegPoint);
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
    // Band power can be used for additional analysis
    debugPrint('📊 [EmotivService] Band power data received');
  }

  /// Check if user is logged in
  Future<void> checkUserLogin() async {
    final json =
        '''
    { 
      "jsonrpc": "2.0",
      "id": ${EmotivConstants.getUserLoggedInRequestId},
      "method": "getUserLogin"
    }
    ''';
    sendRequestToCortex(json);
  }

  /// Login with EMOTIV account
  Future<bool> login() async {
    debugPrint('🔐 [EmotivService] Logging in...');
    _updateStatus(EmotivConnectionStatus.authenticating);

    try {
      final code = await authenticateWithCortex(EmotivConstants.clientId);
      debugPrint(
        '🔑 [EmotivService] Auth code: ${code.isNotEmpty ? "received" : "empty"}',
      );

      if (code.isEmpty) {
        _updateStatus(EmotivConnectionStatus.error);
        return false;
      }

      final json =
          '''
      { 
        "jsonrpc": "2.0",
        "id": ${EmotivConstants.loginRequestId},
        "method": "loginWithAuthenticationCode",
        "params": {
          "clientId": "${EmotivConstants.clientId}",
          "clientSecret": "${EmotivConstants.clientSecret}",
          "code": "$code"
        } 
      }
      ''';
      sendRequestToCortex(json);

      return true;
    } catch (e) {
      debugPrint('❌ [EmotivService] Login error: $e');
      _updateStatus(EmotivConnectionStatus.error);
      return false;
    }
  }

  /// Logout
  void logout() {
    if (_userName == null) return;

    final json =
        '''
    { 
      "jsonrpc": "2.0",
      "id": ${EmotivConstants.logoutRequestId},
      "method": "logout",
      "params": {
        "username": "$_userName"
      } 
    }
    ''';
    sendRequestToCortex(json);
  }

  /// Authorize and get cortex token
  Future<void> authorize() async {
    debugPrint('🔐 [EmotivService] Authorizing...');

    final licenseParam = EmotivConstants.licenseId.isNotEmpty
        ? '"license": "${EmotivConstants.licenseId}",'
        : '';

    final json =
        '''
    { 
      "jsonrpc": "2.0",
      "id": ${EmotivConstants.authorizeRequestId},
      "method": "authorize",
      "params": {
        "clientId": "${EmotivConstants.clientId}",
        "clientSecret": "${EmotivConstants.clientSecret}",
        "debit": ${EmotivConstants.debitNumber}
        $licenseParam
      } 
    }
    ''';
    sendRequestToCortex(json);
  }

  /// Query available headsets
  void queryHeadsets() {
    debugPrint('🔍 [EmotivService] Querying headsets...');

    final json =
        '''
    { 
      "id": ${EmotivConstants.queryHeadsetRequestId},
      "jsonrpc": "2.0",
      "method": "queryHeadsets"
    }
    ''';
    sendRequestToCortex(json);
  }

  /// Connect to a headset
  Future<void> connectHeadset(String headsetId, BuildContext? context) async {
    debugPrint('🔗 [EmotivService] Connecting to headset: $headsetId');

    final json =
        '''
    { 
      "id": ${EmotivConstants.controlDeviceRequestId},
      "jsonrpc": "2.0",
      "method": "controlDevice",
      "params": {
        "command": "connect",
        "headset": "$headsetId"
      }
    }
    ''';
    sendRequestToCortex(json);

    // Trigger feedback when connected
    if (context != null && context.mounted) {
      await _feedbackService.triggerFeedback(context);
    }
  }

  /// Disconnect from headset
  void disconnectHeadset(String headsetId) {
    debugPrint('🔌 [EmotivService] Disconnecting headset: $headsetId');

    final json =
        '''
    { 
      "id": ${EmotivConstants.controlDeviceRequestId},
      "jsonrpc": "2.0",
      "method": "controlDevice",
      "params": {
        "command": "disconnect",
        "headset": "$headsetId"
      }
    }
    ''';
    sendRequestToCortex(json);
  }

  /// Create a session for data streaming
  Future<void> createSession() async {
    if (_cortexToken == null || _activeHeadsetId == null) {
      debugPrint(
        '❌ [EmotivService] Cannot create session - missing token or headset',
      );
      return;
    }

    debugPrint('📝 [EmotivService] Creating session...');

    final json =
        '''
    { 
      "jsonrpc": "2.0",
      "id": ${EmotivConstants.createSessionRequestId},
      "method": "createSession",
      "params": {
        "cortexToken": "$_cortexToken",
        "headset": "$_activeHeadsetId",
        "status": "active"
      } 
    }
    ''';
    sendRequestToCortex(json);
  }

  /// Subscribe to data streams
  void subscribeData({
    bool eeg = true,
    bool metrics = true,
    bool bandPower = false,
    bool motion = false,
  }) {
    if (_cortexToken == null || _sessionId == null) {
      debugPrint(
        '❌ [EmotivService] Cannot subscribe - missing token or session',
      );
      return;
    }

    final streams = <String>[];
    if (eeg) streams.add('eeg');
    if (metrics) streams.add('met');
    if (bandPower) streams.add('pow');
    if (motion) streams.add('mot');

    debugPrint('📊 [EmotivService] Subscribing to: $streams');

    final json =
        '''
    { 
      "jsonrpc": "2.0",
      "id": ${EmotivConstants.subscribeDataRequestId},
      "method": "subscribe",
      "params": {
        "cortexToken": "$_cortexToken",
        "session": "$_sessionId",
        "streams": ${jsonEncode(streams)}
      } 
    }
    ''';
    sendRequestToCortex(json);
  }

  /// Unsubscribe from data streams
  void unsubscribeData({List<String>? streams}) {
    if (_cortexToken == null || _sessionId == null) return;

    final streamsToUnsubscribe = streams ?? ['eeg', 'met', 'pow'];

    final json =
        '''
    { 
      "jsonrpc": "2.0",
      "id": ${EmotivConstants.unsubscribeDataRequestId},
      "method": "unsubscribe",
      "params": {
        "cortexToken": "$_cortexToken",
        "session": "$_sessionId",
        "streams": ${jsonEncode(streamsToUnsubscribe)}
      } 
    }
    ''';
    sendRequestToCortex(json);
  }

  /// Close session
  void closeSession() {
    if (_cortexToken == null || _sessionId == null) return;

    debugPrint('📝 [EmotivService] Closing session...');

    final json =
        '''
    { 
      "jsonrpc": "2.0",
      "id": ${EmotivConstants.updateSessionRequestId},
      "method": "updateSession",
      "params": {
        "cortexToken": "$_cortexToken",
        "session": "$_sessionId",
        "status": "close"
      } 
    }
    ''';
    sendRequestToCortex(json);

    _sessionId = null;
    _updateStatus(EmotivConnectionStatus.connected);
  }

  /// Connect with mock data (for testing without headset)
  Future<bool> connectMock(BuildContext? context) async {
    debugPrint('🎭 [EmotivService] Connecting with mock data...');

    _useMockData = true;
    _activeHeadsetId = 'MOCK-EPOC-001';
    _headsets = [
      EmotivHeadset(id: 'MOCK-EPOC-001', isVirtual: true, status: 'connected'),
    ];
    _headsetController.add(_headsets);

    _updateStatus(EmotivConnectionStatus.connected);

    if (context != null && context.mounted) {
      await _feedbackService.triggerFeedback(context);
    }

    debugPrint('✅ [EmotivService] Mock connection established');
    return true;
  }

  /// Start mock data streaming
  void startMockStreaming() {
    if (!_useMockData) return;

    debugPrint('🎭 [EmotivService] Starting mock data stream...');
    _updateStatus(EmotivConnectionStatus.streaming);

    _mockDataTimer?.cancel();
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final random = Random();
      final now = DateTime.now();

      // Simulate EEG data
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

      // Simulate performance metrics every 2 seconds
      if (now.second % 2 == 0 && now.millisecond < 500) {
        final metrics = EmotivMetrics(
          engagement: 0.4 + random.nextDouble() * 0.4,
          excitement: 0.3 + random.nextDouble() * 0.3,
          stress: 0.2 + random.nextDouble() * 0.5,
          relaxation: 0.3 + random.nextDouble() * 0.4,
          interest: 0.4 + random.nextDouble() * 0.3,
          focus: 0.5 + random.nextDouble() * 0.3,
          timestamp: now,
        );
        _metricsController.add(metrics);
      }
    });
  }

  /// Stop mock streaming
  void stopMockStreaming() {
    _mockDataTimer?.cancel();
    _mockDataTimer = null;
  }

  void _updateStatus(EmotivConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
    debugPrint('🧠 [EmotivService] Status: ${newStatus.label}');
  }

  /// Full connection flow
  Future<bool> fullConnect(BuildContext context) async {
    // 1. Initialize
    final initialized = await initialize();
    if (!initialized) return false;

    // 2. Login
    final loggedIn = await login();
    if (!loggedIn) return false;

    // Wait for login response
    await Future.delayed(const Duration(seconds: 2));

    // 3. Authorize
    await authorize();

    // Wait for authorization
    await Future.delayed(const Duration(seconds: 2));

    // 4. Query headsets
    queryHeadsets();

    return true;
  }

  /// Get setup instructions
  String getSetupInstructions() {
    return '''
To connect your EMOTIV headset:

1. Install EMOTIV App on your phone
2. Create an account at emotiv.com
3. Pair your headset via Bluetooth
4. Get developer credentials at emotiv.com/developer
5. Update clientId and clientSecret in the app
6. Ensure headset sensors have good contact

Supported headsets:
- EMOTIV EPOC X
- EMOTIV EPOC+
- EMOTIV EPOC Flex
- EMOTIV INSIGHT
- EMOTIV MN8
''';
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    debugPrint('🔌 [EmotivService] Disconnecting...');

    stopMockStreaming();

    if (_sessionId != null) {
      closeSession();
    }

    if (_activeHeadsetId != null && !_useMockData) {
      disconnectHeadset(_activeHeadsetId!);
    }

    _cortexToken = null;
    _sessionId = null;
    _activeHeadsetId = null;
    _useMockData = false;
    _headsets = [];

    _updateStatus(EmotivConnectionStatus.disconnected);
  }

  void dispose() {
    stopMockStreaming();

    for (final sub in _cortexSubscriptions) {
      sub.cancel();
    }
    _cortexSubscriptions.clear();

    _statusController.close();
    _eegDataController.close();
    _metricsController.close();
    _headsetController.close();
  }
}
