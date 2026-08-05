import 'package:flutter/material.dart';
import 'package:mobile/pages/chat/chat_details_page.dart';
import '../../services/api_services.dart';

class GroupDetailsController extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ChatMember> currentGroupMembers = [];
  Map<String, String> groupMemberNames = {};
  Map<String, String> userCache = {};
  bool isLoadingDetails = false;
  final Set<String> _fetchedGroups = {};
  bool hasFetchedGroup(String groupId) => _fetchedGroups.contains(groupId);

  Future<void> fetchGroupMembers(String groupId) async {
    try {
      isLoadingDetails = true;
      notifyListeners();

      final response = await _api.getGroupMembers(groupId);
      if (response.statusCode == 200) {
        final List<dynamic> memberList = _extractDataList(response.data, [
          'members',
          'data',
        ]);

        currentGroupMembers = memberList
            .map((json) => ChatMember.fromJson(json))
            .toList();

        for (var member in memberList) {
          final uid = member['user_id'].toString();
          userCache[uid] = member['display_name'] ?? 'Member';
          groupMemberNames[uid] = member['display_name'] ?? 'Unknown';
        }
      }
    } catch (e) {
      debugPrint("Error fetching members: $e");
    } finally {
      isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> preloadGroupMembers(String groupId) async {
    if (_fetchedGroups.contains(groupId)) return;

    _fetchedGroups.add(groupId);

    try {
      final res = await _api.getGroupMembers(groupId);
      final members = _extractDataList(res.data, ['members', 'data']);

      bool updatedCache = false;
      for (var m in members) {
        final uid = m['user_id'].toString();
        final name = m['display_name'] ?? 'Member';

        if (userCache[uid] != name) {
          userCache[uid] = name;
          updatedCache = true;
        }
      }

      if (updatedCache) notifyListeners();
    } catch (e) {
      _fetchedGroups.remove(groupId);
      debugPrint("Failed to preload group members for $groupId: $e");
    }
  }

  void clearCache() {
    currentGroupMembers.clear();
    groupMemberNames.clear();
    userCache.clear();
    _fetchedGroups.clear();
    isLoadingDetails = false;
    notifyListeners();
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
