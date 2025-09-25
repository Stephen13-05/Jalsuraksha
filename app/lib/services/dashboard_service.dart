import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DashboardService {
  DashboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Fetch recent reports for a user or a village
  Future<List<Map<String, dynamic>>> fetchRecentReports({
    String? userId,
    String? village,
    int limit = 5,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _firestore.collection('reports').orderBy('createdAt', descending: true);
      if (userId != null) {
        q = q.where('createdBy', isEqualTo: userId);
      } else if (village != null) {
        q = q.where('village', isEqualTo: village);
      }
      final snap = await q.limit(limit).get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      // Fallback to empty list on error
      return [];
    }
  }

  // Fetch counts for daily/weekly/monthly cases for a village
  Future<({int daily, int weekly, int monthly})> fetchCaseCounts({
    required String village,
  }) async {
    try {
      // Expect a Firestore doc at metrics/{village}
      final doc = await _firestore.collection('metrics').doc(village).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return (
          daily: (data['dailyCases'] ?? 0) as int,
          weekly: (data['weeklyCases'] ?? 0) as int,
          monthly: (data['monthlyCases'] ?? 0) as int,
        );
      }
    } catch (_) {}
    return (daily: 0, weekly: 0, monthly: 0);
  }

  // Fetch risk level for a village: 'low' | 'medium' | 'high'
  Future<String> fetchRiskLevel({
    required String district,
    required String village,
  }) async {
    try {
      final doc = await _firestore.collection('risk').doc('$district:$village').get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final risk = (data['riskLevel'] ?? 'low').toString().toLowerCase();
        if (['low', 'medium', 'high', 'red', 'yellow', 'green'].contains(risk)) {
          return risk;
        }
      }
    } catch (_) {}
    return 'low';
  }

  // Geocode village via OpenStreetMap Nominatim (no API key)
  Future<({double lat, double lon})?> geocodeVillage({
    required String village,
    required String district,
    String country = 'India',
  }) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent('$village, $district, $country')}&format=json&limit=1');
      final res = await http.get(uri, headers: {
        'User-Agent': 'JalArogya/1.0 (dashboard)'
      });
      if (res.statusCode == 200) {
        final List data = json.decode(res.body) as List;
        if (data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) return (lat: lat, lon: lon);
        }
      }
    } catch (_) {}
    return null;
  }
}
