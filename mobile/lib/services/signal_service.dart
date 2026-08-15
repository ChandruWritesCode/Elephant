import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mobile/services/sqlite_signal_store.dart';
import 'package:mobile/services/db_services.dart';
import 'api_services.dart';

class SignalService {
  static final SignalService _instance = SignalService._internal();
  factory SignalService() => _instance;

  final ApiService _api = ApiService();

  late SQLiteSignalStore _store;
  bool _isInitialized = false;

  SignalService._internal();

  Future<void> initStore() async {
    if (_isInitialized) return;
    _store = SQLiteSignalStore();
    _isInitialized = true;
  }

  SignalProtocolAddress _getAddress(String userId) =>
      SignalProtocolAddress(userId, 1);

  Future<void> initializeAndUploadKeys(String currentUserId) async {
    await initStore();

    final db = await DatabaseHelper.instance.database;
    final existingKeys = await db.query('signal_local_keys', where: 'id = 1');

    if (existingKeys.isNotEmpty) {
      debugPrint("E2EE: Keys already exist locally. Skipping generation.");
      return;
    }

    debugPrint("E2EE: Generating new local identity keys...");

    final identityKeyPair = generateIdentityKeyPair();
    final registrationId = generateRegistrationId(false);

    await _store.storeLocalData(identityKeyPair, registrationId);

    final preKeys = generatePreKeys(0, 100);
    final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

    for (var preKey in preKeys) {
      await _store.storePreKey(preKey.id, preKey);
    }
    await _store.storeSignedPreKey(signedPreKey.id, signedPreKey);

    final publicPreKeys = preKeys
        .map(
          (k) => {
            'id': k.id, 
            'content': base64Encode(k.getKeyPair().publicKey.serialize()), 
          },
        )
        .toList();

    final payload = {
      'device_id': 'main', 
      'identity_key': base64Encode(identityKeyPair.getPublicKey().serialize()),
      'signed_prekey': base64Encode(signedPreKey.getKeyPair().publicKey.serialize()),
      'signature': base64Encode(signedPreKey.signature),
      'one_time_prekeys': publicPreKeys,
    };

    try {
      await _api.post("/e2ee/keys", data: payload); 
      debugPrint("E2EE Keys uploaded successfully");
    } catch (e) {
      debugPrint("Failed to upload E2EE keys: $e");
    }
  }

  Future<bool> establishSessionIfNeeded(String remoteUserId) async {
    await initStore();
    final address = _getAddress(remoteUserId);

    if (await _store.containsSession(address)) return true; 

    try {
      final response = await _api.get("/e2ee/bundle/$remoteUserId?device_id=main");
      final data = response.data['data'] ?? response.data;

      final identityKeyStr = data['identity_key'];
      final signedPreKeyStr = data['signed_prekey'];
      final signatureStr = data['signature'];
      final otpBodyStr = data['one_time_prekey_body'];
      final otpId = data['one_time_prekey_id'];

      if (identityKeyStr == null || signedPreKeyStr == null || signatureStr == null || otpBodyStr == null) {
        debugPrint("Receiver bundle is missing required cryptographic keys.");
        return false;
      }

      final identityKey = IdentityKey(Curve.decodePoint(base64Decode(identityKeyStr), 0));
      final signedPreKey = Curve.decodePoint(base64Decode(signedPreKeyStr), 0);
      final signature = base64Decode(signatureStr);
      final preKey = Curve.decodePoint(base64Decode(otpBodyStr), 0);

      final bundle = PreKeyBundle(
        0,                      
        1,                      
        (otpId as int?) ?? 1,   
        preKey,                 
        0,                      
        signedPreKey,           
        signature,              
        identityKey,            
      );

      final sessionBuilder = SessionBuilder(_store, _store, _store, _store, address);
      
      await sessionBuilder.processPreKeyBundle(bundle);
      debugPrint("E2EE Session established perfectly with $remoteUserId!");
      return true;

    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint("Receiver $remoteUserId has not registered E2EE keys yet.");
      } else {
        debugPrint("Network error fetching bundle for $remoteUserId: ${e.message}");
      }
      return false;
    } catch (e) {
      debugPrint("Failed to establish E2EE session with $remoteUserId: $e");
      return false;
    }
  }
  
  Future<Map<String, dynamic>> encryptMessage(
    String remoteUserId,
    String plaintext,
  ) async {
    debugPrint("SignalService: Encrypting message for $remoteUserId...");
    final address = _getAddress(remoteUserId);
    final sessionCipher = SessionCipher(
      _store,
      _store,
      _store,
      _store,
      address,
    );

    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final ciphertextMessage = await sessionCipher.encrypt(plaintextBytes);

    debugPrint("SignalService: Encryption successful (Type ${ciphertextMessage.getType()}).");
    return {
      'type': ciphertextMessage.getType(),
      'ciphertext': base64Encode(ciphertextMessage.serialize()),
    };
  }

  Future<String> decryptMessage(
    String remoteUserId,
    String base64Ciphertext,
    int type,
  ) async {
    debugPrint("SignalService: Decrypting message from $remoteUserId...");
    final address = _getAddress(remoteUserId);
    final sessionCipher = SessionCipher(
      _store,
      _store,
      _store,
      _store,
      address,
    );
    final bytes = base64Decode(base64Ciphertext);

    Uint8List plaintextBytes;

    if (type == CiphertextMessage.prekeyType) {
      plaintextBytes = await sessionCipher.decrypt(PreKeySignalMessage(bytes));
    } else {
      final signalMsg = SignalMessage.fromSerialized(bytes);
      plaintextBytes = await sessionCipher.decryptFromSignal(signalMsg);
    }

    debugPrint("SignalService: Decryption successful!");
    return utf8.decode(plaintextBytes);
  }

  Future<String?> getSafetyNumber(
    String localUserId,
    String remoteUserId,
  ) async {
    final localKeyPair = await _store.getIdentityKeyPair();
    final remoteAddress = _getAddress(remoteUserId);
    final remoteIdentity = await _store.getIdentity(remoteAddress);

    if (remoteIdentity == null) return null;

    final generator = NumericFingerprintGenerator(5200);

    final fingerprint = generator.createFor(
      1,
      Uint8List.fromList(utf8.encode(localUserId)),
      localKeyPair.getPublicKey(),
      Uint8List.fromList(utf8.encode(remoteUserId)),
      remoteIdentity,
    );

    return fingerprint.displayableFingerprint.localFingerprintNumbers;
  }

  Future<void> forceResetSession(String remoteUserId) async {
    final address = _getAddress(remoteUserId);
    await _store.deleteSession(address);
    await establishSessionIfNeeded(remoteUserId);
  }

  Future<void> clearAllSessions() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('signal_sessions');
  }
}