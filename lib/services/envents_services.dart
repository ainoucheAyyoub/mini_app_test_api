import 'package:dio/dio.dart';
import 'package:mini_projet/neworking_api/api_endpoint.dart';
import 'package:mini_projet/neworking_api/dio_helper.dart';
import 'package:mini_projet/modules/events.dart';

class EventsService {
  Future<List<Events>?> getEvents() async {
    try {
      final Response? response = await DioHelper.getRequest(
        endPoint: ApiEndpoints.searchEndpoint,
        query:
            {}, // You can add any parameters you want to send with the request here
      );

      if (response != null && response.statusCode == 200) {
        // The data from the API is usually in the form of a list
        List<dynamic> data = response.data;
        // Convert each item in the list to an Events object
        List<Events> eventsList =
            data.map((json) => Events.fromJson(json)).toList();
        return eventsList;
      } else {
        // If the response is empty or there is an issue with the status code
        print('Error fetching events: Status Code ${response?.statusCode}');
        return null; // Return an empty list in case of an error
      }
    } catch (error) {
      // If there is an error during the connection (e.g., network issue)
      print('Error connecting to the API: $error');
      return null; // Return an empty list in case of an error
    }
  }
}
