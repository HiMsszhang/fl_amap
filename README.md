高德地图定位flutter组件。

目前实现获取定位和监听定位功能。

1、申请一个key
http://lbs.amap.com/api/ios-sdk/guide/create-project/get-key

直接在dart文件中设置key

# ios

1. 在info.plist中增加:
```
<key>NSLocationWhenInUseUsageDescription</key>
<string>要用定位</string>
```
2. iOS 9及以上版本使用后台定位功能, 需要保证"Background Modes"中的"Location updates"处于选中状态

3.使用地理围栏

iOS14及以上版本使用地理围栏功能，需要在plist中配置NSLocationTemporaryUsageDescriptionDictionary字典描述，
且添加自定义Key描述地理围栏的使用场景，此描述会在申请临时精确定位权限的弹窗中展示。
该回调触发条件：拥有定位权限，但是没有获得精确定位权限的情况下，会触发该回调。此方法实现调用申请临时精确定位权限API即可；

** 需要注意，在iOS9及之后版本的系统中，如果您希望程序在后台持续检测围栏触发行为，需要保证manager的 allowsBackgroundLocationUpdates 为 YES，
设置为YES的时候必须保证 Background Modes 中的 Location updates 处于选中状态，否则会抛出异常。

## 开始使用
## 高德定位功能
1.设置key
```dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool key = await setAMapKey(
      iosKey: 'ios key',
      androidKey: 'android key');

  if (key != null && key) print('高德地图ApiKey设置成功');

  runApp(MaterialApp(
      debugShowCheckedModeBanner: false, title: 'FlAMap', home: Home()));
}

```

2.初始化定位参数
```dart

  Future<void> initAMapLocation() async {
    /// 获取权限
    if (getPermissions) return;

    /// 初始化AMap
    final bool data = await initAMapLocation(AMapLocationOption());
    if (data != null && data) {
      show('初始化成功');
    }
  }

```

3.单次获取定位
```dart
  Future<void> getAMapLocation() async {
     /// 务必先初始化 并获取权限
    if (getPermissions) return;
    AMapLocation location =  await getAMapLocation(true);
  }

```

4.开启定位变化监听
```dart

  Future<void> startAMapLocationChange() async {
     /// 务必先初始化 并获取权限
    if (getPermissions) return;
    final bool data =
        await startAMapLocationChange(onLocationChange: (AMapLocation location) {
      locationState.value = location;
      text.value = '位置更新$i次';
    });
   print((data == null || !data) ? '开启成功' : '开启失败');
  }

```
5.关闭定位变化监听
```dart
  void stop(){
     stopAMapLocation();
  }
```

6.关闭定位系统

```dart
  void dispose() {
    super.dispose();
    disposeAMapLocation();
  }
```

## 高德地理围栏功能

1.初始化地理围栏
```dart

  Future<void> get initGeoFence async {
    final bool data = await initAMapGeoFence(GeoFenceActivateAction.stayed);
    if (data) {
      isInitGeoFence = true;
      show('初始化地理围栏:$data');
    }
  }

```
2.关闭围栏系统

```dart
  void dispose() {
    super.dispose();
    disposeAMapGeoFence();
  }
```

3.根据POI添加围栏
```dart
  Future<void> fun() async {
  final AMapPoiModel model = AMapPoiModel(
                              keyword: '首开广场',
                              poiType: '写字楼',
                              city: '北京',
                              size: 1,
                              customId: '000FATE23（考勤打卡）');
  final bool state = await addAMapGeoFenceWithPOI(model);
  }
```

4.根据坐标关键字添加围栏
```dart
  Future<void> fun() async {
  final LatLong latLong = LatLong(39.933921, 116.372927);
                          final AMapLatLongModel model = AMapLatLongModel(
                              latLong: latLong,
                              keyword: '首开广场',
                              poiType: '',
                              customId: '000FATE23（考勤打卡）',
                              size: 20,
                              aroundRadius: 1000);
    final bool state = await addAMapGeoFenceWithLatLong(model);
  }
```

5.添加行政区划围栏
```dart
  Future<void> fun() async {
  final bool state = await addAMapGeoFenceWithDistrict(
                               keyword: '海淀区', customId: '000FATE23（考勤打卡）');
  }
```

6.添加圆形围栏
```dart
  Future<void> fun() async {
  final LatLong latLong = LatLong(30.651411, 103.998638);
  final bool state = await addAMapCircleGeoFence(
                              latLong: latLong,
                              radius: 10,
                              customId: '000FATE23（考勤打卡）');
  }
```

7.添加多边形围栏
```dart
  Future<void> fun() async {
  final bool state = await addAMapCustomGeoFence(latLongs: <LatLong>[
                            LatLong(39.933921, 116.372927),
                            LatLong(39.907261, 116.376532),
                            LatLong(39.900611, 116.418161),
                            LatLong(39.941949, 116.435497),
                          ], customId: '000FATE23（考勤打卡）');
  }
```

8.获取所有围栏信息
```dart
  Future<void> fun() async {
  /// 传入 customID 获取指定标识的围栏信息 仅支持ios
  final List<AMapGeoFenceModel> data = await getAllAMapGeoFence();
  }
```

9.删除地理围栏
```dart
  Future<void> fun() async {
  /// 传入 customID 删除指定标识的围栏
  /// 不传 删除所有围栏
  final bool state = await removeAMapGeoFence();
  }
```
10.暂停监听围栏
```dart
  Future<void> fun() async {
  /// 传入 customID 暂停指定标识的围栏
  /// 不传 暂停所有围栏
  final bool state = await pauseAMapGeoFence();
  }
```
11.重新开始监听围栏
```dart
  Future<void> fun() async {
  /// 传入 customID 重新开始指定标识的围栏
  /// 不传 重新开始所有围栏
  final bool state = await resumeAMapGeoFence();
  }
```

12.开启监听服务
```dart
  Future<void> fun() async {
  final bool state = await registerAMapGeoFenceService(
                              onGeoFenceChange:
                                  (AMapGeoFenceStatusModel geoFence) {

                            print('围栏变化监听');
                     
                          });
  }
```

13.关闭监听服务
```dart
  Future<void> fun() async {
  final bool state = await stopAMapGeoFenceChange();
  }
```