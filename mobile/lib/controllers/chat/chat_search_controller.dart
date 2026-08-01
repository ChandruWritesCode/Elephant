import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class ChatSearchController extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<dynamic> contactSearchResults = [];
  bool isSearchLoading = false;

  Future<void> queryUsers(String term) async {
    final String cleanTerm = term.trim();
    if (cleanTerm.isEmpty || cleanTerm.length < 3) {
      contactSearchResults.clear();
      notifyListeners();
      return;
    }

    isSearchLoading = true;
    notifyListeners();

    try {
      final res = await _api.searchUsers(term);
      contactSearchResults = _extractDataList(res.data, ['users']);
    } catch (e) {
      debugPrint("User query failure: $e");
      contactSearchResults.clear();
    } finally {
      isSearchLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (contactSearchResults.isNotEmpty || isSearchLoading) {
      contactSearchResults.clear();
      isSearchLoading = false;
      notifyListeners();
    }
  }

  List<dynamic> _extractDataList(dynamic data, List<String> fallbackKeys) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'];
      for (final key in fallbackKeys) {
        if (data[key] is List) return data[key];
      }
    }
    return [];
  }
}
