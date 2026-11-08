import 'package:flutter/material.dart';

class EmergencyGuideScreen extends StatelessWidget {
  const EmergencyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guides = [
      {
        'title': 'CPR (Cardiopulmonary Resuscitation)',
        'icon': Icons.favorite_rounded,
        'color': Colors.redAccent,
        'steps': [
          '1. Check responsiveness: Tap shoulders firmly and call loudly.',
          '2. Call Emergency Services (112 / 108) immediately.',
          '3. Check pulse & breathing: If no normal breathing, begin chest compressions immediately.',
          '4. Hand placement: Place heel of one hand in the center of the chest, interlock the other hand.',
          '5. Compress: Push hard and fast at 100-120 beats/minute (2 inches deep). Allow full recoil.',
          '6. Ratio: 30 hard compressions followed by 2 gentle rescue breaths (if trained).'
        ],
      },
      {
        'title': 'Severe Bleeding & Hemorrhage Control',
        'icon': Icons.bloodtype_rounded,
        'color': Colors.deepOrange,
        'steps': [
          '1. Apply direct firm pressure on the wound with sterile gauze or clean cloth.',
          '2. Maintain continuous pressure for at least 10 minutes without lifting cloth to check.',
          '3. If blood soaks through, add more cloth on top — do not remove the original layer.',
          '4. Elevate the bleeding limb above heart level if no fracture is suspected.',
          '5. If life-threatening arterial spurting continues, apply a tourniquet 2-3 inches above the wound (never on a joint).'
        ],
      },
      {
        'title': 'Choking (Heimlich Maneuver)',
        'icon': Icons.air_rounded,
        'color': Colors.blueAccent,
        'steps': [
          '1. Identify: Victim cannot speak, cough forcefully, or grasp their throat.',
          '2. Stand behind victim, wrap arms around waist.',
          '3. Make a fist with thumb side against upper abdomen, just above the navel.',
          '4. Grasp fist with other hand and deliver quick, upward abdominal thrusts.',
          '5. Repeat until the foreign object is expelled or victim becomes unconscious.'
        ],
      },
      {
        'title': 'Burn Care & Trauma',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.amber.shade900,
        'steps': [
          '1. Immediately cool the burn under gentle running tap water for 15-20 minutes.',
          '2. DO NOT apply ice, ice water, butter, oil, or toothpaste to burns.',
          '3. Carefully remove rings, watches, or tight clothing around burned area before swelling.',
          '4. Cover loosely with sterile non-stick bandage or clean cling wrap.',
          '5. Seek immediate hospital care for facial burns, electrical burns, or chemical exposure.'
        ],
      },
      {
        'title': 'Snakebite Field Protocol',
        'icon': Icons.pest_control_rounded,
        'color': Colors.teal,
        'steps': [
          '1. Keep victim calm and completely still. Movement spreads venom through lymphatic system.',
          '2. Position the bitten limb below or at heart level.',
          '3. Remove rings, tight bracelets, and footwear immediately.',
          '4. DO NOT cut the wound, apply ice, suck out venom, or apply an arterial tourniquet.',
          '5. Transport victim immediately to a hospital equipped with polyvalent anti-snake venom (ASV).'
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline First-Aid Survival Guide'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: guides.length,
        itemBuilder: (ctx, index) {
          final item = guides[index];
          final color = item['color'] as Color;
          final steps = item['steps'] as List<String>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(item['icon'] as IconData, color: color),
              ),
              title: Text(
                item['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Tap to expand step-by-step instructions', style: TextStyle(fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps.map((step) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          step,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
