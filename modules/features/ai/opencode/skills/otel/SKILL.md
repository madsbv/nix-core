---
name: otel
description: >
  OpenTelemetry instrumentation guidance for projects: which logging
  libraries to use for autoinstrumentation compatibility, when to use the otel
  SDK, and when to add metrics. Use when writing or reviewing code that logs,
  traces, or emits metrics, or when deciding whether to add otel to a project.
---

# OpenTelemetry Instrumentation

Autoinstrumentation (OpenTelemetry operator) is the baseline — code should be
logging-framework-compatible so traces/logs get captured without manual wiring.

## Logging library choice

Use a logging framework compatible with otel autoinstrumentation:

| Language | Library |
|----------|---------|
| Python   | stdlib `logging` |
| Rust     | `tracing` |
| Other    | pick the ecosystem-standard lib autoinstrumentation hooks into |

Avoid `print`/`println!`/ad-hoc stdout logging — not captured cleanly.

## Whether to use the otel SDK

- **Project already imports otel SDK:** use it. Enrich logs + traces (spans,
  attributes, context). Consider defining a metric if the problem has a
  countable/measurable dimension worth tracking.
- **Existing project WITHOUT otel SDK:** do NOT add it yourself. Still log
  thoroughly via the autoinstrumentation-compatible logging lib above.
- **New project:** ask the user whether to include the otel SDK from the start.

## Metrics

Only add a metric when there's a real measurable dimension (request count,
latency, queue depth, error rate). Don't instrument for its own sake.
