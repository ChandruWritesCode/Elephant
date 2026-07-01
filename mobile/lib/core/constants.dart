// lib/core/constants.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Env {
  static const String defaultHost = "elephant.commandlinecoding.in";
  static const String defaultPort = "443";

  static String host = defaultHost;
  static String port = defaultPort;

  static String get httpBaseUrl {
    final protocol = (port == "443" || host.contains("commandlinecoding.in")) ? "https" : "http";
    final portSuffix = (port == "80" || port == "443") ? "" : ":$port";
    return "$protocol://$host$portSuffix/api";
  }

  static String get wsBaseUrl {
    final protocol = (port == "443" || host.contains("commandlinecoding.in")) ? "wss" : "ws";
    final portSuffix = (port == "80" || port == "443") ? "" : ":$port";
    return "$protocol://$host$portSuffix/api/ws";
  }

  static Future<void> init() async {
    const storage = FlutterSecureStorage();
    host = await storage.read(key: "custom_host") ?? defaultHost;
    port = await storage.read(key: "custom_port") ?? defaultPort;
  }

  static Future<void> updateConfig(String newHost, String newPort) async {
    host = newHost.trim().isEmpty ? defaultHost : newHost.trim();
    port = newPort.trim().isEmpty ? defaultPort : newPort.trim();

    const storage = FlutterSecureStorage();
    await storage.write(key: "custom_host", value: host);
    await storage.write(key: "custom_port", value: port);
  }
}