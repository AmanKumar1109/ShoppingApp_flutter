import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchBottomSheet extends StatefulWidget {
  final String? initialHint;

  const VoiceSearchBottomSheet({
    super.key,
    this.initialHint,
  });

  /// Static helper to show voice search sheet and return recognized query string
  static Future<String?> show(BuildContext context, {String? initialHint}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceSearchBottomSheet(initialHint: initialHint),
    );
  }

  @override
  State<VoiceSearchBottomSheet> createState() => _VoiceSearchBottomSheetState();
}

class _VoiceSearchBottomSheetState extends State<VoiceSearchBottomSheet>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeechAvailable = false;
  bool _hasError = false;
  String _recognizedWords = '';
  String _statusMessage = 'Initializing microphone...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _silenceTimer;

  static const List<String> _suggestedQueries = [
    'Surf Excel',
    'Amul Milk',
    'Dairy Milk Silk',
    'Cadbury Brownie',
    'Wheat Atta',
    'Desi Ghee',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeechRecognizer();
  }

  Future<void> _initSpeechRecognizer() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      if (mounted) {
        setState(() {
          _isSpeechAvailable = available;
        });

        if (available) {
          _startListening();
        } else {
          setState(() {
            _hasError = true;
            _statusMessage =
                'Voice input not available on this device.\nYou can select popular searches below:';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage =
              'Could not access microphone.\nYou can pick popular searches below:';
        });
      }
    }
  }

  void _startListening() async {
    if (!_isSpeechAvailable) return;

    setState(() {
      _isListening = true;
      _hasError = false;
      _statusMessage = 'Listening... Speak now';
      _recognizedWords = '';
    });

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_IN',
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (_) {
      setState(() {
        _isListening = false;
        _hasError = true;
        _statusMessage = 'Tap mic icon to try speaking again.';
      });
    }
  }

  void _stopListening() async {
    _silenceTimer?.cancel();
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        if (_recognizedWords.trim().isNotEmpty) {
          _statusMessage = 'Done listening!';
        } else {
          _statusMessage = 'Tap mic to try again';
        }
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _recognizedWords = result.recognizedWords;
      if (_recognizedWords.isNotEmpty) {
        _statusMessage = 'Listening...';
      }
    });

    // Auto-confirm if final result is reached or after brief pause
    if (result.finalResult && _recognizedWords.trim().isNotEmpty) {
      _silenceTimer?.cancel();
      _silenceTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted && _recognizedWords.trim().isNotEmpty) {
          Navigator.of(context).pop(_recognizedWords.trim());
        }
      });
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      setState(() {
        _isListening = true;
      });
    } else if (status == 'notListening' || status == 'done') {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _hasError = true;
      if (error.errorMsg.toLowerCase().contains('no match') ||
          error.errorMsg.toLowerCase().contains('speech_timeout')) {
        _statusMessage = 'Didn\'t catch that. Tap mic to speak again.';
      } else {
        _statusMessage = 'Voice recognition error: ${error.errorMsg}';
      }
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Grab Bar
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7C415).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Color(0xFF19251B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Voice Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF19251B),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status & Recognized Query Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isListening
                    ? const Color(0xFFF7C415)
                    : const Color(0xFFE5E7EB),
                width: _isListening ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _recognizedWords.isNotEmpty
                      ? '"$_recognizedWords"'
                      : _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _recognizedWords.isNotEmpty ? 20 : 14.5,
                    fontWeight: _recognizedWords.isNotEmpty
                        ? FontWeight.w900
                        : FontWeight.w600,
                    color: _recognizedWords.isNotEmpty
                        ? const Color(0xFF19251B)
                        : (_hasError
                            ? Colors.red[700]
                            : const Color(0xFF6B7280)),
                  ),
                ),
                if (_recognizedWords.isEmpty && _isListening) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Try saying: "Surf excel", "Cadbury brownie", "Milk"...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Central Animated Mic Button
          GestureDetector(
            onTap: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isListening)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 90 * _pulseAnimation.value,
                        height: 90 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF7C415)
                              .withValues(alpha: 0.28 / _pulseAnimation.value),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [
                              const Color(0xFFF7C415),
                              const Color(0xFFE5B20D),
                            ]
                          : [
                              const Color(0xFF19251B),
                              const Color(0xFF2E3E32),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isListening
                            ? const Color(0xFFF7C415).withValues(alpha: 0.45)
                            : Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _isListening ? const Color(0xFF19251B) : Colors.white,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Text(
            _isListening ? 'Tap to stop' : 'Tap to speak',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Suggested Searches Chips
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Popular Voice Searches',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.grey[700],
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedQueries.map((query) {
              return ActionChip(
                backgroundColor: const Color(0xFFF3F4F6),
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                avatar: const Icon(
                  Icons.trending_up_rounded,
                  size: 15,
                  color: Color(0xFF19251B),
                ),
                label: Text(
                  query,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19251B),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(query);
                },
              );
            }).toList(),
          ),

          if (_recognizedWords.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19251B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop(_recognizedWords.trim());
                },
                child: Text(
                  'Search "$_recognizedWords"',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
