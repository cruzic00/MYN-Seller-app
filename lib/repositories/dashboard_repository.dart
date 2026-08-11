import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/dashboard_summary_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

class DashboardRepository {
  Future<DashboardSummaryResponse> getDashboardSummaryResponse() async {
    var url =
        "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/dashboard-summary/${user_id.$}";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        print("URL: $url");
        print("Response Body: ${response.body}");
        return dashboardSummaryResponseFromJson(response.body);
      } else {
        throw Exception('Failed to load dashboard summary: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow; // Rethrow the caught exception
    }
  }
}
