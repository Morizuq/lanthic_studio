import 'package:flutter/material.dart';

class AddDialogueDialog extends StatefulWidget {
  const AddDialogueDialog({
    super.key,
    required this.characters,
    required this.onAddDialogue,
  });

  final List<String> characters;
  final void Function(String speaker, String text) onAddDialogue;

  @override
  State<AddDialogueDialog> createState() => _AddDialogueDialogState();
}

class _AddDialogueDialogState extends State<AddDialogueDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _speakerController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _speakerController = TextEditingController(
      text: widget.characters.isNotEmpty ? widget.characters.first : 'Character',
    );
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _speakerController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onAddDialogue(
      _speakerController.text.trim(),
      _textController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Add Dialogue Line', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _speakerController,
                  decoration: const InputDecoration(
                    labelText: 'Speaker Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Speaker required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _textController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Spoken Line / Dialogue Text',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Dialogue required' : null,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Add Dialogue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
