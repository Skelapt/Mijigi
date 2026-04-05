import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MijigiColors.background,
      appBar: AppBar(
        backgroundColor: MijigiColors.background,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Pro upgrade card
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: MijigiGradients.heroGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MijigiColors.primary.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MijigiColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: MijigiColors.primaryLight, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Picxtract Pro',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Ad-free experience',
                            style: TextStyle(
                                color: MijigiColors.textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: MijigiColors.textTertiary, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section: General
          _SectionHeader('General'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.storage_rounded,
            label: 'Storage',
            subtitle: 'Manage app data',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Section: Legal
          _SectionHeader('Legal'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () => _openTerms(context),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            label: 'Privacy Policy',
            onTap: () => _openPrivacy(context),
          ),

          const SizedBox(height: 24),

          // Section: About
          _SectionHeader('About'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.star_outline_rounded,
            label: 'Rate Picxtract',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: 'Contact Support',
            onTap: () => launchUrl(Uri.parse('mailto:support@picxtract.com')),
          ),

          const SizedBox(height: 40),

          // Footer
          Center(
            child: Text(
              'Picxtract v1.0.0',
              style: TextStyle(
                color: MijigiColors.textTertiary.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _LegalScreen(
        title: 'Terms of Service',
        content: _termsContent,
      )),
    );
  }

  void _openPrivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _LegalScreen(
        title: 'Privacy Policy',
        content: _privacyContent,
      )),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: MijigiColors.textTertiary.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: MijigiColors.textSecondary, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: MijigiColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                color: MijigiColors.textTertiary,
                                fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: MijigiColors.textTertiary.withValues(alpha: 0.5),
                    size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const _LegalScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MijigiColors.background,
      appBar: AppBar(
        backgroundColor: MijigiColors.background,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          content,
          style: const TextStyle(
            color: MijigiColors.textSecondary,
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}

const _termsContent = '''
TERMS OF SERVICE - PICXTRACT

Last updated: April 2026

1. ACCEPTANCE OF TERMS
By downloading, installing, or using Picxtract ("the App"), you agree to be bound by these Terms of Service.

2. DESCRIPTION OF SERVICE
Picxtract is a mobile application that helps users organize, search, and extract information from their photos, documents, and QR codes using on-device machine learning technology.

3. SUBSCRIPTION SERVICES
Picxtract Pro is available as a monthly (\$3.99/month) or yearly subscription. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Payment will be charged to your Google Play or Apple App Store account.

4. FREE TIER
The free version of Picxtract includes advertisements. All core features are available in the free tier. Picxtract Pro removes all advertisements.

5. USER DATA
All image processing, OCR, and barcode scanning is performed on-device. Your photos and documents are not uploaded to external servers. See our Privacy Policy for full details.

6. INTELLECTUAL PROPERTY
You retain all rights to your content. Picxtract does not claim ownership of any photos, documents, or other media you process through the App.

7. LIMITATION OF LIABILITY
Picxtract is provided "as is" without warranty of any kind. We are not liable for any loss of data, inaccurate OCR results, or any other damages arising from the use of the App.

8. CHANGES TO TERMS
We reserve the right to modify these terms at any time. Continued use of the App after changes constitutes acceptance of the new terms.

9. CONTACT
For questions about these Terms, contact support@picxtract.com.
''';

const _privacyContent = '''
PRIVACY POLICY - PICXTRACT

Last updated: April 2026

1. OVERVIEW
Picxtract is committed to protecting your privacy. This policy explains how we handle your data.

2. DATA PROCESSING
All image processing, text recognition (OCR), image labeling, and barcode scanning is performed entirely on your device using Google ML Kit. Your photos, documents, and scanned data are NEVER uploaded to external servers.

3. DATA STORAGE
All extracted text, labels, and metadata are stored locally on your device using encrypted local storage (Hive). This data does not leave your device.

4. WHAT WE DO NOT COLLECT
- We do not collect your photos or documents
- We do not collect OCR text or extracted data
- We do not collect your clipboard history
- We do not collect barcode/QR code scan results
- We do not sell any user data

5. WHAT WE MAY COLLECT
- Anonymous crash reports (if opted in)
- Anonymous usage analytics (feature usage counts, not content)
- Subscription status (for managing Pro features)

6. ADVERTISEMENTS
The free version displays advertisements provided by third-party ad networks. These networks may collect anonymous device identifiers for ad targeting. Picxtract Pro removes all advertisements.

7. THIRD-PARTY SERVICES
- Google ML Kit (on-device processing, no data transmitted)
- Google Play Billing (subscription management)
- Ad network (free tier only, anonymous identifiers)

8. DATA DELETION
Uninstalling the App removes all locally stored data. You can also clear app data from your device Settings at any time.

9. CHILDREN'S PRIVACY
Picxtract is not directed at children under 13. We do not knowingly collect data from children.

10. CHANGES TO POLICY
We will notify users of significant changes to this policy through the App.

11. CONTACT
For privacy questions, contact privacy@picxtract.com.
''';
