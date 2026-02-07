import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/routes/token.dart';
import 'package:zeytin/tools/tokener.dart';

void crudRoutes(Zeytin zeytin, Router router) {
  router.post('/data/add', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null ||
        dataDecrypted["tag"] == null ||
        dataDecrypted["value"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box, tag and value parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      if (dataDecrypted["value"] is Map) {
        await zeytin.put(
          truckId: truck,
          boxId: dataDecrypted["box"],
          tag: dataDecrypted["tag"],
          value: dataDecrypted["value"],
        );
        return Response.ok(
          jsonEncode(
            ZeytinResponse(isSuccess: true, message: "Oki doki!").toMap(),
          ),
        );
      } else {
        return Response.badRequest(
          body: jsonEncode(
            ZeytinResponse(
              isSuccess: false,
              message: "Opps...",
              error:
                  "The Value parameter must be of type Map<String, dynamic>.",
            ).toMap(),
          ),
        );
      }
    }
  });

  router.post('/data/get', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null || dataDecrypted["tag"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box and tag parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      var getData = await zeytin.get(
        truckId: truck,
        boxId: dataDecrypted["box"],
        tag: dataDecrypted["tag"],
      );
      if (getData == null) {
        return Response.badRequest(
          body: jsonEncode(
            ZeytinResponse(
              isSuccess: false,
              message: "Opps...",
              error: "This box does not contain any such data.",
            ).toMap(),
          ),
        );
      }
      final encryptedData = ZeytinTokener(password).encryptMap(getData);
      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Oki doki!",
          "data": encryptedData,
        }),
      );
    }
  });

  router.post('/data/delete', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null || dataDecrypted["tag"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box and tag parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      await zeytin.delete(
        truckId: truck,
        boxId: dataDecrypted["box"],
        tag: dataDecrypted["tag"],
      );
      return Response.ok(
        jsonEncode(
          ZeytinResponse(isSuccess: true, message: "Oki doki!").toMap(),
        ),
      );
    }
  });

  router.post('/data/deleteBox', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box parameter is mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      await zeytin.deleteBox(truckId: truck, boxId: dataDecrypted["box"]);
      return Response.ok(
        jsonEncode(
          ZeytinResponse(isSuccess: true, message: "Oki doki!").toMap(),
        ),
      );
    }
  });

  router.post('/data/addBatch', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null || dataDecrypted["entries"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box and entries parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      if (dataDecrypted["entries"] is Map) {
        Map<String, Map<String, dynamic>> entries = {};
        (dataDecrypted["entries"] as Map).forEach((key, value) {
          if (value is Map<String, dynamic>) {
            entries[key.toString()] = value;
          }
        });

        await zeytin.putBatch(
          truckId: truck,
          boxId: dataDecrypted["box"],
          entries: entries,
        );
        return Response.ok(
          jsonEncode(
            ZeytinResponse(isSuccess: true, message: "Oki doki!").toMap(),
          ),
        );
      } else {
        return Response.badRequest(
          body: jsonEncode(
            ZeytinResponse(
              isSuccess: false,
              message: "Opps...",
              error:
                  "The Entries parameter must be of type Map<String, Map<String, dynamic>>.",
            ).toMap(),
          ),
        );
      }
    }
  });

  router.post('/data/getBox', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box parameter is mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      var boxData = await zeytin.getBox(
        truckId: truck,
        boxId: dataDecrypted["box"],
      );
      final encryptedData = ZeytinTokener(password).encryptMap(boxData);
      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Oki doki!",
          "data": encryptedData,
        }),
      );
    }
  });

  router.post('/data/existsBox', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box parameter is mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      bool exists = await zeytin.existsBox(
        truckId: truck,
        boxId: dataDecrypted["box"],
      );
      final encryptedData = ZeytinTokener(
        password,
      ).encryptMap({"exists": exists});
      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Oki doki!",
          "data": encryptedData,
        }),
      );
    }
  });

  router.post('/data/existsTag', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null || dataDecrypted["tag"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box and tag parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      bool exists = await zeytin.existsTag(
        truckId: truck,
        boxId: dataDecrypted["box"],
        tag: dataDecrypted["tag"],
      );
      final encryptedData = ZeytinTokener(
        password,
      ).encryptMap({"exists": exists});
      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Oki doki!",
          "data": encryptedData,
        }),
      );
    }
  });

  router.post('/data/contains', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null || dataDecrypted["tag"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box and tag parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      bool result = await zeytin.contains(
        truck,
        dataDecrypted["box"],
        dataDecrypted["tag"],
      );
      final encryptedData = ZeytinTokener(
        password,
      ).encryptMap({"contains": result});
      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Oki doki!",
          "data": encryptedData,
        }),
      );
    }
  });

  router.post('/data/search', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null ||
        dataDecrypted["field"] == null ||
        dataDecrypted["prefix"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box, field and prefix parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      var results = await zeytin.search(
        truck,
        dataDecrypted["box"],
        dataDecrypted["field"],
        dataDecrypted["prefix"],
      );
      final encryptedData = ZeytinTokener(
        password,
      ).encryptMap({"results": results});
      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Oki doki!",
          "data": encryptedData,
        }),
      );
    }
  });

  router.post('/data/filter', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];
    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Token and data parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    var tokenData = getTokenData(token);
    if (tokenData == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "The token manager gave an error. Please verify the token's validity.",
          ).toMap(),
        ),
      );
    }
    String truck = tokenData["truck"];
    String password = tokenData["password"];
    var dataDecrypted = ZeytinTokener(password).decryptMap(data);
    if (dataDecrypted["box"] == null ||
        dataDecrypted["field"] == null ||
        dataDecrypted["value"] == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error:
                "Box, field and value parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    } else {
      var results = await zeytin.filter(
        truck,
        dataDecrypted["box"],
        (map) => map[dataDecrypted["field"]] == dataDecrypted["value"],
      );
      final encryptedData = ZeytinTokener(
        password,
      ).encryptMap({"results": results});
      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Oki doki!",
          "data": encryptedData,
        }),
      );
    }
  });
}
