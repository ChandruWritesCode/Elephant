import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/models/group.dart';
import 'package:mobile/services/api.dart';

class GroupController extends ChangeNotifier {
  final Map<String, Map<String, String>> _selectedContacts = {};

  Map<String, Map<String, String>> get selectedContacts => _selectedContacts;

  void addContacts(Map<String, Map<String, String>> contacts) {
    _selectedContacts.clear();
    _selectedContacts.addAll(contacts);
    notifyListeners();
  }

  // Group Creation

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
            return _api.post(
              '/groups/${newGroup.id}/members',
              data: {"user_id": userId},
            );
          });

          await Future.wait(memberRequests);
        }

        return newGroup;
      }

      return null;
    } on DioException catch (e) {
      debugPrint("Dio Error: ${e.message}");
      debugPrint("URL: ${e.requestOptions.uri}");

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
}
