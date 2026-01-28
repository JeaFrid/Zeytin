import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ZeytinClient {
  String _host = "";
  String _email = "";
  String _password = "";
  String _token = "";

  late Dio _dioInstance;
  bool _isInitialized = false;

  Dio get _dio {
    if (!_isInitialized) {
      _dioInstance = Dio(
        BaseOptions(
          baseUrl: _host,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      _isInitialized = true;
    }
    return _dioInstance;
  }

  Future<void> init({
    required String host,
    required String email,
    required String password,
  }) async {
    _host = host;
    _email = email;
    _password = password;
    _dio.options.baseUrl = _host;
  }

  Future<ZeytinResponse> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      Response response = await _dio.post(
        "/truck/create",
        data: {"email": email, "password": password},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opps...",
        error: e.message,
      );
    }
  }

  Future<String?> getToken() async {
    try {
      Response response = await _dio.post(
        "/token/create",
        data: {"email": _email, "password": _password},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      ZeytinResponse data = ZeytinResponse.fromMap(responseData);
      if (data.isSuccess && data.data is Map && data.data!["token"] != null) {
        _token = data.data!["token"];
        return _token;
      } else {
        ZeytinPrint.errorPrint(
          data.error ?? "There's an error message received by the client.",
        );
        return null;
      }
    } on DioException catch (e, s) {
      ZeytinPrint.errorPrint(
        "There's an error message received by the client: ${e.message}",
      );
      print(s);
      return null;
    }
  }

  Future<ZeytinResponse> addData({
    required String box,
    required String tag,
    required Map<String, dynamic> value,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({
        "box": box,
        "tag": tag,
        "value": value,
      });
      Response response = await _dio.post(
        "/data/add",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> getData({
    required String box,
    required String tag,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "tag": tag});
      Response response = await _dio.post(
        "/data/get",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      var zResponse = ZeytinResponse.fromMap(responseData);
      if (zResponse.isSuccess &&
          zResponse.data != null &&
          zResponse.data!["data"] != null) {
        var decrypted = tokener.decryptMap(zResponse.data!["data"]);
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: decrypted,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> deleteData({
    required String box,
    required String tag,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "tag": tag});
      Response response = await _dio.post(
        "/data/delete",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> deleteBox({required String box}) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box});
      Response response = await _dio.post(
        "/data/deleteBox",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> addBatch({
    required String box,
    required Map<String, Map<String, dynamic>> entries,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "entries": entries});
      Response response = await _dio.post(
        "/data/addBatch",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> getBox({required String box}) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box});
      Response response = await _dio.post(
        "/data/getBox",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      var zResponse = ZeytinResponse.fromMap(responseData);
      if (zResponse.isSuccess &&
          zResponse.data != null &&
          zResponse.data!["data"] != null) {
        var decrypted = tokener.decryptMap(zResponse.data!["data"]);
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: decrypted,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> existsBox({required String box}) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box});
      Response response = await _dio.post(
        "/data/existsBox",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      var zResponse = ZeytinResponse.fromMap(responseData);
      if (zResponse.isSuccess &&
          zResponse.data != null &&
          zResponse.data!["data"] != null) {
        var decrypted = tokener.decryptMap(zResponse.data!["data"]);
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: decrypted,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> existsTag({
    required String box,
    required String tag,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "tag": tag});
      Response response = await _dio.post(
        "/data/existsTag",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      var zResponse = ZeytinResponse.fromMap(responseData);
      if (zResponse.isSuccess &&
          zResponse.data != null &&
          zResponse.data!["data"] != null) {
        var decrypted = tokener.decryptMap(zResponse.data!["data"]);
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: decrypted,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> contains({
    required String box,
    required String tag,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "tag": tag});
      Response response = await _dio.post(
        "/data/contains",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      var zResponse = ZeytinResponse.fromMap(responseData);
      if (zResponse.isSuccess &&
          zResponse.data != null &&
          zResponse.data!["data"] != null) {
        var decrypted = tokener.decryptMap(zResponse.data!["data"]);
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: decrypted,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> search({
    required String box,
    required String field,
    required String prefix,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({
        "box": box,
        "field": field,
        "prefix": prefix,
      });
      Response response = await _dio.post(
        "/data/search",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      var zResponse = ZeytinResponse.fromMap(responseData);
      if (zResponse.isSuccess &&
          zResponse.data != null &&
          zResponse.data!["data"] != null) {
        var decrypted = tokener.decryptMap(zResponse.data!["data"]);
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: decrypted,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> filter({
    required String box,
    required String field,
    required String value,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({
        "box": box,
        "field": field,
        "value": value,
      });
      Response response = await _dio.post(
        "/data/filter",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      var zResponse = ZeytinResponse.fromMap(responseData);
      if (zResponse.isSuccess &&
          zResponse.data != null &&
          zResponse.data!["data"] != null) {
        var decrypted = tokener.decryptMap(zResponse.data!["data"]);
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: decrypted,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> uploadFile(String filePath, String fileName) async {
    try {
      var formData = FormData.fromMap({
        "token": _token,
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });
      Response response = await _dio.post("/storage/upload", data: formData);
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> deleteToken({
    required String email,
    required String password,
  }) async {
    try {
      Response response = await _dio.delete(
        "/token/delete",
        data: {"email": email, "password": password},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Stream<Map<String, dynamic>> watchBox({required String box}) {
    var wsUrl = "${_host.replaceFirst("http", "ws")}/data/watch/$_token/$box";
    var channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    var tokener = ZeytinTokener(_password);

    return channel.stream.map((message) {
      var decoded = jsonDecode(message);
      if (decoded["data"] != null) {
        decoded["data"] = tokener.decryptMap(decoded["data"]);
      }
      if (decoded["entries"] != null) {
        decoded["entries"] = tokener.decryptMap(decoded["entries"]);
      }
      return decoded as Map<String, dynamic>;
    });
  }
}

class ZeytinTokener {
  final Key key;
  final Encrypter encrypter;

  ZeytinTokener(String passphrase)
    : key = _deriveKey(passphrase),
      encrypter = Encrypter(AES(_deriveKey(passphrase), mode: AESMode.cbc));

  static Key _deriveKey(String passphrase) {
    final bytes = utf8.encode(passphrase);
    final hash = sha256.convert(bytes).bytes;
    return Key(Uint8List.fromList(hash));
  }

  String encryptMap(Map<String, dynamic> data) {
    final iv = IV.fromSecureRandom(16);
    final plainText = jsonEncode(data);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }

  Map<String, dynamic> decryptMap(String encryptedData) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw FormatException("Invalid encrypted data format");
    }
    final iv = IV.fromBase64(parts[0]);
    final cipherText = parts[1];
    final decrypted = encrypter.decrypt(
      Encrypted.fromBase64(cipherText),
      iv: iv,
    );
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }
}

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
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
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

class ZeytinPrint {
  static void successPrint(String data) {
    print('\x1B[32m[✅]: $data\x1B[0m');
  }

  static void errorPrint(String data) {
    print('\x1B[31m[❌]: $data\x1B[0m');
  }

  void warningPrint(String data) {
    print('\x1B[33m[❗]: $data\x1B[0m');
  }
}
