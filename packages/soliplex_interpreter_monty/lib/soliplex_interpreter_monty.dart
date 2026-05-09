/// Bridge Monty sandboxed Python interpreter into Soliplex (pure Dart).
library;

// Re-export bridge infrastructure from dart_monty's bridge layer.
export 'package:dart_monty/dart_monty_bridge.dart'
    show
        BridgeCallFinished,
        BridgeCallStarted,
        BridgeChildEvent,
        BridgeEvent,
        BridgeFunctionCallArgs,
        BridgeFunctionCallEnd,
        BridgeFunctionCallResult,
        BridgeFunctionCallStart,
        BridgeFunctionEmit,
        BridgeOsCallResult,
        BridgeOsCallStart,
        BridgeRunError,
        BridgeRunFinished,
        BridgeRunStarted,
        HostFunction,
        HostFunctionHandler,
        HostFunctionSchema,
        HostParam,
        HostParamType,
        MontyBridge,
        MontyExtension;

// Soliplex-only types.
export 'src/bridge/tool_definition_converter.dart';
export 'src/console_event.dart';
export 'src/execution_result.dart';
export 'src/input_variable.dart';
export 'src/monty_execution_service.dart';
export 'src/monty_limits_defaults.dart';
export 'src/schema_executor.dart';
