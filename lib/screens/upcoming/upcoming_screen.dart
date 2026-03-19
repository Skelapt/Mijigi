import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deadline.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/deadline_card.dart';
import '../item_detail/item_detail_screen.dart';

class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final expired = provider.expiredDeadlines;
        final urgent = provider.urgentDeadlines;
        final upcoming = provider.upcomingDeadlines
            .where((d) => d.daysUntil > 7)
            .toList();

        final hasAny =
            expired.isNotEmpty || urgent.isNotEmpty || upcoming.isNotEmpty;

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 60)),

            // Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming',
                      style: TextStyle(
                        color: MijigiColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasAny
                          ? 'Deadlines & expiry dates from your captures'
                          : 'Capture documents with dates to track them here',
                      style: const TextStyle(
                        color: MijigiColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            if (!hasAny)
              SliverToBoxAdapter(child: _buildEmptyState())
            else ...[
              // Expired section
              if (expired.isNotEmpty) ...[
                _buildSectionHeader('Expired', MijigiColors.error,
                    Icons.warning_rounded, expired.length),
                _buildDeadlineList(context, provider, expired),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],

              // Urgent section (within 7 days)
              if (urgent.isNotEmpty) ...[
                _buildSectionHeader('This Week', MijigiColors.warning,
                    Icons.priority_high_rounded, urgent.length),
                _buildDeadlineList(context, provider, urgent),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],

              // Upcoming section (8-30 days)
              if (upcoming.isNotEmpty) ...[
                _buildSectionHeader('Coming Up', MijigiColors.accent,
                    Icons.schedule_rounded, upcoming.length),
                _buildDeadlineList(context, provider, upcoming),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
      String title, Color color, IconData icon, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineList(
      BuildContext context, AppProvider provider, List<Deadline> deadlines) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final deadline = deadlines[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DeadlineCard(
                deadline: deadline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ItemDetailScreen(itemId: deadline.itemId),
                    ),
                  );
                },
              ),
            );
          },
          childCount: deadlines.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MijigiColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 36,
              color: MijigiColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No deadlines tracked',
            style: TextStyle(
              color: MijigiColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Capture documents with expiry dates, appointments,\nor deadlines and Mijigi will track them for you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MijigiColors.textTertiary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
