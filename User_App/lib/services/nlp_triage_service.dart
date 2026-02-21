class NLPTriageService {
  // RED: Immediate life-threatening emergencies
  static const List<String> _redKeywords = [
    'medical', 'heart', 'attack', 'bleeding', 'blood', 'dying', 'dead', 'death',
    'trapped', 'stuck', 'drowning', 'water rising', 'fire', 'burn', 'breathe',
    'choking', 'unconscious', 'fainted', 'seizure', 'casualty', 'severe',
    'critical', 'emergency', 'crushed', 'collapse'
  ];

  // ORANGE: Urgent but not immediately life-threatening (vulnerable people, running out of supplies fast)
  static const List<String> _orangeKeywords = [
    'pregnant', 'baby', 'child', 'infant', 'elderly', 'old man', 'old woman',
    'senior', 'disabled', 'wheelchair', 'stranded', 'isolated', 'running out',
    'starving', 'dehydrated', 'fever', 'infection', 'asthma', 'inhaler',
    'insulin', 'property damage', 'roof collapse'
  ];

  // YELLOW: Moderate needs (low on supplies, minor sickness, safe but need evac soon)
  static const List<String> _yellowKeywords = [
    'food', 'water', 'hungry', 'thirsty', 'ration', 'supply', 'medicine',
    'pill', 'prescription', 'cold', 'freezing', 'blanket', 'shelter', 'roof',
    'power', 'electricity', 'battery', 'charge', 'generator', 'evacuate',
    'flooded', 'damage', 'injured', 'sprain', 'cut'
  ];

  // WHITE: Information, general queries, check-ins, reporting without immediate danger
  static const List<String> _whiteKeywords = [
    'info', 'information', 'update', 'road', 'blocked', 'highway', 'street',
    'bridge', 'when', 'how', 'where', 'status', 'safe', 'clear', 'weather',
    'rain', 'storm', 'wind', 'alert', 'notice', 'query', 'check', 'report',
    'tree down', 'pothole', 'traffic', 'general'
  ];

  static Map<String, String> analyzeSOS(String description, String type) {
    if (description.isEmpty && type.isEmpty) {
      return {'priority': 'WHITE', 'tag': 'General Context'};
    }

    // Convert to lowercase for case-insensitive matching
    final textToAnalyze = '$description $type'.toLowerCase();

    // 1. Check for RED keywords
    for (final keyword in _redKeywords) {
      if (textToAnalyze.contains(keyword)) {
        return {'priority': 'RED', 'tag': 'Life-Threatening'};
      }
    }

    // 2. Check for ORANGE keywords
    for (final keyword in _orangeKeywords) {
      if (textToAnalyze.contains(keyword)) {
        return {'priority': 'ORANGE', 'tag': 'High Urgency'};
      }
    }

    // 3. Check for YELLOW keywords
    for (final keyword in _yellowKeywords) {
      if (textToAnalyze.contains(keyword)) {
        return {'priority': 'YELLOW', 'tag': 'Moderate Relieve'};
      }
    }

    // 4. Check for WHITE keywords
    for (final keyword in _whiteKeywords) {
      if (textToAnalyze.contains(keyword)) {
        return {'priority': 'WHITE', 'tag': 'Information/General'};
      }
    }

    // Default fallback
    return {'priority': 'WHITE', 'tag': 'Unclassified Info'};
  }
}
