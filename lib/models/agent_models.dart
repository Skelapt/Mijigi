import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class AgentMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? itemIds;
  final List<AgentAction>? actions;
  final AgentInsight? insight;
  bool isLoading;

  AgentMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.itemIds,
    this.actions,
    this.insight,
    this.isLoading = false,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();

  AgentMessage copyWith({
    String? text,
    bool? isLoading,
    List<String>? itemIds,
    List<AgentAction>? actions,
    AgentInsight? insight,
  }) =>
      AgentMessage(
        id: id,
        text: text ?? this.text,
        isUser: isUser,
        timestamp: timestamp,
        itemIds: itemIds ?? this.itemIds,
        actions: actions ?? this.actions,
        insight: insight ?? this.insight,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AgentAction {
  final String id;
  final String label;
  final AgentActionType type;
  final Map<String, dynamic> params;
  bool isExecuted;

  AgentAction({
    String? id,
    required this.label,
    required this.type,
    this.params = const {},
    this.isExecuted = false,
  }) : id = id ?? _uuid.v4();
}

enum AgentActionType {
  organise,
  tag,
  pin,
  archive,
  delete,
  remind,
  rename,
  merge,
  export,
}

class AgentInsight {
  final String title;
  final Map<String, String> data;
  final InsightType type;

  AgentInsight({
    required this.title,
    required this.data,
    this.type = InsightType.info,
  });
}

enum InsightType {
  info,
  spending,
  reminder,
  summary,
  warning,
}

class AgentConfig {
  final String? apiEndpoint;
  final String? apiKey;
  final String? modelName;

  AgentConfig({this.apiEndpoint, this.apiKey, this.modelName});

  bool get isConfigured =>
      apiEndpoint != null &&
      apiEndpoint!.isNotEmpty &&
      apiKey != null &&
      apiKey!.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'apiEndpoint': apiEndpoint,
        'apiKey': apiKey,
        'modelName': modelName,
      };

  factory AgentConfig.fromMap(Map<String, dynamic> map) => AgentConfig(
        apiEndpoint: map['apiEndpoint'] as String?,
        apiKey: map['apiKey'] as String?,
        modelName: map['modelName'] as String?,
      );
}
