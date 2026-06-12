// lib/widgets/entry_form/mood_picker_sheet.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:dailylogr/providers/user_config_provider.dart';

class MoodPickerSheet extends ConsumerStatefulWidget {
  final String? initialMood;

  const MoodPickerSheet({super.key, this.initialMood});

  @override
  ConsumerState<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends ConsumerState<MoodPickerSheet> {
  String? _adjective;

  // Built-in moods for user
  static const List<String> _builtInAdjectives = [
    '😀 Happy',
    '😞 Sad',
    '😌 Calm',
    '🎯 Focused',
    '😪 Tired',
    '😰 Anxious',
    '🤩 Excited',
    '🙏 Grateful',
    '😡 Angry',
    '😕 Confused',
    '😇 Blessed',
    '😐 Meh',
    '😓 Stressed',
    '😴 Sleepy',
    '🤒 Sick',
    '💪 Productive',
    '🏖️ Relaxed',
    '🤔 Thoughtful',
    '🛌 Rested',
    '😃 Joyful',
    '😔 Lonely',
    '😤 Frustrated',
    '😎 Cool',
    '🤗 Loved',
    '❓ Uncertain',
    '😩 Exhausted',
    '🌟 Hopeful',
    '😬 Nervous',
    '🚀 Enthusiastic',
  ];

  @override
  void initState() {
    super.initState();
    _adjective = widget.initialMood;
  }

  List<String> _allMoods(List<String> customMoods) {
    return [...customMoods, ..._builtInAdjectives];
  }

  // Show add mood dialog
  Future<void> _showAddMoodDialog({String? existingMood}) async {
    final isEditing = existingMood != null;
    // Mood contains an emoji and a name
    final initialEmoji = isEditing ? existingMood.characters.first : '';
    final initialName = isEditing ? existingMood.characters.skip(1).toString().trim() : '';

    final emojiCtrl = TextEditingController(text: initialEmoji);
    final nameCtrl = TextEditingController(text: initialName);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final color = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit mood' : 'New mood'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern Emoji Picker Trigger
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: ctx,
                          builder: (bottomSheetCtx) {
                            return SafeArea(
                              child: SizedBox(
                                height: 300,
                                child: EmojiPicker(
                                  onEmojiSelected: (category, emoji) {
                                    setState(() {
                                      emojiCtrl.text = emoji.emoji;
                                    });
                                    Navigator.pop(bottomSheetCtx);
                                  },
                                  config: Config(
                                    height: 256,
                                    checkPlatformCompatibility: true,
                                    emojiViewConfig: EmojiViewConfig(
                                      emojiSizeMax: 28 *
                                          (!kIsWeb && Platform.isIOS ? 1.30 : 1.0),
                                    ),
                                    bottomActionBarConfig: const BottomActionBarConfig(
                                      showBackspaceButton: false,
                                      showSearchViewButton: false,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: color.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: emojiCtrl.text.isEmpty
                                ? color.outlineVariant
                                : color.primary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: emojiCtrl.text.isEmpty
                              ? Icon(Icons.add_reaction_outlined, size: 36, color: color.onSurfaceVariant)
                              : Text(emojiCtrl.text, style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mood name',
                        hintText: 'e.g. Inspired',
                        border: OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (emojiCtrl.text.isEmpty) return 'Please select an emoji above';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (emojiCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an emoji!')),
                      );
                      return;
                    }
                    if (formKey.currentState!.validate()) {
                      final mood = '${emojiCtrl.text.trim()} ${nameCtrl.text.trim()}';
                      Navigator.pop(ctx, mood);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: color.primary,
                    foregroundColor: color.onPrimary,
                  ),
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          }
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      if (isEditing) {
        await ref.read(userConfigProvider.notifier).updateCustomMood(existingMood, result);
      } else {
        await ref.read(userConfigProvider.notifier).addCustomMood(result);
      }
      if (mounted) {
        setState(() => _adjective = result);
        Navigator.pop(context, result);
      }
    }
  }

  // Build mood picker sheet
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      expand: false,
      builder: (ctx, scrollController) {
        final color = Theme.of(ctx).colorScheme;
        final customMoods = ref.watch(userConfigProvider).customMoods;
        final allMoods = _allMoods(customMoods);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How was your day?',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        onPressed: _showAddMoodDialog,
                      ),
                      ...allMoods.map((adj) {
                        final selected = _adjective == adj;
                        final isCustom = customMoods.contains(adj);

                        final chip = ChoiceChip(
                          label: Text(adj),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _adjective = selected ? null : adj);
                            Navigator.pop(context, _adjective ?? "");
                          },
                          showCheckmark: false,
                          selectedColor: color.primaryContainer,
                        );

                        if (isCustom) {
                          return GestureDetector(
                            onLongPress: () async {
                              final action = await showModalBottomSheet<String>(
                                context: ctx,
                                showDragHandle: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (bCtx) => SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.edit_outlined),
                                          title: const Text('Edit mood'),
                                          onTap: () => Navigator.pop(bCtx, 'edit'),
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.delete_outline, color: color.error),
                                          title: Text('Remove mood', style: TextStyle(color: color.error)),
                                          onTap: () => Navigator.pop(bCtx, 'delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                              if (action == 'edit') {
                                await _showAddMoodDialog(existingMood: adj);
                              } else if (action == 'delete') {
                                if (!ctx.mounted) return;
                                final confirm = await showDialog<bool>(
                                  context: ctx,
                                  builder: (dCtx) => AlertDialog(
                                    title: const Text('Remove mood?'),
                                    content: Text('Remove "$adj" from your custom moods?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dCtx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(dCtx, true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: color.error,
                                          foregroundColor: color.onError,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  if (!mounted) return;
                                  await ref
                                      .read(userConfigProvider.notifier)
                                      .removeCustomMood(adj);
                                  if (_adjective == adj && mounted) {
                                    setState(() => _adjective = null);
                                  }
                                }
                              }
                            },
                            child: chip,
                          );
                        }
                        return chip;
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
