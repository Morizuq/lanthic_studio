import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/features/regenerate/phase6_payload_builder.dart';

void main() {
  group('Phase6PayloadBuilder', () {
    const builder = Phase6PayloadBuilder();

    test('builds FLUX payload with correct endpoint, aspect_ratio, and lora tags', () {
      final payload = builder.build(
        sceneId: 'sc_001',
        prompt: 'Captain Vane stares at the glowing console',
        provider: 'flux',
        loraTags: ['<lora:comic_ink_style:0.8>'],
        aspectRatio: '16:9',
      );

      expect(payload.sceneId, 'sc_001');
      expect(payload.provider, 'flux');
      expect(payload.endpoint, Phase6PayloadBuilder.fluxEndpoint);
      expect(payload.parameters['aspect_ratio'], '16:9');
      expect(
        payload.parameters['prompt'],
        'Captain Vane stares at the glowing console <lora:comic_ink_style:0.8>',
      );
      expect(payload.promptHash.length, 13);
    });

    test('builds Imagen payload with negative prompt and aspect ratio', () {
      final payload = builder.build(
        sceneId: 'sc_002',
        prompt: 'Hermes VII drifting in space',
        provider: 'imagen',
        negativePrompt: 'blurry, 3d',
        aspectRatio: '16:9',
      );

      expect(payload.provider, 'imagen');
      expect(payload.endpoint, Phase6PayloadBuilder.imagenEndpoint);
      expect(payload.parameters['negativePrompt'], 'blurry, 3d');
    });

    test('builds SDXL payload with text prompt weights and prompt key', () {
      final payload = builder.build(
        sceneId: 'sc_003',
        prompt: 'Shattered monolith',
        provider: 'sdxl',
        negativePrompt: 'low resolution',
      );

      expect(payload.provider, 'sdxl');
      expect(payload.prompt, 'Shattered monolith');
      expect(payload.parameters['prompt'], 'Shattered monolith');
      final textPrompts = payload.parameters['text_prompts'] as List;
      expect(textPrompts.length, 2);
      expect(textPrompts[0]['weight'], 1.0);
      expect(textPrompts[1]['weight'], -1.0);
    });

    test('builds Qwen/HF Inference payload with prompt and steps', () {
      final payload = builder.build(
        sceneId: 'sc_004',
        prompt: 'Neon cybernetic tailor shop',
        provider: 'qwen',
        aspectRatio: '16:9',
      );

      expect(payload.provider, 'qwen');
      expect(payload.prompt, 'Neon cybernetic tailor shop');
      expect(payload.parameters['prompt'], 'Neon cybernetic tailor shop');
      expect(payload.parameters['aspect_ratio'], '16:9');
      expect(payload.parameters['steps'], 4);
      expect(payload.endpoint, Phase6PayloadBuilder.qwenHfEndpoint);
    });
  });
}
