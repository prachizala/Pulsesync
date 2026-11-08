import 'dart:async';
import 'package:flutter/material.dart';

class NightBeaconScreen extends StatefulWidget {
  const NightBeaconScreen({super.key});

  @override
  State<NightBeaconScreen> createState() => _NightBeaconScreenState();
}

class _NightBeaconScreenState extends State<NightBeaconScreen> {
  bool _isFlashing = true;
  Color _currentColor = Colors.redAccent;
  Timer? _strobeTimer;
  int _mode = 0; // 0: Fast Strobe, 1: SOS Morse Code, 2: Solid High-Beam

  @override
  void initState() {
    super.initState();
    _startStrobe();
  }

  void _startStrobe() {
    _strobeTimer?.cancel();
    if (_mode == 2) {
      setState(() => _currentColor = Colors.white);
      return;
    }

    final interval = _mode == 0 ? const Duration(milliseconds: 250) : const Duration(milliseconds: 600);

    _strobeTimer = Timer.periodic(interval, (timer) {
      if (!mounted) return;
      setState(() {
        _isFlashing = !_isFlashing;
        _currentColor = _isFlashing ? Colors.redAccent : Colors.white;
      });
    });
  }

  @override
  void dispose() {
    _strobeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Colors.yellowAccent, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'NIGHT RESCUE STROBE',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'High-visibility screen beacon for night rescue & helicopters',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChoiceChip(
                          label: const Text('Rapid Strobe'),
                          selected: _mode == 0,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _mode = 0);
                              _startStrobe();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('SOS Pulse'),
                          selected: _mode == 1,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _mode = 1);
                              _startStrobe();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Torch'),
                          selected: _mode == 2,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _mode = 2);
                              _startStrobe();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
