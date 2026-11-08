import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../data/local/database.dart';
import '../logic/location/location_service.dart';
import '../logic/providers.dart';

class IncidentReportScreen extends ConsumerStatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  ConsumerState<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends ConsumerState<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController(text: '${AppConstants.defaultIndiaLat}');
  final _lonController = TextEditingController(text: '${AppConstants.defaultIndiaLon}');

  String _selectedCategory = AppConstants.categoryMedical;
  String _selectedPriority = AppConstants.priorityHigh;
  bool _isLoadingGps = false;
  bool _isSaving = false;

  bool _isRecordingAudio = false;
  int _audioDurationSeconds = 0;
  bool _hasRecordedAudio = false;
  Timer? _audioTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectGpsLocation();
    });
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _toggleAudioRecording() {
    if (_isRecordingAudio) {
      _stopAudioRecording();
    } else {
      _startAudioRecording();
    }
  }

  void _startAudioRecording() {
    setState(() {
      _isRecordingAudio = true;
      _audioDurationSeconds = 0;
      _hasRecordedAudio = false;
    });
    _audioTimer?.cancel();
    _audioTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_audioDurationSeconds >= 30) {
        _stopAudioRecording();
      } else {
        setState(() => _audioDurationSeconds++);
      }
    });
  }

  void _stopAudioRecording() {
    _audioTimer?.cancel();
    setState(() {
      _isRecordingAudio = false;
      _hasRecordedAudio = true;
    });
  }

  void _deleteAudioRecording() {
    _audioTimer?.cancel();
    setState(() {
      _isRecordingAudio = false;
      _hasRecordedAudio = false;
      _audioDurationSeconds = 0;
    });
  }

  Future<void> _detectGpsLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      final position = await LocationService.getCurrentPosition(context);
      if (position != null) {
        setState(() {
          _latController.text = position.latitude.toStringAsFixed(6);
          _lonController.text = position.longitude.toStringAsFixed(6);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.teal,
              content: Text('GPS coordinates captured successfully.'),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);

    final clientId = const Uuid().v4();
    final now = DateTime.now();
    final lat = double.tryParse(_latController.text) ?? 0.0;
    final lon = double.tryParse(_lonController.text) ?? 0.0;

    String finalDescription = _descriptionController.text.trim();
    if (_hasRecordedAudio) {
      final durationStr = '00:${_audioDurationSeconds.toString().padLeft(2, '0')}';
      finalDescription = finalDescription.isEmpty
          ? '[🎙️ Field Audio Situation Memo: $durationStr recorded]'
          : '$finalDescription\n[🎙️ Field Audio Situation Memo: $durationStr recorded]';
    }

    // 1. Save directly into local Drift DB (offline-first guarantee)
    await db.insertIncident(
      LocalIncidentsCompanion(
        clientId: drift.Value(clientId),
        title: drift.Value(_titleController.text.trim()),
        category: drift.Value(_selectedCategory),
        description: drift.Value(finalDescription),
        status: const drift.Value(AppConstants.statusReported),
        priority: drift.Value(_selectedPriority),
        latitude: drift.Value(lat),
        longitude: drift.Value(lon),
        version: const drift.Value(1),
        isSynced: const drift.Value(false),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // 2. Add to SyncQueue
    await db.enqueueSync(
      entityType: 'incident',
      entityId: clientId,
      operation: 'create',
      payload: clientId,
    );

    // 3. Trigger background sync attempt
    syncService.triggerSync();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.teal,
          content: Text('Incident stored offline in Drift & queued for sync!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Emergency Incident'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Incident Title *',
                  hintText: 'e.g. Flash Flood or Structural Damage',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Situation Description',
                  hintText: 'Describe severity, trapped victims, hazards...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              // Triage Quick-Chips
              const Text('Quick Triage Tags (Tap to add):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  '⚠️ Trapped People',
                  '🔥 Active Flames',
                  '🩸 Critical Injury',
                  '⚡ Live Wire',
                  '🌊 High Water',
                  '🧱 Structural Collapse',
                ].map((tag) {
                  return ActionChip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      final current = _descriptionController.text;
                      if (current.isEmpty) {
                        _descriptionController.text = tag;
                      } else {
                        _descriptionController.text = '$current, $tag';
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              // Emergency Audio Memo Recorder
              _buildAudioMemoRecorder(),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Emergency Category',
                  prefixIcon: Icon(Icons.category_rounded),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: AppConstants.categorySOS, child: Text('🚨 SOS Distress Beacon')),
                  DropdownMenuItem(value: AppConstants.categoryFire, child: Text('🔥 Fire & Hazard')),
                  DropdownMenuItem(value: AppConstants.categoryMedical, child: Text('🚑 Medical Emergency')),
                  DropdownMenuItem(value: AppConstants.categoryFlood, child: Text('🌊 Flood / Natural Disaster')),
                  DropdownMenuItem(value: AppConstants.categoryRoadAccident, child: Text('🚗 Road Accident')),
                  DropdownMenuItem(value: AppConstants.categoryGeneral, child: Text('⚠️ General / Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority Level',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: AppConstants.priorityLow, child: Text('Low')),
                  DropdownMenuItem(value: AppConstants.priorityMedium, child: Text('Medium')),
                  DropdownMenuItem(value: AppConstants.priorityHigh, child: Text('High')),
                  DropdownMenuItem(value: AppConstants.priorityCritical, child: Text('Critical (Immediate)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPriority = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lonController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoadingGps ? null : _detectGpsLocation,
                icon: _isLoadingGps
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: const Text('Acquire GPS Coordinates'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _submitIncident,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _isSaving ? 'Storing...' : 'Dispatch / Store Offline',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMemoRecorder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = '00:${_audioDurationSeconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isRecordingAudio
            ? Colors.red.withValues(alpha: 0.12)
            : (_hasRecordedAudio
                ? Colors.teal.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF1E2631) : const Color(0xFFF1F5F9))),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRecordingAudio
              ? Colors.redAccent
              : (_hasRecordedAudio ? Colors.teal : (isDark ? Colors.white12 : Colors.black12)),
          width: _isRecordingAudio ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isRecordingAudio
                    ? Icons.mic
                    : (_hasRecordedAudio ? Icons.check_circle_rounded : Icons.mic_none_rounded),
                color: _isRecordingAudio
                    ? Colors.redAccent
                    : (_hasRecordedAudio ? Colors.teal : Colors.blueAccent),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isRecordingAudio
                      ? '🔴 Recording Situation Audio... ($timeStr / 00:30)'
                      : (_hasRecordedAudio
                          ? '✅ Situation Audio Memo Attached ($timeStr)'
                          : 'Record Voice Situation Memo (Max 30s)'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isRecordingAudio
                        ? Colors.redAccent
                        : (_hasRecordedAudio ? Colors.teal : (isDark ? Colors.white70 : Colors.black87)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecordingAudio ? Colors.redAccent : Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(_isRecordingAudio ? Icons.stop_rounded : Icons.fiber_manual_record_rounded, size: 16),
                label: Text(_isRecordingAudio ? 'Stop Recording' : (_hasRecordedAudio ? 'Re-record' : 'Start Recording')),
                onPressed: _toggleAudioRecording,
              ),
              if (_hasRecordedAudio) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                  onPressed: _deleteAudioRecording,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
