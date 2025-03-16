//import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:mini_projet/neworking_api/api_endpoint.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioHelper {
  static Dio? dio;

  static initDio() {
    dio ??= Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        receiveDataWhenStatusError: true,
      ),
    );

    dio!.interceptors.add(PrettyDioLogger());
  }

  static Future<Response?> getRequest({
    required String endPoint,
    Map<String, dynamic>? query,
  }) async {
    try {
      print(
        'DioHelper: Sending GET request to ${ApiEndpoints.baseUrl}$endPoint with query: $query',
      ); //   log the request
      Response response = await dio!.get(endPoint, queryParameters: query);
      print(
        'DioHelper: Received response with status code: ${response.statusCode}',
      ); //   log the response
      return response;
    } catch (e) {
      print('DioHelper: Error during GET request: $e'); //    log the error
      return null;
    }
  }

  /* static postRequest({
    required String endPoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      Response response = await dio!.post(endPoint, data: data);

      return response;
    } catch (e) {
      log(e.toString());
    }
  }*/
}
