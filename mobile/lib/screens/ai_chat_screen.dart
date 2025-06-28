import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    // Add initial AI message
    _addAIMessage("Hello! How can I assist you with your train travel plans today?");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
      ));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();
    
    // Get user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final user_body = prefs.getString('user_profile');
    if (user_body != null && user_body.isNotEmpty) {
      setState(() {
        userProfile = jsonDecode(user_body);
      });
    }
    
    // Get user ID safely
    String? userId;
    if (userProfile != null && userProfile!.containsKey('UserID')) {
      userId = userProfile!['UserID']?.toString();
    }
    
    // Log for debugging
    logInfo('Sending message to webhook with UserID: ${userId ?? 'not available'}', tag: 'AIChatScreen');

    // Send message to webhook with user ID
    try {
      final response = await http.post(
        Uri.parse('https://webhook-processor-production-2e11.up.railway.app/webhook/32655209-1252-422e-a8ed-a3438334a96b/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'user_id': userId ?? '',
        }),
      );

      if (response.statusCode == 200) {
        logDebug('Raw response: ${response.body}', tag: 'AIChatScreen');
        try {
          final jsonResponse = jsonDecode(response.body);
          
          // Handle multiple possible response formats
          if (jsonResponse is List && jsonResponse.isNotEmpty) {
            // Original list format
            final aiResponse = jsonResponse[0]['response']['body'];
            logInfo('AI response received (list format)', tag: 'AIChatScreen');
            _addAIMessage(aiResponse);
          } else if (jsonResponse is Map) {
            if (jsonResponse.containsKey('response')) {
              // Original map format
              final aiResponse = jsonResponse['response']['body'];
              logInfo('AI response received (response format)', tag: 'AIChatScreen');
              _addAIMessage(aiResponse);
            } else if (jsonResponse.containsKey('output')) {
              // New format with output field
              final aiResponse = jsonResponse['output'];
              logInfo('AI response received (output format)', tag: 'AIChatScreen');
              _addAIMessage(aiResponse);
            } else {
              logWarning('Unexpected response format: $jsonResponse', tag: 'AIChatScreen');
              _addAIMessage("Sorry, I couldn't process your request. Please try again.");
            }
          } else {
            logWarning('Unexpected response format: $jsonResponse', tag: 'AIChatScreen');
            _addAIMessage("Sorry, I couldn't process your request. Please try again.");
          }
        } catch (e) {
          logError('Error parsing response', tag: 'AIChatScreen', error: e);
          _addAIMessage("Sorry, I couldn't process your request. Please try again.");
        }
      } else {
        _addAIMessage("Sorry, there was an error processing your request. Please try again later.");
      }
    } catch (e) {
      _addAIMessage("Sorry, there was an error connecting to the assistant. Please check your internet connection and try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _addAIMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Train Assistant',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EEFF), Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation with your\nTrain Assistant',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return MessageBubble(
                          message: message.text,
                          isUser: message.isUser,
                          isLast: index == _messages.length - 1,
                        );
                      },
                    ),
            ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(left: 16),
                child: const TypingIndicator(),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask about trains, routes, or bookings...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isLast;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF7C3AED),
                radius: 16,
                child: const Icon(
                  Icons.train,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF7C3AED) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF9F7AEA),
                radius: 16,
                child: const Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.3;
    final progress = (_controller.value + delay) % 1.0;
    final size = 6.0 + 3.0 * (progress < 0.5 ? progress * 2 : (1 - progress) * 2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        shape: BoxShape.circle,
      ),
    );
  }
}
