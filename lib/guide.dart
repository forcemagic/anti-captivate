import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';

typedef void StatusCallback(String state, {bool showBig});
StatusCallback callback;

const String currentPassword = "M1HCS4MG";
enum NetworkStatus { online, stripped, captive, offline }

/// Utility function for logging network traffic
logNetwork(http.Response resp) {
  callback("[HTTP] ${resp.request.method} ${resp.request.url} -> ${resp.statusCode}");
}

/// Detect network status
Future<NetworkStatus> doWeHaveNetwork() async {
  try {
    callback("Running connectivity test (contacting connectivitycheck.gstatic.com)...");
    http.Response plain = await http.get('http://connectivitycheck.gstatic.com/generate_204');
    logNetwork(plain);
    if (plain.statusCode == 204) {
      callback("Running encrypted connectivity test (contacting httpbin.org)...");
      http.Response encrypted = await http.get('https://httpbin.org/status/204');
      logNetwork(encrypted);
      if (encrypted.statusCode == 204) return NetworkStatus.online;
      else return NetworkStatus.stripped;
    } else return NetworkStatus.captive;
  } catch (e) {
    return NetworkStatus.offline;
  }
}

/// Name's misleading, don't worry. This is *the* login function.
Future<void> resolveCaptivePortal() async {
  callback("Loggin in (cross your fingers 🤞)...");
  try {
    // TODO: Assert redirection (?) and check that we're actually on the right wifi
    // Main login request
    http.Response logResp = await http.post(
        'http://suliwifi-1.wificloud.ahrt.hu/login.html?redirect=redirect',
        body: 'username=diakhalo'
            '&password=$currentPassword'
            '&err_flag='  // I have no idea what these guys do, I'll just leave 'em here
            '&buttonClicked=4'
            '&err_msg='
            '&info_flag='
            '&info_msg='
            '&redirect_url=http%3A%2F%2Fkifu.gov.hu%2F',
    );
    logNetwork(logResp);

    if (logResp.statusCode == 200) {
      callback("Login successful! ✔ Connection test in a sec...");
      await Future.delayed(Duration(seconds: 1));
      if (await doWeHaveNetwork() == NetworkStatus.online)
        callback("We did it!! 🥳\nYou should have Internet now.");
      else throw Exception("Sorry, I was not able to properly log in.");
    } else throw Exception("Logon failed (invalid credentials?)");
  } catch (e) {
    callback("Something horrible happened! 😔\n($e)");
  }
}

/// This is the main entry function (called by the event listener)
Future<void> actualEntry(Connectivity con) async {
  callback("Welcome to AntiCaptivate 0.4.1! 👋");
  await Future.delayed(Duration(seconds: 1));

  // Check for network
  NetworkStatus ns = await doWeHaveNetwork();
  if (ns == NetworkStatus.online) {
    callback("Nothing to do! Network seems fine. 🎉");
  } else if (ns == NetworkStatus.captive) {
    callback("Captive portal detected, trying to login...");
    await Future.delayed(Duration(seconds: 1));
    await resolveCaptivePortal();
  } else {
    callback("You don't seem to have Internet. 😔");
  }
}

/// This function is responsible for scheduling the network change event listener
Future<void> entry(s(String s)) async {
  // Globalize callback
  callback = s;

  // Instantiate Connectivity
  Connectivity con = Connectivity();

  // Register connectivity change listener
  con.onConnectivityChanged.listen((ConnectivityResult evt) {
      callback("listener: Event received, executing callback.", showBig: false);
      actualEntry(con);
  });
  callback("listener: Registered!");
}
