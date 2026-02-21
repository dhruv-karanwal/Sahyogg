import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_gdg/config/vision_config.dart';

class GoogleVisionService {
  static const _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';

  final List<String> _floodKeywords = [
    'flood',
    'inundation',
    'water',
    'storm',
    'rain',
    'river',
    'rescue',
    'disaster',
    'landslide',
    'natural disaster',
    'flash flood',
    'watercourse',
    'bank', 
    'dam'
  ];

  Future<Map<String, dynamic>> analyzeImageUrl(String imageUrl) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$googleVisionApiKey');
      
      final requestBody = {
        "requests": [
          {
            "image": {
              "source": {"imageUri": imageUrl}
            },
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 10},
              {"type": "SAFE_SEARCH_DETECTION", "maxResults": 1}
            ]
          }
        ]
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Vision API Error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      final annotations = data['responses'][0];
      
      // 1. Process Safe Search
      final safeSearch = annotations['safeSearchAnnotation'] ?? {};
      if (_isUnsafe(safeSearch)) {
        return {
          'status': 'rejected_unsafe',
          'reason': 'unsafe_content',
          'isFloodLikely': false,
          'floodScore': 0.0,
          'safeSearch': safeSearch,
          'visionLabels': [],
        };
      }

      // 2. Process Labels & Calculate Score
      final labelsData = annotations['labelAnnotations'] as List? ?? [];
      final labels = labelsData.map((e) => {
        'description': e['description'],
        'score': e['score']
      }).toList();

      final floodScore = _calculateFloodScore(labels);
      final isFloodLikely = floodScore >= 0.60;

      return {
        'status': isFloodLikely ? 'verified_flood' : 'rejected_not_flood',
        'reason': isFloodLikely ? 'flood_match' : 'low_confidence',
        'isFloodLikely': isFloodLikely,
        'floodScore': floodScore,
        'safeSearch': safeSearch,
        'visionLabels': labels,
      };

    } catch (e) {
      print('Vision Analysis Failed: $e');
      // Fallback in case of API error, but don't auto-verify
      return {
        'status': 'error',
        'reason': e.toString(),
        'isFloodLikely': false,
        'floodScore': 0.0,
      };
    }
  }

  bool _isUnsafe(Map<String, dynamic> safeSearch) {
    const rejectedLevels = ['LIKELY', 'VERY_LIKELY'];
    
    // Check key categories
    final adult = safeSearch['adult'];
    final violence = safeSearch['violence'];
    final racy = safeSearch['racy'];

    if (rejectedLevels.contains(adult) || 
        rejectedLevels.contains(violence) || 
        rejectedLevels.contains(racy)) {
      return true;
    }
    return false;
  }

  double _calculateFloodScore(List<dynamic> labels) {
    double totalScore = 0.0;
    
    for (var label in labels) {
      final description = (label['description'] as String).toLowerCase();
      final score = (label['score'] as num).toDouble();

      for (var keyword in _floodKeywords) {
        if (description.contains(keyword)) {
          totalScore += score;
          break; // Count label only once even if multiple keywords match
        }
      }
    }
    
    // Cap score at 1.0 (or higher if you want cumulative strength)
    // The requirement says "Sum label scores", so it can exceed 1.0.
    // Let's normalize slightly or just keep raw sum. 
    // "FloodScore logic: Sum label scores that match flood keywords." -> OK.
    return totalScore;
  }
}