import 'package:dart_monty/dart_monty_bridge.dart' show HostFunctionSchema;
import 'package:meta/meta.dart';

/// Pairs the Monty function name with the ToolRegistry lookup name.
///
/// - [pythonName]: The `kind` field — what Python calls
///   (e.g. `get_current_datetime`)
/// - [registryName]: The `tool_name` field — the tool protocol lookup key
///   (e.g. `soliplex.tools.get_current_datetime`)
/// - [schema]: The [HostFunctionSchema] registered with the bridge
@immutable
class ToolNameMapping {
  const ToolNameMapping({
    required this.pythonName,
    required this.registryName,
    required this.schema,
  });

  /// Function name callable from Python code.
  final String pythonName;

  /// Tool name used for ToolRegistry lookup.
  final String registryName;

  /// Host function schema for the bridge.
  final HostFunctionSchema schema;
}
