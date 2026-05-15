import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poultary/utils/utils.dart';


class AIServer {


  static Future<String?> askAI(Map<String, dynamic> data) async {

    try {

      final response = await http.post(

        Uri.parse(
          "https://photogallerytv.com/Api/ai_ask.php",
        ),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {

        final json = jsonDecode(response.body);

        if (json['success'] == true) {

          Utils.ai_credits =
          json['remaining_credits'];

          return json['response'];
        }else{
          String message = json['message'];
          Utils.showToast(message);
        }
      }else{
        Utils.showToast("Unable to get a response");
      }

      return null;

    } catch (e) {

      print(e);

      return null;
    }
  }

  static Future<String?> askHealthAI(Map<String, dynamic> data) async {

    try {

      final response = await http.post(

        Uri.parse(
          "https://photogallerytv.com/Api/ai_ask_health.php",
        ),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {

        final json = jsonDecode(response.body);

        if (json['success'] == true) {

          Utils.ai_credits =
          json['remaining_credits'];

          return json['response'];
        }else{
          String message = json['message'];
          Utils.showToast(message);
          return null;
        }
      }else{
        Utils.showToast("Unable to get a response");
        return null;
      }

      return null;

    } catch (e) {

      print(e);

      return null;
    }
  }

  static Future<String?> askFinanceAI(Map<String, dynamic> data) async {

    try {

      final response = await http.post(

        Uri.parse(
          "https://photogallerytv.com/Api/ai_ask_financial.php",
        ),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {

        final json = jsonDecode(response.body);

        if (json['success'] == true) {

          Utils.ai_credits =
          json['remaining_credits'];

          return json['response'];
        }else{
          String message = json['message'];
          Utils.showToast(message);
          return null;
        }
      }else{
        Utils.showToast("Unable to get a response");
        return null;
      }

      return null;

    } catch (e) {

      print(e);

      return null;
    }
  }
}