class ZeytinResponse {
  final bool isSuccess;
  final String message;
  final String? error;
  final Map<String, dynamic>? data;

  ZeytinResponse({
    required this.isSuccess,
    required this.message,
    this.error,
    this.data,
  });

  factory ZeytinResponse.fromMap(Map<String, dynamic> map) {
    return ZeytinResponse(
      isSuccess: map['isSuccess'] ?? false,
      message: map['message'] ?? '',
      error: map['error'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "isSuccess": isSuccess,
      "message": message,
      if (error != null) "error": error,
      if (data != null) "data": data,
    };
  }
}
