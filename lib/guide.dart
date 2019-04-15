import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';

typedef void StatusCallback(String state);
StatusCallback callback;

const String currentPassword = "TSL4NYNS";

enum NetworkStatus { online, stripped, captive, offline }

Future<NetworkStatus> doWeHaveNetwork() async {
  try {
    callback("Running connectivity test (contacting connectivitycheck.gstatic.com)...");
    http.Response plain = await http.get('http://connectivitycheck.gstatic.com/generate_204');
    callback("Running connectivity test (contacting captive.apple.com)...");
    http.Response plainApple = await http.get('http://captive.apple.com');
    if (plain.statusCode == 204 && plainApple.statusCode == 200) {
      callback("Running encrypted connectivity test (contacting httpbin.org)...");
      http.Response encrypted = await http.get('https://httpbin.org/status/204');
      if (encrypted.statusCode == 204) return NetworkStatus.online;
      else return NetworkStatus.stripped;
    } else return NetworkStatus.captive;
  } catch (e) {
    return NetworkStatus.offline;
  }
}

Future<void> resolveCaptivePortal() async {
  callback("Following redirect to captive portal (using captive.apple.com)...");
  try {
    http.Response redir = await http.get('http://captive.apple.com');
    if (redir.isRedirect) {
      callback("Captive portal is at ${redir.headers['location']}");

      http.Response logResp;
      try {
        callback("We were redirected! Trying to be clever...");
        String targetSite = RegExp('action\=[\"\'](.+)[\"\']').firstMatch(
            redir.body).group(1);
        callback("Almost there, trying to be cleverer...");
        logResp = await http.post(
            targetSite, body: 'username=diakhalo&password=$currentPassword');
      } catch (e) {
        callback("I wanted to be clever... 😅\nNever mind. Trying backup solution...");
        logResp = await http.post('http://suliwifi-1.wificloud.ahrt.hu/login.html?redirect=redirect',
            body: 'username=diakhalo&password=$currentPassword&err_flag=&buttonClicked=4&err_msg=&info_flag=&info_msg=&redirect_url=http%3A%2F%2Fkifu.gov.hu%2F');
      }
      if (logResp.statusCode == 200) {
        callback("Login successful! ✔ Connection test in 2 sec...");
        await Future.delayed(Duration(seconds: 2));
        if (await doWeHaveNetwork() == NetworkStatus.online) callback("We did it!! 🥳\nYou should have Internet now.");
        else throw Exception("Sorry, I was not able to properly log in.");
      } else throw Exception("Logon failed 😔 (invalid credentials?)\n(Got ${logResp.statusCode} instead of 200)");
    } else throw Exception('Following captive redirect failed');
  } catch (e) {
    callback("Something horrible happened! 😔\n($e)");
  }
}

Future<void> actualEntry(Connectivity con) async {
  callback("AntiCaptivate v1.0 welcomes you! 👋\nStand by for awesomeness...");
  await Future.delayed(Duration(seconds: 2));

  // Check for network
  NetworkStatus ns = await doWeHaveNetwork();
  if (ns == NetworkStatus.online) {
    callback("Nothing to do! Network seems fine. 🎉");
  } else if (ns == NetworkStatus.captive) {
    callback("Your Internet connection is limited by something. Let's fix that!");
    await Future.delayed(Duration(seconds: 2));
    await resolveCaptivePortal();
  } else {
    callback("You don't seem to have Internet. 😔");
  }
}

Future<void> entry(s(String s)) async {
  // Globalize callback
  callback = s;

  // Instantiate Connectivity
  Connectivity con = Connectivity();

  // Register connectivity change listener
  con.onConnectivityChanged.listen((ConnectivityResult evt) {
      print("listener: Received event, moving on...");
      actualEntry(con);
  });
  callback("listener: Registered!");

  // Call actual entry point
//  actualEntry(con);
}