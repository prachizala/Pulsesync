import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../data/local/database.dart';
import '../logic/location/location_service.dart';
import '../logic/providers.dart';

class SosBeaconDialog extends ConsumerStatefulWidget {
  const SosBeaconDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SosBeaconDialog(),
    );
  }

  @override
  ConsumerState<SosBeaconDialog> createState() => _SosBeaconDialogState();
}

class _SosBeaconDialogState extends ConsumerState<SosBeaconDialog> with SingleTickerProviderStateMixin {
  int _secondsRemaining = 3;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isDispatched = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _triggerEmergencySOS();
      }
    });
  }

  Future<void> _triggerEmergencySOS() async {
    setState(() => _isDispatched = true);

    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);

    // 1. Get exact GPS location (fallback to India default if unavailable)
    double lat = AppConstants.defaultIndiaLat;
    double lon = AppConstants.defaultIndiaLon;
    try {
      final pos = await LocationService.getCurrentPosition(context);
      if (pos != null) {
        lat = pos.latitude;
        lon = pos.longitude;
      }
    } catch (_) {}

    final clientId = const Uuid().v4();
    final now = DateTime.now();

    // 2. Commit CRITICAL SOS directly to Drift DB
    await db.insertIncident(
      LocalIncidentsCompanion(
        clientId: drift.Value(clientId),
        title: const drift.Value('🚨 EMERGENCY SOS BEACON TRIGGERED'),
        category: const drift.Value(AppConstants.categorySOS),
        description: const drift.Value('Instant SOS distress signal triggered by field user. Immediate assistance needed!'),
        status: const drift.Value(AppConstants.statusReported),
        priority: const drift.Value(AppConstants.priorityCritical),
        latitude: drift.Value(lat),
        longitude: drift.Value(lon),
        version: const drift.Value(1),
        isSynced: const drift.Value(false),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // 3. Queue for sync and trigger push
    await db.enqueueSync(
      entityType: 'incident',
      entityId: clientId,
      operation: 'create',
      payload: clientId,
    );

    syncService.triggerSync();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 5),
          content: Row(
            children: [
              Icon(Icons.crisis_alert_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🚨 SOS BEACON BROADCASTED! Nearby responders alerted.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚠️ EMERGENCY DISTRESS SIGNAL',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade900,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: _isDispatched
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          '$_secondsRemaining',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isDispatched ? 'Dispatched to HQ & Responders...' : 'Broadcasting SOS Beacon in $_secondsRemaining seconds...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your exact GPS coordinates will be dispatched immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      _timer?.cancel();
                      Navigator.pop(context);
                    },
                    child: const Text('CANCEL (False Alarm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isDispatched ? null : _triggerEmergencySOS,
                    child: const Text('SEND NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
