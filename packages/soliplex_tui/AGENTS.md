# soliplex_tui — Agent Guide

Rich terminal UI and headless runner for Soliplex agents.

## Quick Start

```bash
# Interactive TUI
dart run bin/soliplex_tui.dart

# Headless single prompt
dart run bin/soliplex_tui.dart -p "What time is it?"

# Headless multi-turn (same thread)
dart run bin/soliplex_tui.dart --room plain \
  -p "Remember: x = 42" \
  -p "What is x * 2?"

# JSON output
dart run bin/soliplex_tui.dart --json -p "Hello"

# List rooms
dart run bin/soliplex_tui.dart --list-rooms
```

## Connection

```bash
--server, -s  Backend URL (default: http://localhost:8000)
--room, -r    Room ID (uses first room if omitted)
--thread, -t  Thread ID (creates new if omitted)
--log-file    Log path (default: /tmp/soliplex_tui.log)
--verbose, -v Print run state events to stderr
```

## Modes

### Interactive TUI

```bash
dart run bin/soliplex_tui.dart --room plain
```

Rich nocterm-based terminal UI with scrollable chat, streaming text, and tool status.

### Headless (plain text)

```bash
dart run bin/soliplex_tui.dart -p "prompt"
```

Prints assistant response to stdout, exits.

### Headless (JSON)

```bash
dart run bin/soliplex_tui.dart --json -p "prompt"
```

Output format:
```json
{
  "status": "ok",
  "turns": 1,
  "wall_time_ms": 1234,
  "agent_result": "response text",
  "tool_calls": [{"id": "tc-1", "name": "tool", "arguments": "{}"}]
}
```

### Debug (stdin)

```bash
echo "Hello" | dart run bin/soliplex_tui.dart --debug
```

### List Rooms

```bash
dart run bin/soliplex_tui.dart --list-rooms
```

## Tool Configuration

```bash
--no-tools       Don't advertise client tools
--tools          Comma-separated tool names
--auto-approve   Auto-approve all tool requests (headless only)
```

Built-in demo tools: `secret_number` (returns 42), `echo` (echoes text).

## Local LLM Mode (requires --monty)

```bash
--llm-provider   ollama | anthropic | openai
--llm-model      Model name
--llm-url        API base URL
--llm-api-key    API key (or ANTHROPIC_API_KEY / OPENAI_API_KEY env)
--llm-system-prompt  Custom system prompt
```

## Monty Python Mode

```bash
dart run bin/soliplex_tui.dart --monty --room plain
dart run bin/soliplex_tui.dart --monty --prelude utils.py
dart run bin/soliplex_tui.dart --monty --execution-timeout 60
```

## MCP Server Integration (requires --monty)

```bash
# Stdio server
dart run bin/soliplex_tui.dart --monty --mcp weather="python weather_server.py"

# HTTP server
dart run bin/soliplex_tui.dart --monty --mcp api="https://api.example.com/mcp"

# Multiple servers
dart run bin/soliplex_tui.dart --monty \
  --mcp weather="python weather_server.py" \
  --mcp search="python search_server.py"
```

## Experiments

### 1. Multi-Turn State Persistence

```bash
dart run bin/soliplex_tui.dart --room plain \
  -p "Remember: the password is SESAME" \
  -p "What is the password?" \
  -p "How many letters does it have?"
```

Expected: SESAME, 6.

### 2. Multi-Turn with JSON Tracking

```bash
dart run bin/soliplex_tui.dart --room plain --json \
  -p "Call the secret_number tool" \
  -p "Double that number" \
  -p "Is the result divisible by 7?"
```

Expected: JSON with `turns: 3`, tool_calls in first turn.

### 3. Server-Side Tool Chain

```bash
dart run bin/soliplex_tui.dart --room plain \
  -p "What time is it?" \
  -p "What timezone is that in?" \
  -p "Convert it to EST"
```

### 4. Tool Filtering

```bash
# Only expose echo tool
dart run bin/soliplex_tui.dart --room plain --tools echo \
  -p "Call the echo tool with text 'hello world'" \
  -p "Now call secret_number"
```

Expected: echo works, secret_number not available.

### 5. Headless Pipeline (scripted multi-turn)

```bash
# Build context across turns, extract final answer
dart run bin/soliplex_tui.dart --room plain --json \
  -p "I'm planning a trip. My budget is $3000." \
  -p "I want to go somewhere warm in Europe." \
  -p "Suggest 3 destinations with estimated costs." \
  | jq '.agent_result'
```

### 6. Debug Mode (stdin pipe)

```bash
echo "What is 2 + 2?" | dart run bin/soliplex_tui.dart --debug --room echo
```

### 7. Verbose Event Tracing

```bash
dart run bin/soliplex_tui.dart --verbose --room plain \
  -p "What time is it?" 2>events.log
cat events.log
```

### 8. Monty Python Multi-Turn (requires --monty)

```bash
dart run bin/soliplex_tui.dart --monty --room plain \
  -p "Define a Python class called Counter with increment and get methods" \
  -p "Create a counter, increment it 5 times, show the value" \
  -p "Add a decrement method and call it twice"
```

Expected: persistent Python state across all 3 turns.

### 9. Room Discovery + Targeted Prompt

```bash
# List rooms, then use one
dart run bin/soliplex_tui.dart --list-rooms
dart run bin/soliplex_tui.dart --room chat -p "Search for authentication docs"
```

### 10. Wall Time Benchmarking

```bash
# Compare response times across rooms
for room in echo plain chat; do
  echo "--- $room ---"
  dart run bin/soliplex_tui.dart --room $room --json \
    -p "Hello" | jq '.wall_time_ms'
done
```
