import 'package:example/geo_fence_page.dart';
import 'package:example/loaction_page.dart';
import 'package:fl_amap/fl_amap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      navigatorKey: GlobalWayUI().navigatorKey,
      scaffoldMessengerKey: GlobalWayUI().scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'FlAMap',
      home: Scaffold(
          appBar: AppBar(title: const Text('高德地图')), body: const App())));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool isInit = false;

  void setKey() async {
    final bool key = await setAMapKey(
        iosKey: 'e0e98395277890e48caa0c4bed423ead',
        androidKey: '77418e726d0eefc0ac79a8619b5f4d97',
        isAgree: true,
        isContains: true,
        isShow: true);
    debugPrint('高德地图ApiKey设置$key');
    if (key) {
      isInit = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Universal(
        width: double.infinity,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isInit) ElevatedText(onPressed: setKey, text: '设置key'),
          if (isInit)
            ElevatedText(
                onPressed: () => push(const AMapLocationPage()),
                text: '高德定位功能'),
          30.heightBox,
          if (isInit)
            ElevatedText(
                onPressed: () => push(const AMapGeoFencePage()),
                text: '高德地理围栏功能'),
        ]);
  }
}

class ElevatedText extends StatelessWidget {
  const ElevatedText({super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: Text(text));
}

Future<bool> getPermission(Permission permission) async {
  final PermissionStatus status = await permission.request();
  if (!status.isGranted) {
    await openAppSettings();
    return await permission.request().isGranted;
  }
  return status.isGranted;
}
