class ZeytinConfig {
  static const int maxTruckCount = 20;
  static const int maxTruckPerIp = 20;
  static const int truckCreationCooldownMs = 600000;
  static const int globalDosThreshold = 50000;
  static const int dosCooldownMs = 300000;
  static const int ipRateLimitMs = 1000;
  static const int generalIpRateLimit5Sec = 100;
  static bool sleepModeEnabled = true;
  static List<String> blackList = [];
  static List<String> whiteList = ["127.0.0.1"];
  static String liveKitUrl = "ws://127.0.0.1:7880";
  static String liveKitApiKey = "devkey";
  static String liveKitSecretKey = "secret";
}
