import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent_models.dart';
import '../models/capture_item.dart';
import '../services/agent_service.dart';

class AgentProvider extends ChangeNotifier {
  final AgentService _agentService = AgentService();
  final List<AgentMessage> _messages = [];
  bool _isThinking = false;
  AgentConfig _config = AgentConfig();

  List<AgentMessage> get messages => _messages;
  bool get isThinking => _isThinking;
  AgentConfig get config => _config;
  bool get isConfigured => _config.isConfigured;

  /// Suggested commands shown when chat is empty
  List<String> get suggestions => const [
        'What do I have?',
        'Find all my receipts',
        'How much did I spend this month?',
        'Show me documents',
        'Organise my items',
        'Find items with dates',
      ];

  Future<void> init() async {
    await _loadConfig();
  }

  Future<void> sendCommand(String command, List<CaptureItem> items) async {
    if (command.trim().isEmpty) return;

    // Add user message
    _messages.add(AgentMessage(text: command, isUser: true));

    // Add thinking placeholder
    final thinkingMsg = AgentMessage(
      text: '',
      isUser: false,
      isLoading: true,
    );
    _messages.add(thinkingMsg);
    _isThinking = true;
    notifyListeners();

    // Process command
    final response = await _agentService.processCommand(command, items);

    // Replace thinking with response
    final idx = _messages.indexOf(thinkingMsg);
    if (idx >= 0) {
      _messages[idx] = response;
    } else {
      _messages.add(response);
    }

    _isThinking = false;
    notifyListeners();
  }

  /// Execute an agent action (user confirmed)
  Future<void> executeAction(
    AgentAction action,
    Future<void> Function(AgentAction) executor,
  ) async {
    await executor(action);
    action.isExecuted = true;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  // --- Config ---

  Future<void> updateConfig(AgentConfig newConfig) async {
    _config = newConfig;
    _agentService.updateConfig(newConfig);
    await _saveConfig();
    notifyListeners();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _config = AgentConfig(
      apiEndpoint: prefs.getString('agent_api_endpoint'),
      apiKey: prefs.getString('agent_api_key'),
      modelName: prefs.getString('agent_model_name'),
    );
    _agentService.updateConfig(_config);
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    if (_config.apiEndpoint != null) {
      await prefs.setString('agent_api_endpoint', _config.apiEndpoint!);
    }
    if (_config.apiKey != null) {
      await prefs.setString('agent_api_key', _config.apiKey!);
    }
    if (_config.modelName != null) {
      await prefs.setString('agent_model_name', _config.modelName!);
    }
  }
}
