import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/models/group.dart';
import 'package:mobile/services/api.dart';

class GroupController extends ChangeNotifier {
  final Map<String, Map<String, String>> _selectedContacts = {};
  Map<String, Map<String, String>> get selectedContacts => _selectedContacts;

  void setContacts(Map<String, Map<String, String>> contacts) {
    _selectedContacts.clear();
    _selectedContacts.addAll(contacts);
    notifyListeners();
  }
//hhhh.1585
  void toggleContact(String id, Map<String, String> contactData) {
    if (_selectedContacts.containsKey(id)) {
      _selectedContacts.remove(id);
    } else {
      _selectedContacts[id] = contactData;
    }
    notifyListeners();
  }

  // --- Group Creation ---

  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Group?> createGroup({
    required String groupName,
    required List<String> memberIds,
  }) async {
    if (_isLoading) return null;

    try {
      _isLoading = true;
      notifyListeners();

      final createResponse = await _api.post(
        '/groups',
        data: {"name": groupName.trim()},
      );

      if (createResponse.statusCode == 200 ||
          createResponse.statusCode == 201) {
        final groupData =
            createResponse.data['data'] ??
            createResponse.data['group'] ??
            createResponse.data;

        final Group newGroup = Group.fromJson(groupData);

        if (memberIds.isNotEmpty) {
          final memberRequests = memberIds.map((userId) {
            return _api
                .post(
                  '/groups/${newGroup.id}/members',
                  data: {"user_id": userId},
                )
                .catchError((error) {
                  debugPrint("Failed to add user $userId to group: $error");
                  return Response(
                    requestOptions: RequestOptions(path: ''),
                    statusCode: 500,
                  );
                });
          });

          await Future.wait(memberRequests);
        }

        return newGroup;
      }

      return null;
    } on DioException catch (e) {
      debugPrint("Dio Error: ${e.message}");
      if (e.response != null) {
        debugPrint("Payload: ${e.response?.data}");
      }
      return null;
    } catch (e) {
      debugPrint("Error: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _api.post(
        '/groups/$groupId/members',
        data: {"user_id": userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint("Add Member Error: ${e.response?.data}");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _api.delete('/groups/$groupId/members/$userId');

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint("Remove Member Error: ${e.response?.data}");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearGroupData() {
    _selectedContacts.clear();
    _isLoading = false;
    notifyListeners();
  }
}
