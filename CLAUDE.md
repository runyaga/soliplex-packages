# soliplex-packages

Shared packages for Soliplex — LLM completions, scripting, MCP, CLI, TUI.

Core agent packages live in [runyaga/soliplex-agent](https://github.com/runyaga/soliplex-agent).

## Quick Reference

```bash
dart pub get                          # Install dependencies (workspace)
dart format .                         # Format code
dart analyze --fatal-infos            # Analyze
dart test                             # Run tests
```

## Package Structure

```text
packages/
  soliplex_completions/      # LLM providers (Anthropic, OpenAI, Ollama)
  soliplex_scripting/        # Plugin system + scripting environment
  soliplex_interpreter_monty/# Monty Python bridge
  soliplex_dataframe/        # DataFrame engine
  soliplex_mcp/              # MCP connection manager
  soliplex_schema/           # Feature schema bridge
  soliplex_cli/              # Interactive CLI REPL
  soliplex_tui/              # Rich terminal UI
```

## Development Rules

- KISS, YAGNI, SOLID
- Match surrounding code style
- Never use `// ignore:` directives
- Pure Dart only (no Flutter) except where noted
- Use `mocktail` for mocking
