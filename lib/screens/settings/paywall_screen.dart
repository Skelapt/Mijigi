import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MijigiColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: MijigiColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: MijigiColors.textTertiary, size: 18),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: MijigiGradients.buttonGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: MijigiColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 36),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Picxtract Pro',
                style: TextStyle(
                  color: MijigiColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Unlock the full experience',
                style: TextStyle(
                  color: MijigiColors.textSecondary,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 32),

              // Features
              _FeatureItem(
                icon: Icons.block_rounded,
                title: 'Ad-Free Experience',
                subtitle: 'No interruptions, ever',
              ),
              _FeatureItem(
                icon: Icons.bolt_rounded,
                title: 'Priority Processing',
                subtitle: 'Faster OCR and image scanning',
              ),
              _FeatureItem(
                icon: Icons.auto_awesome_rounded,
                title: 'Smart Collections',
                subtitle: 'Auto-organized photo collections',
              ),
              _FeatureItem(
                icon: Icons.support_agent_rounded,
                title: 'Priority Support',
                subtitle: 'Get help when you need it',
              ),

              const Spacer(),

              // Plan toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MijigiColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isYearly = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isYearly
                                ? MijigiColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Monthly',
                                style: TextStyle(
                                  color: !_isYearly
                                      ? Colors.white
                                      : MijigiColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\$3.99/mo',
                                style: TextStyle(
                                  color: !_isYearly
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : MijigiColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isYearly = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isYearly
                                ? MijigiColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Yearly',
                                    style: TextStyle(
                                      color: _isYearly
                                          ? Colors.white
                                          : MijigiColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'SAVE 40%',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\$28.99/yr',
                                style: TextStyle(
                                  color: _isYearly
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : MijigiColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _subscribe,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: MijigiGradients.buttonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: MijigiColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _isYearly
                            ? 'Subscribe - \$28.99/year'
                            : 'Subscribe - \$3.99/month',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Restore + legal
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _restore,
                    child: Text(
                      'Restore Purchase',
                      style: TextStyle(
                        color: MijigiColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(' \u2022 ',
                      style: TextStyle(color: MijigiColors.textTertiary,
                          fontSize: 12)),
                  Text(
                    'Cancel anytime',
                    style: TextStyle(
                      color: MijigiColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _subscribe() {
    // TODO: Integrate with in_app_purchase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription coming soon',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _restore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking for existing subscription...',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MijigiColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: MijigiColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: const TextStyle(
                      color: MijigiColors.textTertiary,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
