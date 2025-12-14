
import 'package:flutter/material.dart';
import 'package:nexaaura/services/audio_service.dart';

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;

  const AudioMessageBubble({super.key, required this.audioUrl});

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final AudioService _audioService = AudioService();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioService.stopPlaying();
    } else {
      await _audioService.startPlaying(widget.audioUrl);
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlayback,
        ),
        const Text('Voice Message'), // Placeholder for waveform
      ],
    );
  }
}
