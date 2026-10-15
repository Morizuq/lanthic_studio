import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/project_providers.dart';

class ApiKeysDialog extends ConsumerStatefulWidget {
  const ApiKeysDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ApiKeysDialog(),
    );
  }

  @override
  ConsumerState<ApiKeysDialog> createState() => _ApiKeysDialogState();
}

class _ApiKeysDialogState extends ConsumerState<ApiKeysDialog> {
  late final TextEditingController _qwenController;
  late final TextEditingController _fluxController;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _qwenController = TextEditingController();
    _fluxController = TextEditingController();
    _loadKeys();
  }

  @override
  void dispose() {
    _qwenController.dispose();
    _fluxController.dispose();
    super.dispose();
  }

  Future<void> _loadKeys() async {
    final credStore = ref.read(credentialStoreProvider);
    final qwenKey = await credStore.readApiKey('qwen');
    final fluxKey = await credStore.readApiKey('flux');

    if (mounted) {
      setState(() {
        if (qwenKey != null) _qwenController.text = qwenKey;
        if (fluxKey != null) _fluxController.text = fluxKey;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final credStore = ref.read(credentialStoreProvider);
    try {
      await credStore.writeApiKey('qwen', _qwenController.text.trim());
      await credStore.writeApiKey('flux', _fluxController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Keys saved securely to OS Keychain.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save keys: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.vpn_key_rounded, size: 20, color: Color(0xFF00B8FF)),
          const SizedBox(width: 8),
          const Text('Provider API Keys'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: _isLoading
            ? const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keys are stored securely in your OS Keychain (never in project files or git).',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),

                  // Qwen / Hugging Face Key
                  TextField(
                    controller: _qwenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Hugging Face Access Token (Free Inference)',
                      helperText: 'Free token with "Inference" permission from huggingface.co/settings/tokens (FLUX.1-schnell / SDXL)',
                      helperMaxLines: 2,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bolt, color: Color(0xFF00B8FF)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FLUX Key
                  TextField(
                    controller: _fluxController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'BFL FLUX API Key (FLUX Pro)',
                      helperText: 'Commercial key from api.bfl.ml for FLUX 1.1 Pro diffusion',
                      helperMaxLines: 1,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed, color: Color(0xFF8B5CF6)),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00B8FF),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: Text(_isSaving ? 'Saving...' : 'Save to Keychain'),
        ),
      ],
    );
  }
}
