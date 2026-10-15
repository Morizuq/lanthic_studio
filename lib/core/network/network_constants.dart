class NetworkConstants {
  NetworkConstants._();

  static const Duration defaultConnectTimeout = Duration(seconds: 15);
  static const Duration defaultReceiveTimeout = Duration(seconds: 15);
  static const Duration defaultSendTimeout = Duration(seconds: 15);

  /// AI generation endpoints (FLUX, Imagen, SDXL) can take up to 60-120 seconds to render.
  static const Duration generationTimeout = Duration(seconds: 90);

  static const String authHeaderKey = 'Authorization';
  static const String apiKeyHeaderKey = 'X-Key';
  static const String acceptHeaderKey = 'Accept';
  static const String contentTypeHeaderKey = 'Content-Type';
  static const String jsonContentType = 'application/json';
}
