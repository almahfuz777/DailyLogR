// lib/widgets/entry_form/entry_content_area.dart
import 'package:flutter/material.dart';

/// The main content area of the Entry Form.
/// Contains the Title and Note text fields.
class EntryContentArea extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController noteCtrl;
  final FocusNode noteFocus;
  final bool readOnly;
  final UndoHistoryController? titleUndoController;
  final UndoHistoryController? noteUndoController;
  final Color? backgroundColor;

  const EntryContentArea({
    super.key,
    required this.titleCtrl,
    required this.noteCtrl,
    required this.noteFocus,
    required this.readOnly,
    this.titleUndoController,
    this.noteUndoController,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => noteFocus.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: Container(
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  undoController: titleUndoController,
                  readOnly: readOnly,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(
                      color: color.onSurfaceVariant.withValues(alpha: 0.65),
                    ),
                    border: InputBorder.none,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: noteCtrl,
                    undoController: noteUndoController,
                    focusNode: noteFocus,
                    readOnly: readOnly,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Note',
                      hintStyle: TextStyle(
                        color: color.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

