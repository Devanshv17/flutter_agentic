# Changelog

All notable changes to `genesis_ai_sdk` will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.1] — 2026-05-29

### Fixed

- Shortened pubspec description to meet pub.dev requirements (improves pub score from 150 to 160)

---

## [0.1.0] — 2026-05-25

### Added

#### Core
- `GenesisAgent` — unified agent API with `chat()`, `stream()`, tool calling,
  and multi-turn memory.
- `GenesisHub` — one-stop factory: `fromHuggingFace()`, `fromUrl()`,
  `fromOllama()`, `fromHFCloud()`, `fromFile()`, `fromProvider()`.
- `GenesisHubPlatformPaths.platformModelsDir()` — returns the correct writable
  model directory on every platform (uses `path_provider`).

#### Providers
- `GemmaProvider` — on-device inference via `flutter_gemma` 0.16.x; supports
  `.litertlm` (all platforms), `.task` (mobile), `.tflite`, `.bin`.
- `LlamaCppProvider` — on-device GGUF inference via `llama_cpp_dart` 0.2.x;
  supports macOS, Windows, Linux, Android.
- `HFInferenceProvider` — cloud inference via the HF Inference Router with
  multi-backend support: `featherless` (default), `nebius`, `together`,
  `sambanova`, `hfNative`.
- `OllamaProvider` — local Ollama server with `pull()`, `listModels()`,
  and `checkStatus()`.
- `GeminiProvider` — Google Gemini API (cloud).
- `OpenAIProvider` — OpenAI API (cloud, any OpenAI-compatible endpoint).
- `AnthropicProvider` — Anthropic Claude API (cloud).

#### Hub / Model Management
- `ModelFormat` — enum covering all formats: `litertlm`, `task`, `gguf`,
  `tflite`, `binary`, `safetensors`, `onnx`, `ollama`, `hfInference`, with
  auto-detection via `ModelFormat.detect()`.
- `HFHub` — HuggingFace Hub client: `modelInfo()`, `listFiles()`,
  `downloadUrl()`, `parseUrl()`, `inferenceUrl()`.
- `UniversalModelManager` — `downloadFromUrl()`, `downloadFromHF()`,
  `pullOllamaModel()`, `providerForFile()`, `isDownloaded()`, `deleteModel()`.

#### Tools & ReAct
- `GenesisTool` / `ToolParam` — define callable tools with typed parameters.
- ReAct loop with configurable max steps and graceful fallback.

#### Memory
- `InMemoryStore` — lightweight in-process message history.
- `HiveMemoryStore` — persistent cross-session memory backed by Hive.

#### Safety
- `InputGuard` — block / rewrite prompts before they reach the model.
- `OutputGuard` — validate / sanitize model responses.
- `RateLimiter` — token-bucket rate limiting.
- `ConcurrencyLimiter` — cap parallel requests.

#### Routing
- `SmartRouter` — latency/quality-based provider selection.
- `PrivacyRouter` — route sensitive prompts to on-device providers
  automatically.

#### Platform
- Full platform support table (`litertlm` on all platforms, `task` on mobile
  only, `gguf` on all except iOS pending xcframework build).
- `PLATFORM_SETUP.md` — step-by-step setup guide for macOS, iOS, Android,
  Windows, Linux.

[0.1.0]: https://github.com/Devanshv17/genesis_ai/releases/tag/v0.1.0
