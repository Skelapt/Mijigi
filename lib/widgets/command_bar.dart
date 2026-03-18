import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CommandBar extends StatefulWidget {
  final VoidCallback onTap;

  const CommandBar({super.key, required this.onTap});

  @override
  State<CommandBar> createState() => _CommandBarState();
}

class _CommandBarState extends State<CommandBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MijigiColors.primary.withValues(alpha: 0.12),
                    MijigiColors.accent.withValues(alpha: 0.06),
                    MijigiColors.primary.withValues(alpha: 0.08),
                  ],
                  stops: [
                    0,
                    _shimmerController.value,
                    1,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MijigiColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [MijigiColors.primary, MijigiColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ask Mijigi anything...',
                      style: TextStyle(
                        color: MijigiColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: MijigiColors.primary.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
