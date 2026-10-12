import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:toggle_timer/core/utils/app_prompts.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';
import 'package:toggle_timer/features/sales/models/lead_model.dart';

import '../../../config/typography/app_typography.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key, required this.lead});
  final LeadModel lead;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordDuration = Duration.zero;
  late List<String> _recordings;
  
  // Playback state variables
  String? _currentlyPlayingPath;
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recordings = List.from(widget.lead.recordingPaths);
    _checkPermissions();
    _setupAudioPlayerListeners();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingPath = null;
          _playbackPosition = Duration.zero;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    if (!await Permission.microphone.isGranted) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        AppPrompts.showError(message: 'Microphone permission is required to record', title: 'Permission Denied');
      }
    }
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<String?> _getRecordingPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/recordings';

      // Create recordings directory if it doesn't exist
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      return '$path/recording_$timestamp.m4a';
    } catch (e) {
      AppPrompts.showError(message: 'Failed to create recording directory: $e');
      return null;
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        AppPrompts.showError(message: 'Microphone permission is required to record', title: 'Permission Denied');
        return;
      }

      final path = await _getRecordingPath();
      if (path == null) return;

      const encoder = AudioEncoder.aacLc;
      await _audioRecorder.start(RecordConfig(encoder: encoder), path: path);

      setState(() {
        _isRecording = true;
      });

      // Start duration timer
      _startDurationTimer();

      AppPrompts.showInfo(message: 'Recording started', duration: const Duration(seconds: 1));
    } catch (e) {
      AppPrompts.showError(message: 'Failed to start recording: $e');
    }
  }

  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordDuration = Duration(seconds: _recordDuration.inSeconds + 1);
        });
        _startDurationTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordDuration = Duration.zero;
      });

      if (path != null && path.isNotEmpty) {
        // Add to recordings list
        setState(() => _recordings.add(path));

        // Update lead with new recording path

        final updatedLead = widget.lead.addActivity('Recording', 'Added recording to lead');
        await updatedLead.save();
        final updatedLead2 = widget.lead.copyWith(recordingPaths: _recordings);
        await updatedLead2.save();

        AppPrompts.showSuccess(message: 'Recording saved successfully', title: 'Success');
      }
    } catch (e) {
      AppPrompts.showError(message: 'Failed to stop recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      AppPrompts.showInfo(message: 'Recording paused', duration: const Duration(seconds: 1));
    } catch (e) {
      AppPrompts.showError(message: 'Failed to pause recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      setState(() {
        _isPaused = false;
      });
      AppPrompts.showInfo(message: 'Recording resumed', duration: const Duration(seconds: 1));
    } catch (e) {
      AppPrompts.showError(message: 'Failed to resume recording: $e');
    }
  }

  Future<void> _deleteRecording(String path) async {
    try {
      // Stop playback if this recording is currently playing
      if (_currentlyPlayingPath == path) {
        await _stopPlayback();
      }

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      
      setState(() {
        _recordings.remove(path);
      });

      // Update lead
      final updatedLead = widget.lead.copyWith(recordingPaths: _recordings);
      await updatedLead.save();

      AppPrompts.showSuccess(message: 'Recording deleted successfully', title: 'Deleted');
    } catch (e) {
      AppPrompts.showError(message: 'Failed to delete recording: $e');
    }
  }

  // Audio Playback Methods
  Future<void> _playRecording(String path) async {
    try {
      // If same file is playing, pause it
      if (_currentlyPlayingPath == path && _isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
        return;
      }
      
      // If different file or not playing, play the new one
      if (_currentlyPlayingPath != path) {
        // Stop current playback if any
        await _audioPlayer.stop();

        // Play the new file
        await _audioPlayer.play(DeviceFileSource(path));
        setState(() {
          _currentlyPlayingPath = path;
          _isPlaying = true;
        });
      } else {
        // Resume playback
        await _audioPlayer.resume();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      AppPrompts.showError(message: 'Failed to play recording: $e');
    }
  }

  Future<void> _pausePlayback() async {
    try {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      AppPrompts.showError(message: 'Failed to pause playback: $e');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingPath = null;
        _playbackPosition = Duration.zero;
      });
    } catch (e) {
      AppPrompts.showError(message: 'Failed to stop playback: $e');
    }
  }

  Future<void> _seekPlayback(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      AppPrompts.showError(message: 'Failed to seek: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _formatDate(String path) {
    try {
      final regex = RegExp(r'recording_(\d+)\.m4a');
      final match = regex.firstMatch(path.split('/').last);
      if (match != null) {
        final timestamp = int.parse(match.group(1)!);
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateFormat('MMM dd, yyyy • HH:mm').format(date);
      }
    } catch (e) {
      // Fallback to file modified date
      try {
        final file = File(path);
        final stat = file.statSync();
        return DateFormat('MMM dd, yyyy • HH:mm').format(stat.modified);
      } catch (e) {
        return 'Unknown date';
      }
    }
    return 'Unknown date';
  }

  Widget _buildRecordingTile(String recording, int index) {
    final fileName = recording.split('/').last;
    final isCurrentlyPlaying = _currentlyPlayingPath == recording && _isPlaying;
    final isPaused = _currentlyPlayingPath == recording && !_isPlaying && _playbackPosition != Duration.zero;

    return Card(
      color: const Color.fromARGB(255, 69, 69, 69),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: isCurrentlyPlaying
                  ? const Icon(Icons.play_arrow, color: Colors.green)
                  : isPaused
                  ? const Icon(Icons.pause, color: Colors.orange)
                  : const Icon(Icons.audio_file),
            ),
            title: Text(
              fileName, style: AppTypography.style16SemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(recording), style: AppTypography.style12Regular),
                if (_currentlyPlayingPath == recording && _audioDuration > Duration.zero)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatDuration(_playbackPosition), style: AppTypography.style12Regular),
                            const Spacer(),
                            Text(_formatDuration(_audioDuration), style: AppTypography.style12Regular),
                          ],
                        ),
                        Slider(
                          value: _playbackPosition.inSeconds.toDouble(),
                          min: 0,
                          max: _audioDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            _seekPlayback(Duration(seconds: value.toInt()));
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentlyPlayingPath == recording && _isPlaying)
                  IconButton(icon: const Icon(Icons.pause), onPressed: _pausePlayback, color: Colors.orange)
                else if (_currentlyPlayingPath == recording && !_isPlaying && _playbackPosition != Duration.zero)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _playRecording(recording),
                    color: Colors.green,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _playRecording(recording),
                    color: Colors.green,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteConfirmation(recording),
                  color: Colors.red,
                ),
              ],
            ),
            onTap: () => _showRecordingOptions(recording),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: AppUtils.gradientFlexibleSpace(),
        title: Text("Meeting Recordings"),
        actions: [
          if (_recordings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _recordings.isEmpty ? null : () => _showDeleteAllConfirmation(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Recording Controls
          Container(
            width: context.width,
            padding: const EdgeInsets.all(16),
            color: theme.primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                if (_isRecording) ...[
                  // Recording indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPaused ? 'PAUSED' : 'RECORDING',
                        style: AppTypography.style14SemiBold.copyWith(color: Colors.red),
                      ),
                      const SizedBox(width: 16),
                      Text(_formatDuration(_recordDuration), style: AppTypography.style18SemiBold),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Recording controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isPaused)
                        FloatingActionButton(
                          onPressed: _pauseRecording,
                          backgroundColor: Colors.orange,
                          mini: true,
                          child: const Icon(Icons.pause),
                        )
                      else
                        FloatingActionButton(
                          onPressed: _resumeRecording,
                          backgroundColor: Colors.green,
                          mini: true,
                          child: const Icon(Icons.play_arrow),
                        ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        onPressed: _stopRecording,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.stop),
                      ),
                    ],
                  ),
                ] else ...[
                  // Start recording button
                  Column(
                    children: [
                      Text('Start a new meeting recording', style: AppTypography.style16Regular),
                      const SizedBox(height: 16),
                      FloatingActionButton.extended(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.fiber_manual_record),
                        label: Text('Start Recording', style: AppTypography.style14SemiBold),
                        backgroundColor: Colors.red,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Recordings List
          Expanded(
            child: _recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic_none, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No recordings yet',
                          style: AppTypography.style18SemiBold.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the red button to start recording',
                          style: AppTypography.style14Regular.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      return _buildRecordingTile(_recordings[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRecordingOptions(String path) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: Text('Play Recording', style: AppTypography.style16Regular),
              onTap: () {
                Navigator.pop(context);
                _playRecording(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: Text('Share', style: AppTypography.style16Regular),
              onTap: () {
                Navigator.pop(context);
                _shareRecording(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: Text('Details', style: AppTypography.style16Regular),
              onTap: () {
                Navigator.pop(context);
                _showRecordingDetails(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: AppTypography.style16Regular),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(path);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareRecording(String path) {
    AppPrompts.showInfo(message: 'Sharing feature coming soon', title: 'Coming Soon',
    );
  }

  void _showRecordingDetails(String path) {
    final file = File(path);
    final fileSize = file.lengthSync();
    final modified = file.statSync().modified;

    Get.dialog(
      AlertDialog(
        title: Text('Recording Details', style: AppTypography.style18SemiBold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${path.split('/').last}', style: AppTypography.style14Regular),
            const SizedBox(height: 8),
            Text(
              'Size: ${_formatFileSize(fileSize)}', style: AppTypography.style14Regular),
            const SizedBox(height: 8),
            Text(
              'Modified: ${DateFormat('MMM dd, yyyy HH:mm').format(modified)}', style: AppTypography.style14Regular),
            const SizedBox(height: 8),
            Text(
              'Path: $path', style: AppTypography.style12Regular),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTypography.style16Regular),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showDeleteConfirmation(String path) {
    AppPrompts.showConfirmation(
      context: context,
      title: 'Delete Recording',
      message: 'Are you sure you want to delete this recording?',
      onConfirm: () => _deleteRecording(path),
    );
  }

  void _showDeleteAllConfirmation() {
    AppPrompts.showConfirmation(
      context: context,
      title: 'Delete All Recordings',
      message: 'Are you sure you want to delete all recordings?',
      onConfirm: () async {
        for (final recording in _recordings.toList()) {
          await _deleteRecording(recording);
        }
      },
    );
  }
}
