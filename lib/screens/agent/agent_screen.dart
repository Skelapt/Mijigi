import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agent_models.dart';
import '../../models/capture_item.dart';
import '../../providers/agent_provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../item_detail/item_detail_screen.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MijigiColors.background,
      appBar: AppBar(
        backgroundColor: MijigiColors.background,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [MijigiColors.primary, MijigiColors.accent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Mijigi Agent'),
          ],
        ),
        actions: [
          if (context.watch<AgentProvider>().messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () =>
                  context.read<AgentProvider>().clearChat(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer2<AgentProvider, AppProvider>(
              builder: (context, agent, app, _) {
                if (agent.messages.isEmpty) {
                  return _buildEmptyState(agent, app);
                }
                return _buildChat(agent, app);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AgentProvider agent, AppProvider app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [MijigiColors.primary, MijigiColors.accent],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: MijigiColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Personal Agent',
            style: TextStyle(
              color: MijigiColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${app.totalItems} items indexed and searchable',
            style: const TextStyle(
              color: MijigiColors.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking',
              style: TextStyle(
                color: MijigiColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...agent.suggestions.map(
            (s) => _buildSuggestionChip(s, agent, app),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(
      String text, AgentProvider agent, AppProvider app) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          _inputController.text = text;
          _send(agent, app);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: MijigiColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MijigiColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: MijigiColors.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  color: MijigiColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChat(AgentProvider agent, AppProvider app) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: agent.messages.length,
      itemBuilder: (context, index) {
        final msg = agent.messages[index];
        return _buildMessage(msg, app);
      },
    );
  }

  Widget _buildMessage(AgentMessage msg, AppProvider app) {
    if (msg.isUser) return _buildUserMessage(msg);
    if (msg.isLoading) return _buildThinkingMessage();
    return _buildAgentMessage(msg, app);
  }

  Widget _buildUserMessage(AgentMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: MijigiColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: MijigiColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: MijigiColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MijigiColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Thinking...',
              style: TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentMessage(AgentMessage msg, AppProvider app) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: MijigiColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: MijigiColors.border),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: MijigiColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),

            // Insight card
            if (msg.insight != null) ...[
              const SizedBox(height: 8),
              _buildInsightCard(msg.insight!),
            ],

            // Referenced items
            if (msg.itemIds != null && msg.itemIds!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildItemChips(msg.itemIds!, app),
            ],

            // Actions
            if (msg.actions != null && msg.actions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...msg.actions!.map((a) => _buildActionButton(a)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(AgentInsight insight) {
    final color = switch (insight.type) {
      InsightType.spending => MijigiColors.categoryReceipt,
      InsightType.reminder => MijigiColors.warning,
      InsightType.warning => MijigiColors.error,
      _ => MijigiColors.primary,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...insight.data.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        color: MijigiColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      e.value,
                      style: const TextStyle(
                        color: MijigiColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildItemChips(List<String> itemIds, AppProvider app) {
    final items = itemIds
        .map((id) => app.items.where((i) => i.id == id).firstOrNull)
        .whereType<CaptureItem>()
        .take(5)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map((item) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(itemId: item.id),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: MijigiColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MijigiColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _typeIcon(item.type),
                      size: 16,
                      color: MijigiColors.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: MijigiColors.textTertiary,
                    ),
                  ],
                ),
              ),
            )),
        if (itemIds.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+ ${itemIds.length - 5} more items',
              style: const TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(AgentAction action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: action.isExecuted
            ? null
            : () {
                final app = context.read<AppProvider>();
                final agent = context.read<AgentProvider>();
                agent.executeAction(action, (a) async {
                  await _executeAction(a, app);
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: action.isExecuted
                ? MijigiColors.accent.withValues(alpha: 0.1)
                : MijigiColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: action.isExecuted
                  ? MijigiColors.accent.withValues(alpha: 0.3)
                  : MijigiColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.isExecuted
                    ? Icons.check_circle_rounded
                    : Icons.play_arrow_rounded,
                size: 16,
                color: action.isExecuted
                    ? MijigiColors.accent
                    : MijigiColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                action.isExecuted ? '${action.label} (done)' : action.label,
                style: TextStyle(
                  color: action.isExecuted
                      ? MijigiColors.accent
                      : MijigiColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: MijigiColors.surface,
        border: Border(
          top: BorderSide(color: MijigiColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              autofocus: true,
              style: const TextStyle(
                color: MijigiColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Ask anything about your items...',
                hintStyle: TextStyle(
                  color: MijigiColors.textTertiary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              ),
              onSubmitted: (_) {
                final agent = context.read<AgentProvider>();
                final app = context.read<AppProvider>();
                _send(agent, app);
              },
            ),
          ),
          Consumer<AgentProvider>(
            builder: (context, agent, _) {
              return GestureDetector(
                onTap: agent.isThinking
                    ? null
                    : () {
                        final app = context.read<AppProvider>();
                        _send(agent, app);
                      },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: agent.isThinking
                        ? null
                        : const LinearGradient(
                            colors: [
                              MijigiColors.primary,
                              MijigiColors.primaryLight,
                            ],
                          ),
                    color: agent.isThinking ? MijigiColors.surfaceLight : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    agent.isThinking
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _send(AgentProvider agent, AppProvider app) {
    final text = _inputController.text.trim();
    if (text.isEmpty || agent.isThinking) return;
    _inputController.clear();
    agent.sendCommand(text, app.activeItems);
  }

  Future<void> _executeAction(AgentAction action, AppProvider app) async {
    final ids = (action.params['itemIds'] as List?)?.cast<String>() ?? [];

    switch (action.type) {
      case AgentActionType.pin:
        for (final id in ids) {
          await app.togglePin(id);
        }
        break;
      case AgentActionType.archive:
        for (final id in ids) {
          await app.archiveItem(id);
        }
        break;
      case AgentActionType.delete:
        for (final id in ids) {
          await app.deleteItem(id);
        }
        break;
      case AgentActionType.organise:
        // Re-categorise uncategorised items
        for (final id in ids) {
          final item = app.items.where((i) => i.id == id).firstOrNull;
          if (item != null && item.rawText != null) {
            // Force re-process
            item.isProcessed = false;
            await app.updateItem(item);
          }
        }
        break;
      default:
        break;
    }
  }

  IconData _typeIcon(CaptureType type) => switch (type) {
        CaptureType.photo => Icons.photo_rounded,
        CaptureType.screenshot => Icons.screenshot_rounded,
        CaptureType.document => Icons.description_rounded,
        CaptureType.note => Icons.edit_note_rounded,
        CaptureType.clipboard => Icons.content_paste_rounded,
        CaptureType.voice => Icons.mic_rounded,
        CaptureType.link => Icons.link_rounded,
      };
}
