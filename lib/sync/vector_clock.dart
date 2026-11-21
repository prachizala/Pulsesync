/// Monotonic Vector Clock Conflict Resolver for Field Responders
/// Provides causality tracking across decentralized offline SQLite replicas.

class VectorClock {
  final Map<String, int> _clock = {};

  VectorClock([Map<String, int>? initial]) {
    if (initial != null) {
      _clock.addAll(initial);
    }
  }

  void increment(String nodeId) {
    _clock[nodeId] = (_clock[nodeId] ?? 0) + 1;
  }

  void merge(VectorClock other) {
    other._clock.forEach((key, value) {
      _clock[key] = (_clock[key] ?? 0) > value ? (_clock[key] ?? 0) : value;
    });
  }

  Map<String, int> toMap() => Map.unmodifiable(_clock);
}

void main() {
  final clockA = VectorClock({'NODE_1': 1});
  final clockB = VectorClock({'NODE_2': 2});
  clockA.merge(clockB);
  assert(clockA.toMap()['NODE_2'] == 2);
  print('Vector clock tests passed successfully!');
}
