# Lanthic Studio: System Architecture, Iteration History & Blockers Context

> **Target Audience**: Technical ideation and architecture review with Claude, Argon, and Codex.  
> **Repository**: `lanthic_studio` (Flutter Desktop / Web)  
> **Timestamp**: 2026-10-15  

---

## 1. Executive Summary & Purpose

**Lanthic Studio** is an open-source visual narrative production workstation built with Flutter. It orchestrates an 8-phase storytelling and visual asset pipeline, providing visual node-graph orchestration, script review, visual continuity validation, and image synthesis.

The studio operates locally on native filesystem directories structured around story projects (e.g., `the_signature_in_the_lining`, `sample_story`). It allows directors and writers to edit narratives, adjust visual direction, inspect continuity, and "cook" (synthesize) image scenes via AI vision providers.

---

## 2. System Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│                                                                        │
│  ┌───────────────────────┐  ┌────────────────┐  ┌───────────────────┐  │
│  │ StudioNodeGraphView   │  │ ReviewScreen   │  │ ContinuityScreen  │  │
│  │ (Bezier Canvas, Nodes)│  │ (Reader / Edit)│  │ (Validation grid) │  │
│  └───────────┬───────────┘  └───────┬────────┘  └─────────┬─────────┘  │
└──────────────┼──────────────────────┼─────────────────────┼────────────┘
               │                      │                     │
               ▼                      ▼                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        APPLICATION / DOMAIN                            │
│                                                                        │
│  ┌───────────────────────────────┐  ┌───────────────────────────────┐  │
│  │  LanthicPipelineOrchestrator  │  │     RegenerationService       │  │
│  │  - Step execution (Phases 1-8)│  │     - Phase 6 Payload Builder │  │
│  │  - State & dependency graph   │  │     - Prompt Sanitizer        │  │
│  └───────────────┬───────────────┘  └───────────────┬───────────────┘  │
│                  │                                  │                  │
│                  ▼                                  ▼                  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Domain Aggregates: AggregatedScene, SceneModel,                  │  │
│  │ GenerationManifestModel, VisualDirectionModel, ContinuityModel   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        DATA & INFRASTRUCTURE                           │
│                                                                        │
│  ┌───────────────────────────┐      ┌───────────────────────────────┐  │
│  │   DiskProjectRepository   │      │       ProviderRegistry        │  │
│  │   - Reads/Writes YAML     │      │   - QwenImageProvider         │  │
│  │   - Scene asset versioning│      │   - FluxImageProvider         │  │
│  └─────────────┬─────────────┘      └───────────────┬───────────────┘  │
│                │                                    │                  │
│                ▼                                    ▼                  │
│  ┌───────────────────────────┐      ┌───────────────────────────────┐  │
│  │ Filesystem (Local YAML):  │      │ External Synthesizer Routers: │  │
│  │ script, visual_direction, │      │ - HF Router (fal-ai, etc.)    │  │
│  │ image_prompts, manifest   │      │ - Open-source FLUX Fallback   │  │
│  └───────────────────────────┘      └───────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. The 8-Phase Narrative Pipeline

The studio synchronizes with `lanthic-skills` output phases represented on disk as YAML specifications:

| Phase | Output Artifact | Purpose | Status in Studio |
| :--- | :--- | :--- | :--- |
| **Phase 1: Script** | `script.yaml` | Raw scene dialogue, actions, sluglines, scene beats | Fully read & displayed |
| **Phase 2: Beats** | `beats.yaml` | Dramatic units, pacing, narrative tension | Fully parsed |
| **Phase 3: Visual Direction** | `visual_direction.yaml` | Lens focal lengths, lighting setups, color palettes, camera angles | Fully parsed & aggregated |
| **Phase 4: Image Prompts** | `image_prompts.yaml` | Raw and compiled text prompts for image models | Sanitized & validated |
| **Phase 5: Generation Manifest**| `generation_manifest.yaml` | Scene IDs, status (`pending`, `cooking`, `approved`), asset references | Live read/write updating |
| **Phase 6: Image Synthesis** | `assets/scenes/sc_XXX/` | Generated PNG/JPG scene images and metadata versions | Active focus of debugging |
| **Phase 7: Visual Validation** | `visual_validation.yaml` | Continuity scores, character identity flags, composition score | Parsed & color-coded |
| **Phase 8: Assembly & Continuity**| `continuity.yaml` | Cross-scene timeline, character costume/lighting continuity | Parsed & timeline view |

---

## 4. Completed vs. Half-Baked Iterations

### A. Fully Implemented & Verified
1. **Interactive Node Graph (`StudioNodeGraphView`)**:
   - Custom-painted bezier splines connecting pipeline steps.
   - Node cards displaying run status, execution time, error banners, and action triggers ("Cook", "Inspect").
   - Pan/zoom canvas matrix with responsive desktop layouts.
2. **Disk Project Repository (`DiskProjectRepository`)**:
   - Atomic disk read/write for YAML specifications.
   - Preserves comments and unknown keys during updates.
   - Non-destructive image asset versioning (`scene_v1.png`, `scene_v2.png`).
3. **Enterprise Core & Network Engine**:
   - Custom `DioProvider` with automated timeout policies.
   - `LanthicAnalyticsInterceptor` formatting all HTTP requests, response headers, and payloads with redacted credentials in Flutter debug logs.
   - Resilient `SecureStorageServiceImpl` featuring an automatic in-memory/file fallback when macOS Keychain throws `-34018` (missing entitlement in unbundled dev builds).
4. **Prompt Sanitization System**:
   - `ImagePromptItem.sanitizePrompt` strips SD-WebUI specific syntax (e.g. `<lora:comic_ink_style:0.8>`).
   - Unwraps raw JSON/YAML object dictionaries when prompts are formatted as `{value: "..."}` instead of plain strings.

### B. Half-Baked / In-Progress Iterations
1. **Third-Party Inference Routing (`QwenImageProvider` / `FluxImageProvider`)**:
   - *Current State*: Configured with candidate list of endpoints.
   - *Half-Baked*: Hugging Face router provider model IDs (`fal-ai/flux/schnell`) require linked billing accounts. Free community tokens fail when calling partner routes.
2. **Fail-Safe Open-Source Synthesis Fallback**:
   - *Current State*: Integrated automated fallback to zero-auth open-source FLUX synthesis (`image.pollinations.ai/prompt/...&model=flux`).
   - *Half-Baked*: While functional, community endpoints experience latency variance (2–5 seconds) and lack deterministic rate-limit SLAs.
3. **Custom / Local Model Endpoints (Ollama / ComfyUI)**:
   - *Current State*: UI modal accepts custom endpoints (`http://localhost:11434`, `http://127.0.0.1:8188`).
   - *Half-Baked*: ComfyUI WebSocket workflow graph submission is not yet implemented; only basic OpenAI-compatible or raw Diffusers REST POST schemas are supported.
4. **Video Timeline & Scrubbing (`lanthic_video_timeline.dart`)**:
   - *Current State*: Widget scaffolded with timecode display and frame markers.
   - *Half-Baked*: Audio-scrubbing and multi-track transition playback are placeholders pending stable frame synthesis.

---

## 5. File Registry & Responsibilities

| File Path | Primary Responsibility |
| :--- | :--- |
| `lib/data/providers/qwen_image_provider.dart` | Executes vision generation against Hugging Face Router & fallback open-source FLUX tiers. |
| `lib/data/providers/flux_image_provider.dart` | Direct FLUX inference implementation via Replicate / Fal HTTP APIs. |
| `lib/data/providers/provider_registry.dart` | Service locator mapping identifier strings (`qwen`, `flux`, `sdxl`) to `ImageProviderContract`. |
| `lib/data/repositories/disk_project_repository.dart` | Reads and writes project state across all 8 pipeline YAML files on disk. |
| `lib/domain/models/aggregated_scene.dart` | Central aggregate root combining Script, Beats, Direction, Prompts, and Validation per scene. |
| `lib/domain/models/image_prompt_model.dart` | Models prompt data and houses the `sanitizePrompt` cleaning engine. |
| `lib/domain/models/generation_manifest_model.dart`| Tracks scene asset cooking statuses, hashes, and image version paths. |
| `lib/features/graph/screens/studio_node_graph_view.dart` | The interactive node editor canvas for cooking and pipeline orchestration. |
| `lib/features/graph/widgets/graph_node_card.dart` | Card widget representing a single phase node with action triggers and logs. |
| `lib/features/graph/widgets/bezier_spline_painter.dart` | CustomPainter rendering bezier connections between pipeline phases. |
| `lib/features/regenerate/phase6_payload_builder.dart` | Formats generation payloads matching provider-specific REST contracts. |
| `lib/core/network/lanthic_analytics_interceptor.dart` | Logs sanitized HTTP requests, status codes, and error bodies to console. |
| `lib/core/storage/secure_storage_service.dart` | Key-value store for API keys with macOS Keychain `-34018` fallback. |

---

## 6. Repetitive Blockers & Raw Error Analysis

The following errors have recurred throughout development and require architectural resolution:

### Blocker 1: Hugging Face Router Partner ID Mismatch
- **Log Snippet**:
  ```text
  [NETWORK] POST https://router.huggingface.co/fal-ai/models/black-forest-labs/FLUX.1-schnell -> HTTP 400 (629ms)
  RESPONSE BODY: {"error":"Model not supported by provider fal-ai"}
  ```
- **Why it occurred**:
  Hugging Face routes models by internal partner slugs rather than Hugging Face Hub repository names. For `black-forest-labs/FLUX.1-schnell`, Fal's internal slug on the router is `fal-ai/flux/schnell`, and WaveSpeed's slug is `wavespeed-ai/flux-schnell`. Passing the Hub repo name resulted in immediate 400 rejection.

### Blocker 2: Serverless `hf-inference` Deprecation
- **Log Snippet**:
  ```text
  [NETWORK] POST https://router.huggingface.co/hf-inference/models/black-forest-labs/FLUX.1-schnell -> HTTP 410 (294ms)
  RESPONSE BODY: {"error":"The requested model is deprecated and no longer supported by provider hf-inference"}
  ```
  Followed by:
  ```text
  [NETWORK] POST https://router.huggingface.co/hf-inference/models/ByteDance/SDXL-Lightning -> HTTP 400 (402ms)
  RESPONSE BODY: {"error":"Model not supported by provider hf-inference"}
  ```
- **Why it occurred**:
  Hugging Face retired free direct hosting of 12B+ diffusion models on their shared serverless infrastructure. Only partner providers (Fal, WaveSpeed, Replicate) now host them on the HF Router.

### Blocker 3: Partner Provider Billing / Token Rejection
- **Log Snippet**:
  ```text
  [WARNING] [HF Provider] Endpoint https://router.huggingface.co/fal-ai/models/fal-ai/flux/schnell failed with HTTP 403 / 400
  {"error":"Payment required or provider not linked"}
  ```
- **Why it occurred**:
  Standard free Hugging Face User Access Tokens (`hf_...`) cannot execute paid partner routes unless the user has added credit card billing in [Hugging Face Inference Providers Settings](https://huggingface.co/settings/inference-providers).

### Blocker 4: Prompt Structure Malformation (Dictionary / LoRA Syntax)
- **Log Snippet**:
  ```text
  DATA: {inputs: {value: "A medium shot at eye level in a modest wooden tailor workshop..."}}
  Error: 400 Bad Request - Expected string for inputs, received map
  ```
  And in prompts containing LoRA tokens:
  ```text
  Prompt: "...ocular implant glow <lora:comic_ink_style:0.8>"
  ```
- **Why it occurred**:
  1. Different pipeline generation scripts wrote `prompt` as either a scalar string or a nested map `{value: "..."}`.
  2. The LLM inserted Automatic1111/ComfyUI LoRA syntax (`<lora:...>`) which standard Diffusers REST endpoints reject as illegal characters or unparseable tokens.

### Blocker 5: Aspect Ratio vs. Dimension Schema
- **Log Snippet**:
  ```text
  DATA: {parameters: {aspect_ratio: "16:9"}}
  Error: 422 Unprocessable Entity - Unrecognized field aspect_ratio
  ```
- **Why it occurred**:
  Diffusers-based models expect explicit integer dimensions (`width: 1024, height: 576`), whereas UI/LLM pipelines pass qualitative aspect ratios (`16:9`).

### Blocker 6: macOS Keychain `-34018`
- **Log Snippet**:
  ```text
  PlatformException(-34018, A required entitlement is not present., null, null)
  ```
- **Why it occurred**:
  Unpackaged debug builds of Flutter macOS do not carry code-signed Keychain Sharing entitlements, causing `flutter_secure_storage` to throw fatal exceptions during API key retrieval.

---

## 7. Strategic Questions for Claude, Argon, and Codex

1. **Inference Architecture**:
   - Should Lanthic Studio maintain an embedded lightweight inference proxy/broker (e.g. Node/Python sidecar or Go binary), or continue utilizing a pure Dart HTTP client targeting multi-provider endpoints?
   - What is the most resilient way to support local ComfyUI/Ollama workflows without forcing non-technical users to manually configure WebSockets and workflow JSONs?
2. **Model Serving Strategy**:
   - For users without paid GPU quotas, what is the best hybrid fallback pattern? (e.g., client-side WebGPU running Stable Diffusion vs. community serverless endpoints vs. BYOK [Bring Your Own Key] for Replicate/Fal/Together)?
3. **YAML Synchronization & State Management**:
   - When users cook a single scene from the NodeGraph, what is the cleanest pattern for updating `generation_manifest.yaml` atomically across multiple background isolates without causing file lock contention with Flutter Riverpod?
