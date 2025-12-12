import 'package:flutter/material.dart';

/// A Material Design 3 chip input field that allows adding/removing multiple text items
/// Used for common triggers (distractions) and resources needed (practices)
class ChipInputField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> initialItems;
  final ValueChanged<List<String>> onChanged;
  final IconData? icon;
  final int? maxItems;

  const ChipInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.initialItems,
    required this.onChanged,
    this.icon,
    this.maxItems,
  });

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  late List<String> _items;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.maxItems != null && _items.length >= widget.maxItems!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxItems} items allowed'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_items.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item already added'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _items.add(text);
      _controller.clear();
      widget.onChanged(_items);
    });
  }

  void _removeItem(String item) {
    setState(() {
      _items.remove(item);
      widget.onChanged(_items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '${widget.label} field with ${_items.length} items',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addItem,
                tooltip: 'Add item',
                color: colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addItem(),
          ),

          // Chips display
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _items.map((item) {
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Semantics(
                    label: '$item, double tap to remove',
                    button: true,
                    child: Chip(
                      label: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      onDeleted: () => _removeItem(item),
                      backgroundColor: colorScheme.secondaryContainer,
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Helper text
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                'Press + or Enter to add items',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                '${_items.length} ${_items.length == 1 ? 'item' : 'items'}${widget.maxItems != null ? ' (max ${widget.maxItems})' : ''}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
