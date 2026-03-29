import 'package:dart_monty/dart_monty.dart';
import 'package:nocterm/nocterm.dart';
import 'package:soliplex_agent/soliplex_agent.dart';
import 'package:soliplex_client/soliplex_client.dart'
    show DartHttpClient, SoliplexApi;
import 'package:soliplex_logging/soliplex_logging.dart';
import 'package:soliplex_scripting/soliplex_scripting.dart';
import 'package:soliplex_tui/src/components/chat_page.dart';
import 'package:soliplex_tui/src/services/tui_ui_delegate.dart';
import 'package:soliplex_tui/src/tool_definitions.dart';

/// Web platform constraints (WASM — single bridge, non-reentrant).
class WebPlatformConstraints implements PlatformConstraints {
  const WebPlatformConstraints();

  @override
  bool get supportsParallelExecution => false;

  @override
  bool get supportsAsyncMode => false;

  @override
  int get maxConcurrentBridges => 1;

  @override
  bool get supportsReentrantInterpreter => false;
}

/// Minimal HostApi for web — no native shell/file/clipboard.
/// DataFrames and charts stored in memory.
class WebHostApi implements HostApi {
  final Map<int, Map<String, List<Object?>>> _dataFrames = {};
  final Map<int, Map<String, Object?>> _charts = {};
  int _nextHandle = 1;

  @override
  int registerDataFrame(Map<String, List<Object?>> columns) {
    final handle = _nextHandle++;
    _dataFrames[handle] = Map.unmodifiable(columns);
    return handle;
  }

  @override
  Map<String, List<Object?>>? getDataFrame(int handle) => _dataFrames[handle];

  @override
  int registerChart(Map<String, Object?> chartConfig) {
    final handle = _nextHandle++;
    _charts[handle] = chartConfig;
    return handle;
  }

  @override
  bool updateChart(int chartId, Map<String, Object?> chartConfig) {
    if (!_charts.containsKey(chartId)) return false;
    _charts[chartId] = chartConfig;
    return true;
  }

  @override
  Future<Object?> invoke(String name, Map<String, Object?> args) async {
    throw UnsupportedError('Web host does not support: $name');
  }
}

/// Configuration from URL query parameters.
///
/// Supported params:
///   ?server=http://...   Backend URL (default: same origin via proxy)
///   ?room=echo           Room ID
///   ?tools=echo,secret_number   Comma-separated tool filter (default: all)
///   ?no-tools            Disable all client tools
///   ?monty               Enable Monty Python execution
class _WebConfig {
  _WebConfig() {
    final params = Uri.base.queryParameters;
    serverUrl = params['server'] ?? Uri.base.origin;
    room = params['room'];
    noTools = params.containsKey('no-tools');
    montyEnabled = params.containsKey('monty');
    final toolsParam = params['tools'];
    enabledTools = toolsParam?.split(',').map((s) => s.trim()).toSet();
  }

  late final String serverUrl;
  late final String? room;
  late final bool noTools;
  late final bool montyEnabled;
  late final Set<String>? enabledTools;
}

Future<void> main() async {
  final config = _WebConfig();

  final connection = ServerConnection.create(
    serverId: 'default',
    serverUrl: config.serverUrl,
    httpClient: DartHttpClient(),
  );

  // Resolve room.
  final rooms = await connection.api.getRooms();
  if (rooms.isEmpty) {
    throw StateError('No rooms available on the server.');
  }
  final roomId = config.room ?? rooms.first.id;

  // Build tool registry (same as native TUI).
  final toolRegistry = config.noTools
      ? const ToolRegistry()
      : buildDemoToolRegistry(enabledTools: config.enabledTools);

  final uiDelegate = TuiUiDelegate();
  final hostApi = WebHostApi();

  // Monty wiring (optional — enabled via ?monty query param).
  SessionExtensionFactory? extensionFactory;
  if (config.montyEnabled) {
    extensionFactory = () async {
      final factory = createMontyScriptEnvironmentFactory(
        hostApi: hostApi,
        httpClient: DartHttpClient(),
        platformFactory: () async => Monty(),
        limits: MontyLimitsDefaults.tool,
        executionTimeout: const Duration(seconds: 30),
        agentTimeout: const Duration(seconds: 30),
      );
      final env = await factory();
      return [ScriptEnvironmentExtension(env)];
    };
  }

  final runtime = AgentRuntime(
    connection: connection,
    llmProvider: AgUiLlmProvider(
      api: connection.api,
      agUiStreamClient: connection.agUiStreamClient,
    ),
    toolRegistryResolver: (_) async => toolRegistry,
    platform: const WebPlatformConstraints(),
    logger: LogManager.instance.getLogger('Web'),
    uiDelegate: uiDelegate,
    extensionFactory: extensionFactory,
  );

  await runApp(
    NoctermApp(
      title: 'Soliplex TUI',
      theme: TuiThemeData.dark,
      home: ChatPage(
        runtime: runtime,
        roomId: roomId,
        uiDelegate: uiDelegate,
      ),
    ),
  );
}
