# soliplex_cli — Agent Guide

Interactive REPL and headless runner for Soliplex agents.

## Quick Start

```bash
# Interactive REPL against local backend
dart run bin/soliplex_cli.dart

# Single prompt, print result, exit
dart run bin/soliplex_cli.dart -p "What time is it?"

# Multi-turn (same thread, shared state)
dart run bin/soliplex_cli.dart --room plain \
  -p "Call the secret_number tool" \
  -p "Now multiply that by 3"
```

## Connection

```bash
--host, -H    Backend URL (env: SOLIPLEX_BASE_URL, default: http://localhost:8000)
--room, -r    Default room (env: SOLIPLEX_ROOM_ID, default: plain)
--verbose, -v Log HTTP traffic to stderr
--log-file    Structured log output path
```

## Tool Configuration

```bash
--no-tools    Don't advertise client tools
--tools, -t   Comma-separated tool names (filters demo tools)
```

Built-in demo tools: `secret_number` (returns 42), `echo` (echoes text).

## Headless Mode

```bash
# Single prompt
dart run bin/soliplex_cli.dart -p "Hello"

# Multi-turn (sequential, same thread)
dart run bin/soliplex_cli.dart -p "Define x=10" -p "What is x*2?"

# Pipe from script
for prompt in "step 1" "step 2" "step 3"; do
  dart run bin/soliplex_cli.dart -p "$prompt"
done
```

## Interactive REPL Commands

| Command | Action |
|---------|--------|
| `<text>` | Send prompt (continues current thread) |
| `/new [room] [prompt]` | Start fresh thread, optionally in a different room |
| `/room <id> <prompt>` | Send to specific room |
| `/rooms` | List available rooms |
| `/spawn <prompt>` | Background session (ephemeral thread) |
| `/waitall` | Wait for all background sessions |
| `/waitany` | Wait for first to complete (race) |
| `/cancel` | Cancel all background sessions |
| `/sessions` | List active sessions |
| `/thread` | Show active threads per room |
| `/examples` | Usage walkthrough |
| `/help` | Show commands |
| `/quit` | Exit |

## Local LLM Mode (bypass backend)

```bash
# Ollama (default model: qwen3:8b)
dart run bin/soliplex_cli.dart --llm-provider ollama

# Anthropic
dart run bin/soliplex_cli.dart --llm-provider anthropic --llm-api-key sk-ant-...

# OpenAI
dart run bin/soliplex_cli.dart --llm-provider openai --llm-api-key sk-...

# Custom Ollama endpoint + model
dart run bin/soliplex_cli.dart --llm-provider ollama \
  --llm-model qwen3:30b --llm-url http://bizon:11434/v1
```

## Monty Python Mode

```bash
# Enable execute_python tool
dart run bin/soliplex_cli.dart --monty --room plain

# With WASM constraints (single bridge)
dart run bin/soliplex_cli.dart --monty --wasm-mode

# With prelude (inject utility functions)
dart run bin/soliplex_cli.dart --monty --prelude utils.py

# Custom timeout
dart run bin/soliplex_cli.dart --monty --exec-timeout 60
```

## Parallel Agents

In the interactive REPL:

```
/spawn Summarize document A
/spawn Summarize document B
/spawn Summarize document C
/waitall
```

Or programmatically — see `example/parallel_agents.dart`.

## Experiments

### 1. Multi-Turn State Persistence

Verify the agent maintains conversation context across turns.

```bash
dart run bin/soliplex_cli.dart --room plain \
  -p "Remember: the secret word is BANANA" \
  -p "What is the secret word?" \
  -p "Spell it backwards"
```

Expected: second turn returns BANANA, third returns ANANAB.

### 2. Client-Side Tool Execution

Verify `secret_number` tool is called and result incorporated.

```bash
dart run bin/soliplex_cli.dart --room plain \
  -p "Call the secret_number tool and tell me the result" \
  -p "Is that number even or odd?" \
  -p "What is the square root of that number?"
```

Expected: 42, even, ~6.48.

### 3. Server-Side Tool (datetime)

Verify server-side tools don't yield to client.

```bash
dart run bin/soliplex_cli.dart --room plain \
  -p "What time is it right now?" \
  -p "What day of the week is that?" \
  -p "How many days until the weekend?"
```

### 4. Multi-Room Conversation

Verify switching rooms starts fresh context.

```bash
# Interactive REPL
dart run bin/soliplex_cli.dart
> My name is Alice
> /new chat Tell me my name
> /room echo Say exactly: test
```

Expected: chat room doesn't know "Alice" (new thread).

### 5. Parallel Fan-Out

Verify concurrent agents complete independently.

```bash
# Interactive REPL
dart run bin/soliplex_cli.dart --room echo
> /spawn Say exactly: ALPHA
> /spawn Say exactly: BETA
> /spawn Say exactly: GAMMA
> /waitall
```

Expected: three results in any order.

### 6. Cancel Mid-Run

```bash
# Interactive REPL with plain room
dart run bin/soliplex_cli.dart --room plain
> /spawn Write a 10000 word essay about every programming language
> /cancel
> /sessions
```

Expected: session cancelled, no active sessions.

### 7. Monty Python Execution (requires --monty)

```bash
dart run bin/soliplex_cli.dart --monty --room plain \
  -p "Write a Python function to compute fibonacci numbers" \
  -p "Call fibonacci(10) and show the result" \
  -p "Now compute fibonacci(20)"
```

Expected: multi-turn with persistent Python state.

### 8. Verbose HTTP Tracing

```bash
dart run bin/soliplex_cli.dart --verbose --room echo \
  -p "Hello" 2>trace.log
cat trace.log
```

Expected: full HTTP request/response trace in trace.log.
