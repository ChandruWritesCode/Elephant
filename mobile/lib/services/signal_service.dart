import 'dart:convert';
import 'dart:typed_data';
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
            'keyId': k.id,
            'publicKey': base64Encode(k.getKeyPair().publicKey.serialize()),
          },
        )
        .toList();

    final payload = {
      'registrationId': registrationId,
      'identityKey': base64Encode(identityKeyPair.getPublicKey().serialize()),
      'signedPreKey': {
        'keyId': signedPreKey.id,
        'publicKey': base64Encode(
          signedPreKey.getKeyPair().publicKey.serialize(),
        ),
        'signature': base64Encode(signedPreKey.signature),
      },
      'preKeys': publicPreKeys,
    };

    try {
      await _api.post("/keys", data: payload);
      debugPrint("E2EE Keys uploaded successfully");
    } catch (e) {
      debugPrint("Failed to upload E2EE keys: $e");
    }
  }

  Future<void> establishSessionIfNeeded(String remoteUserId) async {
    await initStore();
    final address = _getAddress(remoteUserId);

    if (await _store.containsSession(address)) return;

    try {
      final response = await _api.get("/bundle/$remoteUserId");
      final data = response.data['data'] ?? response.data;

      final identityKey = IdentityKey(
        Curve.decodePoint(base64Decode(data['identityKey']), 0),
      );
      final signedPreKey = Curve.decodePoint(
        base64Decode(data['signedPreKey']['publicKey']),
        0,
      );
      final signature = base64Decode(data['signedPreKey']['signature']);
      final preKey = Curve.decodePoint(
        base64Decode(data['preKey']['publicKey']),
        0,
      );

      final bundle = PreKeyBundle(
        data['registrationId'],
        1,
        data['preKey']['keyId'],
        preKey,
        data['signedPreKey']['keyId'],
        signedPreKey,
        signature,
        identityKey,
      );

      final sessionBuilder = SessionBuilder(
        _store,
        _store,
        _store,
        _store,
        address,
      );
      await sessionBuilder.processPreKeyBundle(bundle);
    } catch (e) {
      debugPrint("Failed to establish E2EE session with $remoteUserId: $e");
    }
  }

  Future<Map<String, dynamic>> encryptMessage(
    String remoteUserId,
    String plaintext,
  ) async {
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
