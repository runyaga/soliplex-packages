# soliplex-packages

Shared Dart packages for Soliplex. As of the
`chore/retire-superseded-packages` cleanup, this workspace holds only:

```text
packages/
  soliplex_interpreter_monty/  # Play-button-style execution wrapper around
                               # MontyPlatform; consumed by llama_monty for
                               # routing LLM completions through the bridge.
```

Earlier members of this workspace — `soliplex_scripting`, `soliplex_cli`,
`soliplex_tui`, `soliplex_mcp`, `soliplex_completions`, `soliplex_dataframe`,
`soliplex_schema`, `soliplex_showcase` — have been retired. The Monty
extension story now lives in `runyaga/dart_monty_labs` (the HHG ecosystem
on top of `dart_monty 0.17.1`); the Soliplex backend bridge is captured by
`soliplex_monty_plugin` on the
`runyaga/soliplex-frontend@feat/soliplex-plugin` branch and is targeted to
land as `hhg_soliplex` in `dart_monty_labs`. See git history before this
commit for the retired sources.

## Quick Reference

```bash
dart pub get
dart format .
dart analyze --fatal-infos
dart test
```

## Development Rules

- KISS, YAGNI, SOLID
- Match surrounding code style
- Never use `// ignore:` directives
- Pure Dart only (no Flutter)
- Use `mocktail` for mocking
