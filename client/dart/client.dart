import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
const bool isRelease = bool.fromEnvironment('dart.vm.product');
const bool isDebug = !isRelease;


class ZeytinClient {
  String _host = "";
  String _email = "";
  String _password = "";
  String _token = "";
  String _truckID = "";
  String get host => _host;
  String get email => _email;
  String get password => _password;
  String get token => _token;
  String get truck => _truckID;
  late Dio _dioInstance;
  bool _isInitialized = false;

  Dio get _dio {
    if (!_isInitialized) {
      _dioInstance = Dio(
        BaseOptions(
          baseUrl: _host,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
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
    var l = await _login(email: email, password: password);
    if (l.isSuccess) {
      _truckID = l.data?["id"] ?? "";
      ZeytinPrint.successPrint(
        "Hello developer! You are currently connected to the Zeytin server. Keep your code clean!",
      );
      ZeytinPrint.warningPrint("Host: $host");
      ZeytinPrint.warningPrint("Email: $email");
      ZeytinPrint.warningPrint("Truck: $truck");
      Timer.periodic(Duration(seconds: 35), (timer) async {
        await getToken();
      });
    } else {
      ZeytinPrint.warningPrint(
        "Hello developer! I couldn't find a truck for the account you entered.",
      );
      ZeytinPrint.successPrint("A truck has set off for you...");
      var c = await _createAccount(email: email, password: password);
      if (c.isSuccess) {
        ZeytinPrint.successPrint(
          "Hello developer! You are currently connected to the Zeytin server. Keep your code clean!",
        );
        ZeytinPrint.warningPrint("Host: $host");
        ZeytinPrint.warningPrint("Email: $email");
        ZeytinPrint.warningPrint("Truck: $truck");
        Timer.periodic(Duration(seconds: 50), (timer) async {
          await getToken();
        });
      } else {
        ZeytinPrint.errorPrint("There is a problem with the server.");
      }
    }
  }

  Future<ZeytinResponse> _createAccount({
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

  Future<ZeytinResponse> _login({
    required String email,
    required String password,
  }) async {
    try {
      Response response = await _dio.post(
        "/truck/id",
        data: {"email": email, "password": password},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      ZeytinResponse zResponse = ZeytinResponse.fromMap(responseData);
      if (zResponse.isSuccess && zResponse.data != null) {
        _email = email;
        _password = password;
        await getToken();
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opps...",
        error: e.response?.data != null && e.response?.data is Map
            ? e.response?.data["error"]
            : e.message,
      );
    }
  }

  String getFileUrl({required String fileId}) {
    final String effectiveTruckId = _truckID;
    final String baseUrl = _dio.options.baseUrl;
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return "$normalizedBaseUrl/$effectiveTruckId/$fileId";
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
      ZeytinPrint.errorPrint(
        "There's an error message received by the client: $s",
      );
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
      var zResponse = ZeytinResponse.fromMap(responseData, password: _password);
      if (zResponse.isSuccess && zResponse.data != null) {
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: zResponse.data,
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

      var zResponse = ZeytinResponse.fromMap(responseData, password: _password);
      if (zResponse.isSuccess && zResponse.data != null) {
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: zResponse.data,
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
    var wsUrl = "${_host.replaceFirst("https", "wss")}/data/watch/$_token/$box";
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

  factory ZeytinResponse.fromMap(Map<String, dynamic> map, {String? password}) {
    var rawData = map['data'];
    Map<String, dynamic>? processedData;

    if (rawData != null) {
      if (rawData is Map) {
        processedData = Map<String, dynamic>.from(rawData);
      } else if (rawData is String && password != null) {
        try {
          processedData = ZeytinTokener(password).decryptMap(rawData);
        } catch (e) {
          ZeytinPrint.errorPrint("Şifre çözme hatası: $e");
          processedData = null;
        }
      }
    }

    return ZeytinResponse(
      isSuccess: map['isSuccess'] ?? false,
      message: map['message'] ?? '',
      error: map['error']?.toString(),
      data: processedData,
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
    if (isDebug) {
      print('\x1B[32m[✅]: $data\x1B[0m');
    }
  }

  static void errorPrint(String data) {
    if (isDebug) {
      print('\x1B[31m[❌]: $data\x1B[0m');
    }
  }

  static void warningPrint(String data) {
    if (isDebug) {
      print('\x1B[33m[❗]: $data\x1B[0m');
    }
  }
}

class ZeytinSocialCommentsModel {
  final ZeytinUserResponse? user;
  final String? text;
  final String? id;
  final String? postID;
  final List<String>? likes;
  final Map<String, dynamic>? moreData;
  ZeytinSocialCommentsModel(
    this.user,
    this.text,
    this.likes,
    this.postID,
    this.id,
    this.moreData,
  );
  Map<String, dynamic> toJson() {
    return {
      "user": user?.toJson() ?? {},
      "text": text ?? "",
      "id": id ?? "",
      "likes": likes ?? [],
      "post": postID ?? "",
      "moreData": moreData ?? {},
    };
  }

  ZeytinSocialCommentsModel copyWith({
    ZeytinUserResponse? user,
    String? text,
    List<String>? likes,
    String? postID,
    String? id,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinSocialCommentsModel(
      user ?? this.user,
      text ?? this.text,
      likes ?? this.likes,
      postID ?? this.postID,
      id ?? this.id,
      moreData ?? this.moreData,
    );
  }

  factory ZeytinSocialCommentsModel.fromJson(Map<String, dynamic> data) {
    return ZeytinSocialCommentsModel(
      data["user"] != null ? ZeytinUserResponse.fromJson(data["user"]) : null,
      data["text"],
      (data["likes"] as List?)?.cast<String>() ?? [],
      data["postID"] ?? "",
      data["id"],
      data["moreData"] ?? {},
    );
  }
}

class ZeytinSocialModel {
  final ZeytinUserResponse? user;
  final String? text;
  final String? id;
  String? category;
  final List<String>? images;
  final List<String>? docs;
  final List<String>? locations;
  final List<String>? likes;
  final List<ZeytinSocialCommentsModel>? comments;
  final Map<String, dynamic>? moreData;
  ZeytinSocialModel({
    this.moreData,
    this.user,
    this.category,
    this.text,
    this.images,
    this.docs,
    this.locations,
    this.id,
    this.likes,
    this.comments,
  });
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> coms = [];
    if (comments != null) {
      for (var element in comments!) {
        coms.add(element.toJson());
      }
    }

    return {
      "user": user?.toJson() ?? {},
      "text": text ?? "",
      "images": images ?? [],
      "docs": docs ?? [],
      "category": category ?? "",
      "locations": locations ?? [],
      "id": id ?? "",
      "moreData": moreData ?? {},
      "likes": likes ?? [],
      "comments": comments == null ? [] : coms,
    };
  }

  ZeytinSocialModel copyWith({
    ZeytinUserResponse? user,
    String? text,
    String? category,
    String? id,
    List<String>? images,
    List<String>? docs,
    List<String>? locations,
    List<String>? likes,
    List<ZeytinSocialCommentsModel>? comments,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinSocialModel(
      user: user ?? this.user,
      text: text ?? this.text,
      category: category ?? this.category,
      images: images ?? this.images,
      docs: docs ?? this.docs,
      locations: locations ?? this.locations,
      id: id ?? this.id,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      moreData: moreData ?? this.moreData,
    );
  }

  factory ZeytinSocialModel.fromJson(Map<String, dynamic> data) {
    List<ZeytinSocialCommentsModel> coms = [];
    for (var element in data["comments"]) {
      coms.add(ZeytinSocialCommentsModel.fromJson(element));
    }

    return ZeytinSocialModel(
      user: ZeytinUserResponse.fromJson(data["user"]),
      text: data["text"] ?? "",
      images: data["images"] ?? [],
      category: data["category"] ?? "",
      docs: data["docs"] ?? [],
      locations: data["locations"] ?? [],
      id: data["id"] ?? "",
      likes: (data["likes"] as List?)?.cast<String>() ?? [],
      comments: coms,
      moreData: data["moreData"] ?? {},
    );
  }
}

class ZeytinSocial {
  ZeytinClient zeytin;
  ZeytinSocial(this.zeytin);
  Future<ZeytinResponse> createPost({
    required ZeytinSocialModel postModel,
  }) async {
    String id = Uuid().v1();

    return await zeytin.addData(
      box: "social",
      tag: id,
      value: postModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinResponse> editPost({
    required String id,
    required ZeytinSocialModel postModel,
  }) async {
    return await zeytin.addData(
      box: "social",
      tag: id,
      value: postModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinResponse> addLike({
    required ZeytinUserResponse user,
    required String postID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    if ((post.likes ?? []).contains(user.uid)) {
      return ZeytinResponse(isSuccess: true, message: "message");
    } else {
      List<String> likes = (post.likes ?? []);
      likes.add(user.uid);
      ZeytinSocialModel newPost = post.copyWith(likes: likes);
      await editPost(id: postID, postModel: newPost);
      return ZeytinResponse(isSuccess: true, message: "message");
    }
  }

  Future<ZeytinResponse> removeLike({
    required ZeytinUserResponse user,
    required String postID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    if ((post.likes ?? []).contains(user.uid)) {
      List<String> likes = (post.likes ?? []);
      likes.remove(user.uid);
      ZeytinSocialModel newPost = post.copyWith(likes: likes);
      await editPost(id: postID, postModel: newPost);
      return ZeytinResponse(isSuccess: true, message: "message");
    } else {
      return ZeytinResponse(isSuccess: true, message: "message");
    }
  }

  Future<ZeytinResponse> addComment({
    required ZeytinSocialCommentsModel comment,
    required String postID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    List<ZeytinSocialCommentsModel> comments = [];
    comments = post.comments ?? [];
    comments.add(comment.copyWith(id: Uuid().v1()));
    ZeytinSocialModel newPost = post.copyWith(comments: comments);
    await editPost(id: postID, postModel: newPost);
    return ZeytinResponse(isSuccess: true, message: "ok");
  }

  Future<ZeytinResponse> deleteComment({
    required String commentID,
    required String postID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    List<ZeytinSocialCommentsModel> comments = [];
    comments = post.comments ?? [];
    comments.removeWhere((element) => element.id == commentID);
    ZeytinSocialModel newPost = post.copyWith(comments: comments);
    await editPost(id: postID, postModel: newPost);
    return ZeytinResponse(isSuccess: true, message: "ok");
  }

  Future<ZeytinResponse> addCommentLike({
    required ZeytinUserResponse user,
    required String postID,
    required String commentID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);

    List<ZeytinSocialCommentsModel> comments = post.comments ?? [];
    bool updated = false;

    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentID) {
        List<String> commentLikes = comments[i].likes ?? [];

        if (!commentLikes.contains(user.uid)) {
          commentLikes.add(user.uid);
          comments[i] = ZeytinSocialCommentsModel(
            comments[i].user,
            comments[i].text,
            commentLikes,
            comments[i].postID,
            comments[i].id,
            comments[i].moreData,
          );
          updated = true;
        }
        break;
      }
    }

    if (updated) {
      ZeytinSocialModel newPost = post.copyWith(comments: comments);
      await editPost(id: postID, postModel: newPost);
      return ZeytinResponse(isSuccess: true, message: "Comment liked");
    }

    return ZeytinResponse(
      isSuccess: false,
      message: "No comments found or it's already liked.",
    );
  }

  Future<ZeytinResponse> removeCommentLike({
    required ZeytinUserResponse user,
    required String postID,
    required String commentID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);

    List<ZeytinSocialCommentsModel> comments = post.comments ?? [];
    bool updated = false;

    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentID) {
        List<String> commentLikes = comments[i].likes ?? [];

        if (commentLikes.contains(user.uid)) {
          commentLikes.remove(user.uid);
          comments[i] = ZeytinSocialCommentsModel(
            comments[i].user,
            comments[i].text,
            commentLikes,
            comments[i].postID,
            comments[i].id,
            comments[i].moreData,
          );
          updated = true;
        }
        break;
      }
    }

    if (updated) {
      ZeytinSocialModel newPost = post.copyWith(comments: comments);
      await editPost(id: postID, postModel: newPost);
      return ZeytinResponse(isSuccess: true, message: "Comment like removed");
    }

    return ZeytinResponse(
      isSuccess: false,
      message: "No comments or likes found.",
    );
  }

  Future<List<ZeytinSocialCommentsModel>> getComments({
    required String postID,
    int? limit,
    int? offset,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    List<ZeytinSocialCommentsModel> allComments = post.comments ?? [];

    if (offset != null && offset >= allComments.length) {
      return [];
    }

    int startIndex = offset ?? 0;
    int endIndex = limit != null ? startIndex + limit : allComments.length;

    if (endIndex > allComments.length) {
      endIndex = allComments.length;
    }

    if (startIndex >= endIndex) {
      return [];
    }

    return allComments.sublist(startIndex, endIndex);
  }

  Future<ZeytinSocialModel> getPost({required String id}) async {
    var post = await zeytin.getData(box: "social", tag: id);
    return ZeytinSocialModel.fromJson(post.data ?? {});
  }

  Future<List<ZeytinSocialModel>> getAllPost() async {
    List<ZeytinSocialModel> list = [];
    var social = await zeytin.getBox(box: "social");
    for (var element in social.data!.keys) {
      list.add(ZeytinSocialModel.fromJson(social.data![element]));
    }

    return list;
  }
}

class ZeytinBaseUser {
  ZeytinClient zeytin;
  ZeytinBaseUser(this.zeytin);
  Future<ZeytinResponse> create(
    String name,
    String email,
    String password,
  ) async {
    try {
      bool existEmail = await exist(email);
      if (existEmail) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Email available",
          error: "This email is already registered.",
        );
      } else {
        String uid = const Uuid().v1();
        var emptyUser = ZeytinUserResponse.empty();
        var newUser = emptyUser.copyWith(
          uid: uid,
          username: name,
          email: email,
          password: password,
          accountCreation: DateTime.now().toIso8601String(),
        );
        var res = await zeytin.addData(
          box: "users",
          tag: uid,
          value: newUser.toJson(),
        );

        if (res.isSuccess) {
          return ZeytinResponse(
            isSuccess: true,
            message: "ok",
            data: newUser.toJson(),
          );
        }
        return res;
      }
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Error",
        error: e.toString(),
      );
    }
  }

  Future<bool> exist(String email) async {
    var res = await zeytin.getBox(box: "users");
    for (var element in res.data?.keys ?? []) {
      var user = ZeytinUserResponse.fromJson(res.data![element]);

      if (user.email.toLowerCase() == email.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  Future<ZeytinResponse> login(String email, String password) async {
    try {
      bool existE = await exist(email);
      if (existE) {
        var res = await zeytin.getBox(box: "users");

        for (var element in res.data!.keys) {
          var val = res.data![element];
          if (val["email"].toString().toLowerCase() == email.toLowerCase()) {}
          if (val["email"].toString().toLowerCase() == email.toLowerCase() &&
              val["password"].toString().trim() == password.toString().trim()) {
            return ZeytinResponse(isSuccess: true, message: "ok", data: val);
          }
        }
        return ZeytinResponse(isSuccess: false, message: "Wrong password");
      } else {
        return ZeytinResponse(isSuccess: false, message: "Account not found");
      }
    } catch (e) {
      ZeytinPrint.errorPrint(e.toString());
      return ZeytinResponse(
        isSuccess: false,
        message: "Opps...",
        error: e.toString(),
      );
    }
  }

  Future<ZeytinUserResponse?> getProfile({required String userId}) async {
    try {
      final userData = await zeytin.getData(box: "users", tag: userId);
      if (userData.data == null) return null;
      return ZeytinUserResponse.fromJson(userData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<List<ZeytinUserResponse>> getAllProfile() async {
    try {
      final allUsers = await zeytin.getBox(box: "users");
      List<ZeytinUserResponse> users = [];
      for (var element in allUsers.data!.keys) {
        users.add(ZeytinUserResponse.fromJson(allUsers.data![element]));
      }
      return users;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> updateProfile(ZeytinUserResponse user) async {
    try {
      var res = await zeytin.addData(
        box: "users",
        tag: user.uid,
        value: user.toJson(),
      );
      if (res.isSuccess) {
        return ZeytinResponse(
          isSuccess: true,
          message: "ok",
          data: user.toJson(),
        );
      } else {
        return res;
      }
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: e.toString(),
        error: e.toString(),
      );
    }
  }
}

class RevaniChat {
  ZeytinClient zeytin;
  RevaniChat(this.zeytin);

  Future<ZeytinResponse> createChat({
    required String chatId,
    required String chatName,
    required List<String> participantIds,
    required String type,
    String? chatPhotoURL,
    List<String>? adminIds,
    Map<String, dynamic>? themeSettings,
    String? disappearingMessagesTimer,
  }) async {
    try {
      final chat = Chat(
        chatID: chatId,
        chatName: chatName,
        chatPhotoURL: chatPhotoURL,
        type: type,
        adminIDs: adminIds ?? (type == "private" ? [] : participantIds),
        themeSettings: themeSettings,
        disappearingMessagesTimer: disappearingMessagesTimer,
        participants: null,
        createdAt: DateTime.now(),
      );

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? messageType,
    RevaniMedia? media,
    RevaniLocation? location,
    RevaniContact? contact,
    String? replyToMessageId,
    List<String>? mentions,
    Duration? selfDestructTimer,
    String? botId,
    List<RevaniInteractiveButton>? interactiveButtons,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageId = Uuid().v1();
      final now = DateTime.now();
      final selfDestructTimestamp = selfDestructTimer != null
          ? now.add(selfDestructTimer)
          : null;

      final message = RevaniMessage(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        text: text,
        timestamp: now,
        messageType: messageType ?? 'text',
        status: 'sent',
        media: media,
        location: location,
        contact: contact,
        replyToMessageId: replyToMessageId,
        mentions: mentions ?? [],
        selfDestructTimer: selfDestructTimer,
        selfDestructTimestamp: selfDestructTimestamp,
        botId: botId,
        interactiveButtons: interactiveButtons ?? [],
        metadata: metadata ?? {},
      );

      final response = await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );

      if (response.isSuccess == true) {
        await _updateChatLastMessage(chatId, message);
      }

      return response;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<RevaniMessage>> getMessages({
    required String chatId,
    int? limit,
    int? offset,
    String? beforeMessageId,
    DateTime? beforeTimestamp,
  }) async {
    try {
      final allMessages = await zeytin.getBox(box: "messages");

      List<RevaniMessage> chatMessages = [];
      for (var item in allMessages.data!.values) {
        final message = RevaniMessage.fromJson(item.value);
        if (message.chatId == chatId) {
          chatMessages.add(message);
        }
      }

      chatMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (beforeMessageId != null) {
        final index = chatMessages.indexWhere(
          (m) => m.messageId == beforeMessageId,
        );
        if (index != -1) {
          chatMessages = chatMessages.sublist(index + 1);
        }
      } else if (beforeTimestamp != null) {
        chatMessages = chatMessages
            .where((m) => m.timestamp.isBefore(beforeTimestamp))
            .toList();
      }

      final startIndex = offset ?? 0;
      final endIndex = limit != null
          ? (startIndex + limit).clamp(0, chatMessages.length)
          : chatMessages.length;

      if (startIndex >= chatMessages.length) {
        return [];
      }

      return chatMessages.sublist(startIndex, endIndex).reversed.toList();
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> editMessage({
    required String messageId,
    required String newText,
    String? editedBy,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      if (message.isDeleted) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Cannot edit deleted message",
        );
      }

      message = message.copyWith(
        text: newText,
        isEdited: true,
        editedTimestamp: DateTime.now(),
      );

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> deleteMessage({
    required String messageId,
    required String userId,
    bool deleteForEveryone = false,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      if (message.senderId != userId && !deleteForEveryone) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      message = message.copyWith(
        isDeleted: true,
        deletedForEveryone: deleteForEveryone,
      );

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      final existingReactions = message.reactions.reactions;
      final reactionsForEmoji = existingReactions[emoji] ?? [];

      final alreadyReacted = reactionsForEmoji.any((r) => r.userId == userId);
      if (alreadyReacted) {
        return ZeytinResponse(isSuccess: true, message: "Already reacted");
      }

      final newReaction = RevaniReaction(
        emoji: emoji,
        userId: userId,
        timestamp: DateTime.now(),
      );

      reactionsForEmoji.add(newReaction);
      existingReactions[emoji] = reactionsForEmoji;

      message = message.copyWith(
        reactions: RevaniMessageReactions(reactions: existingReactions),
      );

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      final existingReactions = message.reactions.reactions;
      final reactionsForEmoji = existingReactions[emoji] ?? [];

      final index = reactionsForEmoji.indexWhere((r) => r.userId == userId);
      if (index == -1) {
        return ZeytinResponse(isSuccess: true, message: "Reaction not found");
      }

      reactionsForEmoji.removeAt(index);

      if (reactionsForEmoji.isEmpty) {
        existingReactions.remove(emoji);
      } else {
        existingReactions[emoji] = reactionsForEmoji;
      }

      message = message.copyWith(
        reactions: RevaniMessageReactions(reactions: existingReactions),
      );

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> markAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      final readBy = message.statusInfo.readBy;
      if (!readBy.contains(userId)) {
        readBy.add(userId);
      }

      final statusInfo = message.statusInfo.copyWith(
        readBy: readBy,
        readAt: readBy.length == 1 ? DateTime.now() : message.statusInfo.readAt,
      );

      message = message.copyWith(statusInfo: statusInfo);

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> markAsDelivered({
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      final deliveredTo = message.statusInfo.deliveredTo;
      if (!deliveredTo.contains(userId)) {
        deliveredTo.add(userId);
      }

      final statusInfo = message.statusInfo.copyWith(
        deliveredTo: deliveredTo,
        deliveredAt: deliveredTo.length == 1
            ? DateTime.now()
            : message.statusInfo.deliveredAt,
      );

      message = message.copyWith(statusInfo: statusInfo);

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> forwardMessage({
    required String originalMessageId,
    required String targetChatId,
    required String senderId,
  }) async {
    try {
      final messageData = await zeytin.getData(
        box: "messages",
        tag: originalMessageId,
      );

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      final originalMessage = RevaniMessage.fromJson(messageData.data!);

      final newMessageId = Uuid().v1();
      final now = DateTime.now();

      final forwardedMessage = RevaniMessage(
        messageId: newMessageId,
        chatId: targetChatId,
        senderId: senderId,
        text: originalMessage.text,
        timestamp: now,
        messageType: originalMessage.messageType,
        status: 'sent',
        isForwarded: true,
        forwardedFrom: originalMessage.senderId,
        media: originalMessage.media,
        location: originalMessage.location,
        contact: originalMessage.contact,
        mentions: originalMessage.mentions,
      );

      final response = await zeytin.addData(
        box: "messages",
        tag: newMessageId,
        value: forwardedMessage.toJson(),
      );

      if (response.isSuccess == true) {
        await _updateChatLastMessage(targetChatId, forwardedMessage);
      }

      return response;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> pinMessage({
    required String messageId,
    required String pinnedBy,
    required String chatId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      if (message.chatId != chatId) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Message not in this chat",
        );
      }

      message = message.copyWith(
        isPinned: true,
        pinnedBy: pinnedBy,
        pinnedTimestamp: DateTime.now(),
      );

      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) {
        var chat = Chat.fromJson(chatData.data!);
        final pinnedMessageIDs = chat.pinnedMessageIDs ?? [];
        if (!pinnedMessageIDs.contains(messageId)) {
          pinnedMessageIDs.add(messageId);
          chat = chat.copyWith(pinnedMessageIDs: pinnedMessageIDs);
          await zeytin.addData(box: "chats", tag: chatId, value: chat.toJson());
        }
      }

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> unpinMessage({
    required String messageId,
    required String chatId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      message = message.copyWith(
        isPinned: false,
        pinnedBy: null,
        pinnedTimestamp: null,
      );

      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) {
        var chat = Chat.fromJson(chatData.data!);
        final pinnedMessageIDs = chat.pinnedMessageIDs ?? [];
        pinnedMessageIDs.remove(messageId);
        chat = chat.copyWith(pinnedMessageIDs: pinnedMessageIDs);
        await zeytin.addData(box: "chats", tag: chatId, value: chat.toJson());
      }

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> starMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      final starredBy = message.starredBy;
      if (!starredBy.contains(userId)) {
        starredBy.add(userId);
        message = message.copyWith(starredBy: starredBy);

        return await zeytin.addData(
          box: "messages",
          tag: messageId,
          value: message.toJson(),
        );
      }

      return ZeytinResponse(isSuccess: true, message: "Already starred");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> unstarMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);

      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = RevaniMessage.fromJson(messageData.data!);

      final starredBy = message.starredBy;
      if (starredBy.contains(userId)) {
        starredBy.remove(userId);
        message = message.copyWith(starredBy: starredBy);

        return await zeytin.addData(
          box: "messages",
          tag: messageId,
          value: message.toJson(),
        );
      }

      return ZeytinResponse(isSuccess: true, message: "Not starred");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<Chat>> getChatsForUser({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final allChats = await zeytin.getBox(box: "chats");

      List<Chat> userChats = [];
      for (var item in allChats.data!.values) {
        final chat = Chat.fromJson(item.value);

        final chatData = await zeytin.getData(
          box: "chats",
          tag: chat.chatID ?? "",
        );
        if (chatData.data != null) {
          userChats.add(chat);
        }
      }

      userChats.sort((a, b) {
        final aTime = a.lastMessageTimestamp ?? DateTime(1970);
        final bTime = b.lastMessageTimestamp ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      final startIndex = offset ?? 0;
      final endIndex = limit != null
          ? (startIndex + limit).clamp(0, userChats.length)
          : userChats.length;

      if (startIndex >= userChats.length) {
        return [];
      }

      return userChats.sublist(startIndex, endIndex);
    } catch (e) {
      return [];
    }
  }

  Future<Chat?> getChat({required String chatId}) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) return null;
      return Chat.fromJson(chatData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<ZeytinResponse> updateChat({
    required String chatId,
    String? chatName,
    String? chatPhotoURL,
    Map<String, dynamic>? themeSettings,
    bool? isMuted,
    bool? isArchived,
    bool? isBlocked,
    String? disappearingMessagesTimer,
    List<String>? adminIDs,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = Chat.fromJson(chatData.data!);

      chat = chat.copyWith(
        chatName: chatName ?? chat.chatName,
        chatPhotoURL: chatPhotoURL ?? chat.chatPhotoURL,
        themeSettings: themeSettings ?? chat.themeSettings,
        isMuted: isMuted ?? chat.isMuted,
        isArchived: isArchived ?? chat.isArchived,
        isBlocked: isBlocked ?? chat.isBlocked,
        disappearingMessagesTimer:
            disappearingMessagesTimer ?? chat.disappearingMessagesTimer,
        adminIDs: adminIDs ?? chat.adminIDs,
      );

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> addParticipant({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      final chat = Chat.fromJson(chatData.data!);
      final participants = chat.participants ?? [];

      final userResponse = await _getUserResponse(userId);
      if (userResponse == null) {
        return ZeytinResponse(isSuccess: false, message: "User not found");
      }

      final alreadyParticipant = participants.any((p) => p.uid == userId);
      if (alreadyParticipant) {
        return ZeytinResponse(
          isSuccess: true,
          message: "Already a participant",
        );
      }

      final newParticipants = [...participants, userResponse];
      final updatedChat = chat.copyWith(participants: newParticipants);

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: updatedChat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> removeParticipant({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      final chat = Chat.fromJson(chatData.data!);
      final participants = chat.participants ?? [];

      final updatedParticipants = participants
          .where((p) => p.uid != userId)
          .toList();
      final updatedChat = chat.copyWith(participants: updatedParticipants);

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: updatedChat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> createSystemMessage({
    required String chatId,
    required String type,
    String? userId,
    String? userName,
    String? oldValue,
    String? value,
  }) async {
    try {
      final messageId = Uuid().v1();
      final now = DateTime.now();

      final systemMessageData = RevaniSystemMessageData(
        type: type,
        userId: userId,
        userName: userName,
        oldValue: oldValue,
        value: value,
      );

      final message = RevaniMessage(
        messageId: messageId,
        chatId: chatId,
        senderId: "system",
        text: _getSystemMessageText(type, userName, oldValue, value),
        timestamp: now,
        messageType: 'system',
        status: 'sent',
        isSystemMessage: true,
        systemMessageData: systemMessageData,
      );

      final response = await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );

      if (response.isSuccess == true) {
        await _updateChatLastMessage(chatId, message);
      }

      return response;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<RevaniMessage>> searchMessages({
    required String chatId,
    required String query,
    int? limit,
    int? offset,
  }) async {
    try {
      final allMessages = await zeytin.getBox(box: "messages");

      List<RevaniMessage> matchingMessages = [];
      for (var item in allMessages.data!.values) {
        final message = RevaniMessage.fromJson(item.value);
        if (message.chatId == chatId &&
            !message.isDeleted &&
            message.text.toLowerCase().contains(query.toLowerCase())) {
          matchingMessages.add(message);
        }
      }

      matchingMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final startIndex = offset ?? 0;
      final endIndex = limit != null
          ? (startIndex + limit).clamp(0, matchingMessages.length)
          : matchingMessages.length;

      if (startIndex >= matchingMessages.length) {
        return [];
      }

      return matchingMessages.sublist(startIndex, endIndex);
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = Chat.fromJson(chatData.data!);
      var typingUserIDs = chat.typingUserIDs ?? [];

      if (isTyping) {
        if (!typingUserIDs.contains(userId)) {
          typingUserIDs.add(userId);
        }
      } else {
        typingUserIDs.remove(userId);
      }

      chat = chat.copyWith(typingUserIDs: typingUserIDs);

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<RevaniMessage>> getStarredMessages({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final allMessages = await zeytin.getBox(box: "messages");

      List<RevaniMessage> starredMessages = [];
      for (var item in allMessages.data!.values) {
        final message = RevaniMessage.fromJson(item.value);
        if (message.starredBy.contains(userId) && !message.isDeleted) {
          starredMessages.add(message);
        }
      }

      starredMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final startIndex = offset ?? 0;
      final endIndex = limit != null
          ? (startIndex + limit).clamp(0, starredMessages.length)
          : starredMessages.length;

      if (startIndex >= starredMessages.length) {
        return [];
      }

      return starredMessages.sublist(startIndex, endIndex);
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> updateUnreadCount({
    required String chatId,
    required String userId,
    int? unreadCount,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = Chat.fromJson(chatData.data!);

      if (unreadCount != null) {
        chat = chat.copyWith(unreadCount: unreadCount);
      } else {
        final messages = await getMessages(chatId: chatId, limit: 100);
        final unread = messages.where((m) {
          return m.senderId != userId &&
              !m.statusInfo.readBy.contains(userId) &&
              !m.isDeleted;
        }).length;

        chat = chat.copyWith(unreadCount: unread);
      }

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<RevaniMessage>> getPinnedMessages({
    required String chatId,
    int? limit,
    int? offset,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) return [];

      final chat = Chat.fromJson(chatData.data!);
      final pinnedMessageIDs = chat.pinnedMessageIDs ?? [];

      List<RevaniMessage> pinnedMessages = [];
      for (var messageId in pinnedMessageIDs) {
        final messageData = await zeytin.getData(
          box: "messages",
          tag: messageId,
        );
        if (messageData.data != null) {
          final message = RevaniMessage.fromJson(messageData.data!);
          if (!message.isDeleted) {
            pinnedMessages.add(message);
          }
        }
      }

      pinnedMessages.sort((a, b) {
        final aTime = a.pinnedTimestamp ?? DateTime(1970);
        final bTime = b.pinnedTimestamp ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      final startIndex = offset ?? 0;
      final endIndex = limit != null
          ? (startIndex + limit).clamp(0, pinnedMessages.length)
          : pinnedMessages.length;

      if (startIndex >= pinnedMessages.length) {
        return [];
      }

      return pinnedMessages.sublist(startIndex, endIndex);
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> clearChatHistory({
    required String chatId,
    required String userId,
    bool deleteForEveryone = false,
  }) async {
    try {
      final messages = await getMessages(chatId: chatId, limit: 1000);

      for (var message in messages) {
        if (deleteForEveryone || message.senderId == userId) {
          await deleteMessage(
            messageId: message.messageId,
            userId: userId,
            deleteForEveryone: deleteForEveryone,
          );
        }
      }

      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) {
        var chat = Chat.fromJson(chatData.data!);
        chat = chat.copyWith(
          lastMessage: null,
          lastMessageTimestamp: null,
          lastMessageSenderID: null,
          unreadCount: 0,
        );

        await zeytin.addData(box: "chats", tag: chatId, value: chat.toJson());
      }

      return ZeytinResponse(isSuccess: true, message: "Chat history cleared");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<RevaniMessage?> getMessage({required String messageId}) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) return null;
      return RevaniMessage.fromJson(messageData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<ZeytinResponse> archiveChat({
    required String chatId,
    required bool archive,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = Chat.fromJson(chatData.data!);
      chat = chat.copyWith(isArchived: archive);

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> muteChat({
    required String chatId,
    required bool mute,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = Chat.fromJson(chatData.data!);
      chat = chat.copyWith(isMuted: mute);

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> blockChat({
    required String chatId,
    required bool block,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = Chat.fromJson(chatData.data!);
      chat = chat.copyWith(isBlocked: block);

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> processSelfDestructMessages() async {
    try {
      final allMessages = await zeytin.getBox(box: "messages");
      final now = DateTime.now();

      for (var item in allMessages.data!.values) {
        final message = RevaniMessage.fromJson(item.value);

        if (message.selfDestructTimestamp != null &&
            message.selfDestructTimestamp!.isBefore(now) &&
            !message.isDeleted) {
          await deleteMessage(
            messageId: message.messageId,
            userId: message.senderId,
            deleteForEveryone: true,
          );
        }
      }

      return ZeytinResponse(
        isSuccess: true,
        message: "Self-destruct messages processed",
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinUserResponse?> _getUserResponse(String userId) async {
    try {
      final userData = await zeytin.getData(box: "users", tag: userId);
      if (userData.data == null) return null;
      return ZeytinUserResponse.fromJson(userData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateChatLastMessage(
    String chatId,
    RevaniMessage message,
  ) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) return;

      var chat = Chat.fromJson(chatData.data!);

      chat = chat.copyWith(
        lastMessage: message.text,
        lastMessageTimestamp: message.timestamp,
        lastMessageSenderID: message.senderId,
      );

      await zeytin.addData(box: "chats", tag: chatId, value: chat.toJson());
    } catch (e) {
      ZeytinPrint.errorPrint("Error updating chat last message: $e");
    }
  }

  String _getSystemMessageText(
    String type,
    String? userName,
    String? oldValue,
    String? value,
  ) {
    switch (type) {
      case 'user_joined':
        return '$userName joined the chat';
      case 'user_left':
        return '$userName left the chat';
      case 'group_created':
        return 'Group created by $userName';
      case 'name_changed':
        return '$userName changed group name from "$oldValue" to "$value"';
      case 'photo_changed':
        return '$userName changed group photo';
      case 'admin_added':
        return '$userName is now an admin';
      case 'admin_removed':
        return '$userName is no longer an admin';
      default:
        return 'System message';
    }
  }
}

class ZeytinUserResponse {
  final String username;
  final String uid;
  final String email;
  final String emailVerified;
  final String password;
  final String role;
  final String firstName;
  final String lastName;
  final String displayName;
  final String avatarUrl;
  final String gender;
  final String dateOfBirth;
  final String biography;
  final String preferredLanguage;
  final String timezone;
  final String accountStatus;
  final String accountUpdated;
  final String accountCreation;
  final String accountType;
  final String lastLoginTimestamp;
  final String lastLoginIp;
  final String socialMedias;
  final String theme;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final String locale;
  final String posts;
  final String createdBy;
  final String updatedBy;
  final String version;
  final Map<String, dynamic> data;

  ZeytinUserResponse({
    required this.username,
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.password,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.avatarUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.biography,
    required this.preferredLanguage,
    required this.timezone,
    required this.accountStatus,
    required this.accountUpdated,
    required this.accountCreation,
    required this.accountType,
    required this.lastLoginTimestamp,
    required this.lastLoginIp,
    required this.socialMedias,
    required this.theme,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.locale,
    required this.posts,
    required this.createdBy,
    required this.updatedBy,
    required this.version,
    required this.data,
  });

  factory ZeytinUserResponse.empty() {
    return ZeytinUserResponse(
      username: '',
      uid: '',
      email: '',
      emailVerified: '',
      password: '',
      role: '',
      firstName: '',
      lastName: '',
      displayName: '',
      avatarUrl: '',
      gender: '',
      dateOfBirth: '',
      biography: '',
      preferredLanguage: '',
      timezone: '',
      accountStatus: '',
      accountUpdated: '',
      accountCreation: '',
      accountType: '',
      lastLoginTimestamp: '',
      lastLoginIp: '',
      socialMedias: '',
      theme: '',
      street: '',
      city: '',
      postalCode: '',
      country: '',
      locale: '',
      posts: '',
      createdBy: '',
      updatedBy: '',
      version: '',
      data: {},
    );
  }

  factory ZeytinUserResponse.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    return ZeytinUserResponse(
      username: s(json['username']),
      uid: s(json['uid']),
      email: s(json['email']),
      emailVerified: s(json['email_verified']),
      password: s(json['password']),
      role: s(json['role']),
      firstName: s(json['first_name']),
      lastName: s(json['last_name']),
      displayName: s(json['display_name']),
      avatarUrl: s(json['avatar_url']),
      gender: s(json['gender']),
      dateOfBirth: s(json['date_of_birth']),
      biography: s(json['biography']),
      preferredLanguage: s(json['preferred_language']),
      timezone: s(json['timezone']),
      accountStatus: s(json['account_status']),
      accountUpdated: s(json['account_updated']),
      accountCreation: s(json['account_creation']),
      accountType: s(json['account_type']),
      lastLoginTimestamp: s(json['last_login_timestamp']),
      lastLoginIp: s(json['last_login_ip']),
      socialMedias: s(json['social_medias']),
      theme: s(json['theme']),
      street: s(json['street']),
      city: s(json['city']),
      postalCode: s(json['postal_code']),
      country: s(json['country']),
      locale: s(json['locale']),
      posts: s(json['posts']),
      createdBy: s(json['created_by']),
      updatedBy: s(json['updated_by']),
      version: s(json['version']),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'uid': uid,
      'email': email,
      'email_verified': emailVerified,
      'password': password,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'biography': biography,
      'preferred_language': preferredLanguage,
      'timezone': timezone,
      'account_status': accountStatus,
      'account_updated': accountUpdated,
      'account_creation': accountCreation,
      'account_type': accountType,
      'last_login_timestamp': lastLoginTimestamp,
      'last_login_ip': lastLoginIp,
      'social_medias': socialMedias,
      'theme': theme,
      'street': street,
      'city': city,
      'postal_code': postalCode,
      'country': country,
      'locale': locale,
      'posts': posts,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'version': version,
      'data': data,
    };
  }

  ZeytinUserResponse copyWith({
    String? username,
    String? uid,
    String? email,
    String? emailVerified,
    String? password,
    String? role,
    String? firstName,
    String? lastName,
    String? displayName,
    String? avatarUrl,
    String? gender,
    String? dateOfBirth,
    String? biography,
    String? preferredLanguage,
    String? timezone,
    String? accountStatus,
    String? accountUpdated,
    String? accountCreation,
    String? accountType,
    String? lastLoginTimestamp,
    String? lastLoginIp,
    String? socialMedias,
    String? theme,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    String? locale,
    String? posts,
    String? createdBy,
    String? updatedBy,
    String? version,
    Map<String, dynamic>? data,
  }) {
    return ZeytinUserResponse(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      password: password ?? this.password,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      biography: biography ?? this.biography,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
      accountStatus: accountStatus ?? this.accountStatus,
      accountUpdated: accountUpdated ?? this.accountUpdated,
      accountCreation: accountCreation ?? this.accountCreation,
      accountType: accountType ?? this.accountType,
      lastLoginTimestamp: lastLoginTimestamp ?? this.lastLoginTimestamp,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      socialMedias: socialMedias ?? this.socialMedias,
      theme: theme ?? this.theme,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      locale: locale ?? this.locale,
      posts: posts ?? this.posts,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
      data: data != null
          ? Map<String, dynamic>.from(data)
          : Map<String, dynamic>.from(this.data),
    );
  }
}

class Chat {
  final List<ZeytinUserResponse>? participants;
  final String? chatID;
  final String? chatName;
  final String? chatPhotoURL;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final String? lastMessageSenderID;
  final int unreadCount;
  final bool isMuted;
  final String type;
  final DateTime? createdAt;
  final List<String>? adminIDs;
  final Map<String, dynamic>? themeSettings;
  final List<String>? pinnedMessageIDs;
  final bool isArchived;
  final bool isBlocked;
  final List<String>? typingUserIDs;
  final String? disappearingMessagesTimer;
  final Map<String, dynamic>? callHistorySummary;
  final List<String>? botIDs;
  final Map<String, dynamic>? moreData;

  Chat({
    this.participants,
    this.chatID,
    this.chatName,
    this.chatPhotoURL,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.lastMessageSenderID,
    this.unreadCount = 0,
    this.isMuted = false,
    this.type = "private",
    this.createdAt,
    this.adminIDs,
    this.themeSettings,
    this.pinnedMessageIDs,
    this.isArchived = false,
    this.isBlocked = false,
    this.typingUserIDs,
    this.disappearingMessagesTimer,
    this.callHistorySummary,
    this.botIDs,
    this.moreData,
  });

  Map<String, dynamic> toJson() {
    var participantList = [];
    if (participants != null) {
      for (var element in participants!) {
        participantList.add(element.toJson());
      }
    }

    return {
      "participants": participantList,
      "chatID": chatID ?? "",
      "chatName": chatName,
      "chatPhotoURL": chatPhotoURL,
      "lastMessage": lastMessage,
      "lastMessageTimestamp": lastMessageTimestamp?.toIso8601String(),
      "lastMessageSenderID": lastMessageSenderID,
      "unreadCount": unreadCount,
      "isMuted": isMuted,
      "type": type,
      "createdAt": createdAt?.toIso8601String(),
      "adminIDs": adminIDs ?? [],
      "themeSettings": themeSettings ?? {},
      "pinnedMessageIDs": pinnedMessageIDs ?? [],
      "isArchived": isArchived,
      "isBlocked": isBlocked,
      "typingUserIDs": typingUserIDs ?? [],
      "disappearingMessagesTimer": disappearingMessagesTimer,
      "callHistorySummary": callHistorySummary ?? {},
      "botIDs": botIDs ?? [],
      "moreData": moreData ?? {},
    };
  }

  Chat copyWith({
    List<ZeytinUserResponse>? participants,
    String? chatID,
    String? chatName,
    String? chatPhotoURL,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    String? lastMessageSenderID,
    int? unreadCount,
    bool? isMuted,
    String? type,
    DateTime? createdAt,
    List<String>? adminIDs,
    Map<String, dynamic>? themeSettings,
    List<String>? pinnedMessageIDs,
    bool? isArchived,
    bool? isBlocked,
    List<String>? typingUserIDs,
    String? disappearingMessagesTimer,
    Map<String, dynamic>? callHistorySummary,
    List<String>? botIDs,
    Map<String, dynamic>? moreData,
  }) {
    return Chat(
      participants: participants ?? this.participants,
      chatID: chatID ?? this.chatID,
      chatName: chatName ?? this.chatName,
      chatPhotoURL: chatPhotoURL ?? this.chatPhotoURL,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSenderID: lastMessageSenderID ?? this.lastMessageSenderID,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      adminIDs: adminIDs ?? this.adminIDs,
      themeSettings: themeSettings ?? this.themeSettings,
      pinnedMessageIDs: pinnedMessageIDs ?? this.pinnedMessageIDs,
      isArchived: isArchived ?? this.isArchived,
      isBlocked: isBlocked ?? this.isBlocked,
      typingUserIDs: typingUserIDs ?? this.typingUserIDs,
      disappearingMessagesTimer:
          disappearingMessagesTimer ?? this.disappearingMessagesTimer,
      callHistorySummary: callHistorySummary ?? this.callHistorySummary,
      botIDs: botIDs ?? this.botIDs,
      moreData: moreData ?? this.moreData,
    );
  }

  factory Chat.fromJson(Map<String, dynamic> data) {
    List<ZeytinUserResponse> participantList = [];
    if (data["participants"] != null) {
      for (var element in data["participants"]!) {
        participantList.add(ZeytinUserResponse.fromJson(element));
      }
    }

    return Chat(
      participants: participantList,
      chatID: data["chatID"] ?? "",
      chatName: data["chatName"],
      chatPhotoURL: data["chatPhotoURL"],
      lastMessage: data["lastMessage"],
      lastMessageTimestamp: data["lastMessageTimestamp"] != null
          ? DateTime.tryParse(data["lastMessageTimestamp"])
          : null,
      lastMessageSenderID: data["lastMessageSenderID"],
      unreadCount: data["unreadCount"] ?? 0,
      isMuted: data["isMuted"] ?? false,
      type: data["type"] ?? "private",
      createdAt: data["createdAt"] != null
          ? DateTime.tryParse(data["createdAt"])
          : null,
      adminIDs: data["adminIDs"] != null
          ? List<String>.from(data["adminIDs"])
          : null,
      themeSettings: data["themeSettings"] != null
          ? Map<String, dynamic>.from(data["themeSettings"])
          : null,
      pinnedMessageIDs: data["pinnedMessageIDs"] != null
          ? List<String>.from(data["pinnedMessageIDs"])
          : null,
      isArchived: data["isArchived"] ?? false,
      isBlocked: data["isBlocked"] ?? false,
      typingUserIDs: data["typingUserIDs"] != null
          ? List<String>.from(data["typingUserIDs"])
          : null,
      disappearingMessagesTimer: data["disappearingMessagesTimer"],
      callHistorySummary: data["callHistorySummary"] != null
          ? Map<String, dynamic>.from(data["callHistorySummary"])
          : null,
      botIDs: data["botIDs"] != null ? List<String>.from(data["botIDs"]) : null,
      moreData: data["moreData"] != null
          ? Map<String, dynamic>.from(data["moreData"])
          : null,
    );
  }
}

class RevaniMediaDimensions {
  final int width;
  final int height;

  RevaniMediaDimensions({required this.width, required this.height});

  Map<String, dynamic> toJson() => {'width': width, 'height': height};
  factory RevaniMediaDimensions.fromJson(Map<String, dynamic> json) {
    return RevaniMediaDimensions(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }
}

class RevaniMedia {
  final String url;
  final String? thumbnailUrl;
  final int? fileSize;
  final String fileName;
  final String mimeType;
  final Duration? duration;
  final RevaniMediaDimensions? dimensions;

  RevaniMedia({
    required this.url,
    this.thumbnailUrl,
    this.fileSize,
    required this.fileName,
    required this.mimeType,
    this.duration,
    this.dimensions,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'fileSize': fileSize,
      'fileName': fileName,
      'mimeType': mimeType,
      'duration': duration?.inMilliseconds,
      'dimensions': dimensions?.toJson(),
    };
  }

  factory RevaniMedia.fromJson(Map<String, dynamic> json) {
    return RevaniMedia(
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      fileSize: json['fileSize'],
      fileName: json['fileName'] ?? '',
      mimeType: json['mimeType'] ?? '',
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      dimensions: json['dimensions'] != null
          ? RevaniMediaDimensions.fromJson(json['dimensions'])
          : null,
    );
  }
}

class RevaniLocation {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;

  RevaniLocation({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'address': address,
    };
  }

  factory RevaniLocation.fromJson(Map<String, dynamic> json) {
    return RevaniLocation(
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      name: json['name'],
      address: json['address'],
    );
  }
}

class RevaniContact {
  final String name;
  final String? phoneNumber;
  final String? email;

  RevaniContact({required this.name, this.phoneNumber, this.email});

  Map<String, dynamic> toJson() {
    return {'name': name, 'phoneNumber': phoneNumber, 'email': email};
  }

  factory RevaniContact.fromJson(Map<String, dynamic> json) {
    return RevaniContact(
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
    );
  }
}

class RevaniReaction {
  final String emoji;
  final String userId;
  final DateTime timestamp;

  RevaniReaction({
    required this.emoji,
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RevaniReaction.fromJson(Map<String, dynamic> json) {
    return RevaniReaction(
      emoji: json['emoji'] ?? '',
      userId: json['userId'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class RevaniMessageReactions {
  final Map<String, List<RevaniReaction>> reactions;

  RevaniMessageReactions({Map<String, List<RevaniReaction>>? reactions})
    : reactions = reactions ?? {};

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    reactions.forEach((emoji, reactionList) {
      result[emoji] = reactionList.map((r) => r.toJson()).toList();
    });
    return result;
  }

  factory RevaniMessageReactions.fromJson(Map<String, dynamic> json) {
    final Map<String, List<RevaniReaction>> reactionsMap = {};

    json.forEach((emoji, reactionData) {
      if (reactionData is List) {
        reactionsMap[emoji] = reactionData
            .map<RevaniReaction>((item) => RevaniReaction.fromJson(item))
            .toList();
      }
    });

    return RevaniMessageReactions(reactions: reactionsMap);
  }
}

class RevaniMessageStatusInfo {
  final List<String> deliveredTo;
  final List<String> readBy;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  RevaniMessageStatusInfo({
    List<String>? deliveredTo,
    List<String>? readBy,
    this.deliveredAt,
    this.readAt,
  }) : deliveredTo = deliveredTo ?? [],
       readBy = readBy ?? [];

  Map<String, dynamic> toJson() {
    return {
      'deliveredTo': deliveredTo,
      'readBy': readBy,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  RevaniMessageStatusInfo copyWith({
    List<String>? deliveredTo,
    List<String>? readBy,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return RevaniMessageStatusInfo(
      deliveredTo: deliveredTo ?? this.deliveredTo,
      readBy: readBy ?? this.readBy,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory RevaniMessageStatusInfo.fromJson(Map<String, dynamic> json) {
    return RevaniMessageStatusInfo(
      deliveredTo: json['deliveredTo'] != null
          ? List<String>.from(json['deliveredTo'])
          : [],
      readBy: json['readBy'] != null ? List<String>.from(json['readBy']) : [],
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
    );
  }
}

class RevaniSystemMessageData {
  final String type;
  final String? userId;
  final String? userName;
  final String? oldValue;
  final String? value;

  RevaniSystemMessageData({
    required this.type,
    this.userId,
    this.userName,
    this.oldValue,
    this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'userId': userId,
      'userName': userName,
      'oldValue': oldValue,
      'value': value,
    };
  }

  factory RevaniSystemMessageData.fromJson(Map<String, dynamic> json) {
    return RevaniSystemMessageData(
      type: json['type'] ?? '',
      userId: json['userId'],
      userName: json['userName'],
      oldValue: json['oldValue'],
      value: json['value'],
    );
  }
}

class RevaniInteractiveButton {
  final String id;
  final String text;
  final String type;
  final String? payload;

  RevaniInteractiveButton({
    required this.id,
    required this.text,
    required this.type,
    this.payload,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'type': type, 'payload': payload};
  }

  factory RevaniInteractiveButton.fromJson(Map<String, dynamic> json) {
    return RevaniInteractiveButton(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? '',
      payload: json['payload'],
    );
  }
}

class RevaniMessage {
  final String messageId;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String messageType;
  final String status;
  final bool isEdited;
  final DateTime? editedTimestamp;
  final bool isDeleted;
  final bool deletedForEveryone;
  final bool isForwarded;
  final String? forwardedFrom;
  final RevaniMedia? media;
  final RevaniLocation? location;
  final RevaniContact? contact;
  final String? replyToMessageId;
  final List<String> mentions;
  final RevaniMessageReactions reactions;
  final RevaniMessageStatusInfo statusInfo;
  final List<String> starredBy;
  final bool isPinned;
  final String? pinnedBy;
  final DateTime? pinnedTimestamp;
  final bool isSystemMessage;
  final RevaniSystemMessageData? systemMessageData;
  final bool encrypted;
  final String? encryptionKey;
  final Duration? selfDestructTimer;
  final DateTime? selfDestructTimestamp;
  final String? localId;
  final String? serverId;
  final int sequenceNumber;
  final String? botId;
  final List<RevaniInteractiveButton> interactiveButtons;
  final Map<String, dynamic> metadata;

  RevaniMessage({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.messageType = 'text',
    this.status = 'sent',
    this.isEdited = false,
    this.editedTimestamp,
    this.isDeleted = false,
    this.deletedForEveryone = false,
    this.isForwarded = false,
    this.forwardedFrom,
    this.media,
    this.location,
    this.contact,
    this.replyToMessageId,
    List<String>? mentions,
    RevaniMessageReactions? reactions,
    RevaniMessageStatusInfo? statusInfo,
    List<String>? starredBy,
    this.isPinned = false,
    this.pinnedBy,
    this.pinnedTimestamp,
    this.isSystemMessage = false,
    this.systemMessageData,
    this.encrypted = false,
    this.encryptionKey,
    this.selfDestructTimer,
    this.selfDestructTimestamp,
    this.localId,
    this.serverId,
    this.sequenceNumber = 0,
    this.botId,
    List<RevaniInteractiveButton>? interactiveButtons,
    Map<String, dynamic>? metadata,
  }) : mentions = mentions ?? [],
       reactions = reactions ?? RevaniMessageReactions(),
       statusInfo = statusInfo ?? RevaniMessageStatusInfo(),
       starredBy = starredBy ?? [],
       interactiveButtons = interactiveButtons ?? [],
       metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType,
      'status': status,
      'isEdited': isEdited,
      'editedTimestamp': editedTimestamp?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedForEveryone': deletedForEveryone,
      'isForwarded': isForwarded,
      'forwardedFrom': forwardedFrom,
      'media': media?.toJson(),
      'location': location?.toJson(),
      'contact': contact?.toJson(),
      'replyToMessageId': replyToMessageId,
      'mentions': mentions,
      'reactions': reactions.toJson(),
      'statusInfo': statusInfo.toJson(),
      'starredBy': starredBy,
      'isPinned': isPinned,
      'pinnedBy': pinnedBy,
      'pinnedTimestamp': pinnedTimestamp?.toIso8601String(),
      'isSystemMessage': isSystemMessage,
      'systemMessageData': systemMessageData?.toJson(),
      'encrypted': encrypted,
      'encryptionKey': encryptionKey,
      'selfDestructTimer': selfDestructTimer?.inSeconds,
      'selfDestructTimestamp': selfDestructTimestamp?.toIso8601String(),
      'localId': localId,
      'serverId': serverId,
      'sequenceNumber': sequenceNumber,
      'botId': botId,
      'interactiveButtons': interactiveButtons.map((b) => b.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory RevaniMessage.fromJson(Map<String, dynamic> json) {
    return RevaniMessage(
      messageId: json['messageId'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      messageType: json['messageType'] ?? 'text',
      status: json['status'] ?? 'sent',
      isEdited: json['isEdited'] ?? false,
      editedTimestamp: json['editedTimestamp'] != null
          ? DateTime.tryParse(json['editedTimestamp'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      deletedForEveryone: json['deletedForEveryone'] ?? false,
      isForwarded: json['isForwarded'] ?? false,
      forwardedFrom: json['forwardedFrom'],
      media: json['media'] != null ? RevaniMedia.fromJson(json['media']) : null,
      location: json['location'] != null
          ? RevaniLocation.fromJson(json['location'])
          : null,
      contact: json['contact'] != null
          ? RevaniContact.fromJson(json['contact'])
          : null,
      replyToMessageId: json['replyToMessageId'],
      mentions: json['mentions'] != null
          ? List<String>.from(json['mentions'])
          : [],
      reactions: json['reactions'] != null
          ? RevaniMessageReactions.fromJson(json['reactions'])
          : RevaniMessageReactions(),
      statusInfo: json['statusInfo'] != null
          ? RevaniMessageStatusInfo.fromJson(json['statusInfo'])
          : RevaniMessageStatusInfo(),
      starredBy: json['starredBy'] != null
          ? List<String>.from(json['starredBy'])
          : [],
      isPinned: json['isPinned'] ?? false,
      pinnedBy: json['pinnedBy'],
      pinnedTimestamp: json['pinnedTimestamp'] != null
          ? DateTime.tryParse(json['pinnedTimestamp'])
          : null,
      isSystemMessage: json['isSystemMessage'] ?? false,
      systemMessageData: json['systemMessageData'] != null
          ? RevaniSystemMessageData.fromJson(json['systemMessageData'])
          : null,
      encrypted: json['encrypted'] ?? false,
      encryptionKey: json['encryptionKey'],
      selfDestructTimer: json['selfDestructTimer'] != null
          ? Duration(seconds: json['selfDestructTimer'])
          : null,
      selfDestructTimestamp: json['selfDestructTimestamp'] != null
          ? DateTime.tryParse(json['selfDestructTimestamp'])
          : null,
      localId: json['localId'],
      serverId: json['serverId'],
      sequenceNumber: json['sequenceNumber'] ?? 0,
      botId: json['botId'],
      interactiveButtons: json['interactiveButtons'] != null
          ? (json['interactiveButtons'] as List)
                .map((item) => RevaniInteractiveButton.fromJson(item))
                .toList()
          : [],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
    );
  }

  RevaniMessage copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    String? messageType,
    String? status,
    bool? isEdited,
    DateTime? editedTimestamp,
    bool? isDeleted,
    bool? deletedForEveryone,
    bool? isForwarded,
    String? forwardedFrom,
    RevaniMedia? media,
    RevaniLocation? location,
    RevaniContact? contact,
    String? replyToMessageId,
    List<String>? mentions,
    RevaniMessageReactions? reactions,
    RevaniMessageStatusInfo? statusInfo,
    List<String>? starredBy,
    bool? isPinned,
    String? pinnedBy,
    DateTime? pinnedTimestamp,
    bool? isSystemMessage,
    RevaniSystemMessageData? systemMessageData,
    bool? encrypted,
    String? encryptionKey,
    Duration? selfDestructTimer,
    DateTime? selfDestructTimestamp,
    String? localId,
    String? serverId,
    int? sequenceNumber,
    String? botId,
    List<RevaniInteractiveButton>? interactiveButtons,
    Map<String, dynamic>? metadata,
  }) {
    return RevaniMessage(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      editedTimestamp: editedTimestamp ?? this.editedTimestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      media: media ?? this.media,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      mentions: mentions ?? this.mentions,
      reactions: reactions ?? this.reactions,
      statusInfo: statusInfo ?? this.statusInfo,
      starredBy: starredBy ?? this.starredBy,
      isPinned: isPinned ?? this.isPinned,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      pinnedTimestamp: pinnedTimestamp ?? this.pinnedTimestamp,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      systemMessageData: systemMessageData ?? this.systemMessageData,
      encrypted: encrypted ?? this.encrypted,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      selfDestructTimer: selfDestructTimer ?? this.selfDestructTimer,
      selfDestructTimestamp:
          selfDestructTimestamp ?? this.selfDestructTimestamp,
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      botId: botId ?? this.botId,
      interactiveButtons: interactiveButtons ?? this.interactiveButtons,
      metadata: metadata ?? this.metadata,
    );
  }
}
