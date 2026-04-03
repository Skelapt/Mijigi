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
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: 46,
      decoration: BoxDecoration(
        color: _hasFocus
            ? MijigiColors.surfaceLight
            : MijigiColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: _hasFocus
              ? MijigiColors.primary.withValues(alpha: 0.35)
              : MijigiColors.border.withValues(alpha: 0.6),
          width: 0.5,
        ),
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
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: MijigiColors.textTertiary.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Icon(
                Icons.search_rounded,
                color: _hasFocus
                    ? MijigiColors.primary
                    : MijigiColors.textTertiary.withValues(alpha: 0.7),
                size: 19,
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: _controller.text.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: MijigiColors.textTertiary,
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged('');
                      },
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
          ),
        ),
      ),
    );
  }
}
