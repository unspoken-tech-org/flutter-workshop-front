class TokenRequest {
  final String boundDeviceId;
  final String appVersion;

  TokenRequest({
    required this.boundDeviceId,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'boundDeviceId': boundDeviceId,
        'appVersion': appVersion,
      };
}
