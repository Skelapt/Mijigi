import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MijigiSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final TextEditingController? controller;

  const MijigiSearchBar({
    super.key,
    this.hint = 'Search everything...',
    required this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.controller,
  });

  @override
  State<MijigiSearchBar> createState() => _MijigiSearchBarState();
}

class _MijigiSearchBarState extends State<MijigiSearchBar> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasFocus ? MijigiColors.primary.withValues(alpha: 0.5) : MijigiColors.border,
          width: _hasFocus ? 1.5 : 1,
        ),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: MijigiColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _hasFocus = focused),
        child: TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          style: const TextStyle(
            color: MijigiColors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: MijigiColors.textTertiary,
              fontSize: 16,
            ),
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.search_rounded,
                color: _hasFocus ? MijigiColors.primary : MijigiColors.textTertiary,
                size: 22,
              ),
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: MijigiColors.textTertiary,
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          ),
        ),
      ),
    );
  }
}
