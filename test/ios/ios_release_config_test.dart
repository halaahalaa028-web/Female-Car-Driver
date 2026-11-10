// Static checks of the iOS project. They exist to make sure the
// "black screen on launch" problem (Firebase config that does not match the
// app) and other App Store / TestFlight blockers can never come back unnoticed.
// They run on any OS (`flutter test`), no Mac needed.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/helper/startup_guard.dart';

String read(String path) => File(path).readAsStringSync();

/// Minimal plist reader: top-level `<key>` followed by `<string>`.
Map<String, String> plistStrings(String xml) {
  final map = <String, String>{};
  final re = RegExp(r'<key>([^<]+)</key>\s*<string>([^<]*)</string>');
  for (final m in re.allMatches(xml)) {
    map[m.group(1)!] = m.group(2)!;
  }
  return map;
}

bool plistHasKey(String xml, String key) => xml.contains('<key>$key</key>');

/// Values of the iOS `FirebaseOptions` block in lib/firebase_options.dart.
Map<String, String> dartIosFirebaseOptions() {
  final src = read('lib/firebase_options.dart');
  final start = src.indexOf('static const FirebaseOptions ios');
  expect(start, greaterThan(-1), reason: 'no iOS FirebaseOptions in firebase_options.dart');
  final end = src.indexOf(');', start);
  final block = src.substring(start, end);
  final map = <String, String>{};
  for (final m in RegExp(r"(\w+):\s*'([^']*)'").allMatches(block)) {
    map[m.group(1)!] = m.group(2)!;
  }
  return map;
}

void main() {
  late String pbxproj;
  late String infoPlist;
  late String appDelegate;
  late String pubspec;
  late Map<String, String> gs; // GoogleService-Info.plist

  setUpAll(() {
    pbxproj = read('ios/Runner.xcodeproj/project.pbxproj');
    infoPlist = read('ios/Runner/Info.plist');
    appDelegate = read('ios/Runner/AppDelegate.swift');
    pubspec = read('pubspec.yaml');
    gs = plistStrings(read('ios/Runner/GoogleService-Info.plist'));
  });

  group('Firebase config matches the app (root cause of the black screen)', () {
    test('GoogleService-Info.plist exists and has the required keys', () {
      for (final k in ['API_KEY', 'GCM_SENDER_ID', 'BUNDLE_ID', 'PROJECT_ID', 'GOOGLE_APP_ID']) {
        expect(gs[k], isNotNull, reason: 'missing $k');
        expect(gs[k], isNotEmpty, reason: 'empty $k');
      }
    });

    test('plist BUNDLE_ID equals the Xcode PRODUCT_BUNDLE_IDENTIFIER (all configurations)', () {
      final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
          .allMatches(pbxproj)
          .map((m) => m.group(1)!.trim())
          .where((id) => !id.contains('RunnerTests'))
          .toSet();
      expect(ids, hasLength(1), reason: 'Runner configurations use different bundle ids: $ids');
      expect(gs['BUNDLE_ID'], ids.single);
    });

    test('plist values equal the iOS FirebaseOptions in Dart', () {
      final dart = dartIosFirebaseOptions();
      expect(gs['GOOGLE_APP_ID'], dart['appId'], reason: 'appId differs -> Firebase.initializeApp throws on iOS');
      expect(gs['API_KEY'], dart['apiKey']);
      expect(gs['GCM_SENDER_ID'], dart['messagingSenderId']);
      expect(gs['PROJECT_ID'], dart['projectId']);
      expect(gs['BUNDLE_ID'], dart['iosBundleId']);
    });

    test('GOOGLE_APP_ID is an iOS app id of the same sender / project number', () {
      final id = gs['GOOGLE_APP_ID']!;
      expect(id, matches(RegExp(r'^1:\d+:ios:[0-9a-f]+$')));
      expect(id.split(':')[1], gs['GCM_SENDER_ID']);
    });

    test('no leftover template (6amtech / hexaride / drivevalley) Firebase identifiers', () {
      final files = <String>[
        'ios/Runner/GoogleService-Info.plist',
        'ios/Runner/Info.plist',
        'ios/Runner.xcodeproj/project.pbxproj',
        'lib/firebase_options.dart',
      ];
      for (final f in files) {
        final text = read(f).toLowerCase();
        for (final bad in ['sixamtech', 'hexaride', 'drivevalley']) {
          expect(text.contains(bad), isFalse, reason: '$f still contains "$bad"');
        }
      }
    });

    test('plist is bundled as a Resource and NOT compiled as a Source', () {
      final fileRef = RegExp(r'(\w+) /\* GoogleService-Info\.plist \*/ = \{isa = PBXFileReference').firstMatch(pbxproj);
      expect(fileRef, isNotNull, reason: 'GoogleService-Info.plist is not part of the Xcode project');
      expect(pbxproj.contains('GoogleService-Info.plist in Resources'), isTrue,
          reason: 'plist missing from "Copy Bundle Resources" -> not shipped in the app');
      expect(pbxproj.contains('GoogleService-Info.plist in Sources'), isFalse,
          reason: 'plist added to "Compile Sources" instead of Resources');
      // The build file must actually be listed in the Resources build phase.
      final resourcesPhase = RegExp(r'PBXResourcesBuildPhase section.*?End PBXResourcesBuildPhase section', dotAll: true)
          .firstMatch(pbxproj)!
          .group(0)!;
      expect(resourcesPhase.contains('GoogleService-Info.plist in Resources'), isTrue);
    });

    test('only one GoogleService-Info.plist is bundled (".old" copies are not part of the target)', () {
      expect(pbxproj.contains('GoogleService-Info.plist.old'), isFalse);
    });
  });

  group('AppDelegate', () {
    test('does not import a framework whose plugin was removed', () {
      if (appDelegate.contains('import GoogleMaps')) {
        expect(pubspec.contains('google_maps_flutter'), isTrue,
            reason: 'AppDelegate imports GoogleMaps but google_maps_flutter is not a dependency (iOS build breaks)');
      }
      if (pubspec.contains(RegExp(r'^\s+google_maps_flutter:', multiLine: true)) == false) {
        expect(appDelegate.contains('GMSServices'), isFalse);
      }
    });

    test('never calls FirebaseApp.configure() unguarded (crashes at launch if plist missing)', () {
      final calls = RegExp(r'FirebaseApp\.configure\(\)').allMatches(appDelegate).toList();
      if (calls.isNotEmpty) {
        expect(appDelegate.contains('GoogleService-Info'), isTrue,
            reason: 'configure() must be guarded by a check that the plist is in the bundle');
        expect(appDelegate.contains('FirebaseApp.app() == nil'), isTrue);
      }
    });

    test('registers plugins and calls super', () {
      expect(appDelegate.contains('GeneratedPluginRegistrant.register(with: self)'), isTrue);
      expect(appDelegate.contains('super.application(application, didFinishLaunchingWithOptions: launchOptions)'), isTrue);
    });

    test('API keys are not hard-coded in Swift / Info.plist', () {
      expect(appDelegate.contains(RegExp(r'AIza[0-9A-Za-z_\-]{20,}')), isFalse);
      expect(infoPlist.contains(RegExp(r'AIza[0-9A-Za-z_\-]{20,}')), isFalse);
    });
  });

  group('Info.plist', () {
    test('is well-formed XML plist', () {
      expect(infoPlist.trimLeft().startsWith('<?xml'), isTrue);
      expect(infoPlist.contains('<plist'), isTrue);
      expect(infoPlist.trimRight().endsWith('</plist>'), isTrue);
      // balanced dict/array tags
      expect('<dict>'.allMatches(infoPlist).length + '<dict/>'.allMatches(infoPlist).length,
          greaterThanOrEqualTo('</dict>'.allMatches(infoPlist).length));
      expect('<dict>'.allMatches(infoPlist).length, '</dict>'.allMatches(infoPlist).length);
      expect('<array>'.allMatches(infoPlist).length, '</array>'.allMatches(infoPlist).length);
    });

    test('version comes from pubspec (FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER)', () {
      final p = plistStrings(infoPlist);
      expect(p['CFBundleShortVersionString'], r'$(FLUTTER_BUILD_NAME)');
      expect(p['CFBundleVersion'], r'$(FLUTTER_BUILD_NUMBER)');
      expect(p['CFBundleExecutable'], r'$(EXECUTABLE_NAME)');
      expect(p['CFBundleIdentifier'], r'$(PRODUCT_BUNDLE_IDENTIFIER)');
    });

    test('pubspec version is x.y.z+build', () {
      expect(RegExp(r'^version:\s*\d+\.\d+\.\d+\+\d+\s*$', multiLine: true).hasMatch(pubspec), isTrue);
    });

    test('privacy usage descriptions exist and are not empty (App Store rejects / app crashes otherwise)', () {
      final p = plistStrings(infoPlist);
      final needed = <String>[
        if (pubspec.contains('image_picker')) ...['NSCameraUsageDescription', 'NSPhotoLibraryUsageDescription'],
        if (pubspec.contains('geolocator')) ...[
          'NSLocationWhenInUseUsageDescription',
          'NSLocationAlwaysAndWhenInUseUsageDescription',
        ],
      ];
      for (final k in needed) {
        expect((p[k] ?? '').trim(), isNotEmpty, reason: 'missing/empty $k');
      }
    });

    test('push notifications: remote-notification background mode', () {
      expect(infoPlist.contains('<string>remote-notification</string>'), isTrue);
    });

    test('Main storyboard and launch screen exist', () {
      final p = plistStrings(infoPlist);
      final main = p['UIMainStoryboardFile'];
      final launch = p['UILaunchStoryboardName'];
      if (main != null) expect(File('ios/Runner/Base.lproj/$main.storyboard').existsSync(), isTrue);
      if (launch != null) expect(File('ios/Runner/Base.lproj/$launch.storyboard').existsSync(), isTrue);
    });

    test('Maps key placeholder is only used when Google Maps is a dependency', () {
      if (infoPlist.contains(r'$(GMS_API_KEY)')) {
        expect(pubspec.contains('google_maps_flutter'), isTrue);
      }
    });

    test('export compliance flag is declared (no manual question on every TestFlight upload)', () {
      expect(plistHasKey(infoPlist, 'ITSAppUsesNonExemptEncryption'), isTrue);
    });
  });

  group('Signing / capabilities', () {
    test('entitlements file referenced by the project exists and declares push', () {
      final refs = RegExp(r'CODE_SIGN_ENTITLEMENTS = "?([^";]+)"?;').allMatches(pbxproj).map((m) => m.group(1)!).toSet();
      expect(refs, isNotEmpty);
      for (final r in refs) {
        final f = File('ios/$r');
        expect(f.existsSync(), isTrue, reason: 'missing entitlements file ios/$r');
        expect(f.readAsStringSync().contains('aps-environment'), isTrue, reason: '$r has no aps-environment');
      }
    });

    test('a development team is configured', () {
      expect(RegExp(r'DEVELOPMENT_TEAM = [A-Z0-9]{10};').hasMatch(pbxproj), isTrue);
    });

    test('Podfile platform is not higher than the project deployment target', () {
      final podfile = read('ios/Podfile');
      final pod = double.parse(RegExp(r"platform :ios, '([\d.]+)'").firstMatch(podfile)!.group(1)!);
      final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);')
          .allMatches(pbxproj)
          .map((m) => double.parse(m.group(1)!))
          .toList();
      expect(targets, isNotEmpty);
      for (final t in targets) {
        expect(t, greaterThanOrEqualTo(pod), reason: 'project target $t < Podfile platform $pod');
      }
      expect(pod, greaterThanOrEqualTo(13.0)); // Firebase 11+/12+ need >= 13/15
    });
  });

  group('App icon (App Store Connect validation)', () {
    test('1024x1024 marketing icon exists, is a PNG and has NO alpha channel', () {
      final dir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
      expect(dir.existsSync(), isTrue);
      final contents = read('${dir.path}/Contents.json');
      expect(contents.contains('ios-marketing'), isTrue, reason: 'no 1024x1024 ios-marketing entry');
      final name = RegExp(r'"filename"\s*:\s*"([^"]+)"[^}]*"idiom"\s*:\s*"ios-marketing"|"idiom"\s*:\s*"ios-marketing"[^}]*"filename"\s*:\s*"([^"]+)"|"filename"\s*:\s*"([^"]+)"[^}]*"size"\s*:\s*"1024x1024"|"size"\s*:\s*"1024x1024"[^}]*"filename"\s*:\s*"([^"]+)"', dotAll: true)
          .firstMatch(contents);
      expect(name, isNotNull);
      final fname = [name!.group(1), name.group(2), name.group(3), name.group(4)].firstWhere((e) => e != null)!;
      final f = File('${dir.path}/$fname');
      expect(f.existsSync(), isTrue, reason: '$fname referenced but missing');
      final bytes = f.readAsBytesSync();
      expect(bytes.sublist(1, 4), [0x50, 0x4E, 0x47], reason: 'not a PNG');
      final width = ByteData.sublistView(bytes).getUint32(16);
      final height = ByteData.sublistView(bytes).getUint32(20);
      expect([width, height], [1024, 1024]);
      final colorType = bytes[25]; // 4 = gray+alpha, 6 = RGBA
      expect(colorType == 4 || colorType == 6, isFalse,
          reason: 'icon has an alpha channel (colour type $colorType): App Store Connect rejects it');
    });

    test('every icon file listed in Contents.json exists', () {
      final dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final names = RegExp(r'"filename"\s*:\s*"([^"]+)"').allMatches(read('$dir/Contents.json')).map((m) => m.group(1)!);
      for (final n in names) {
        expect(File('$dir/$n').existsSync(), isTrue, reason: 'missing icon $n');
      }
    });
  });

  group('Start-up never blocks before the first frame (startup_guard)', () {
    test('Firebase init throwing + no native app -> returns false, does not throw', () async {
      final ready = await initFirebaseSafely(
        hasApps: () => false,
        initialize: () async => throw StateError('already exists with different options'),
        fallbackApp: () => throw StateError('no app'),
        onError: (_) {},
      );
      expect(ready, isFalse);
    });

    test('Firebase init throwing but a native default app exists -> still ready', () async {
      final ready = await initFirebaseSafely(
        hasApps: () => false,
        initialize: () async => throw StateError('mismatch'),
        fallbackApp: () {},
        onError: (_) {},
      );
      expect(ready, isTrue);
    });

    test('already configured natively -> initialize is not called again', () async {
      var called = false;
      final ready = await initFirebaseSafely(
        hasApps: () => true,
        initialize: () async => called = true,
        fallbackApp: () {},
      );
      expect(ready, isTrue);
      expect(called, isFalse);
    });

    test('Firebase init that hangs forever is cut by the timeout', () async {
      final sw = Stopwatch()..start();
      final ready = await initFirebaseSafely(
        hasApps: () => false,
        initialize: () => Future<void>.delayed(const Duration(days: 1)),
        fallbackApp: () => throw StateError('no app'),
        timeout: const Duration(milliseconds: 80),
        onError: (_) {},
      );
      expect(ready, isFalse);
      expect(sw.elapsed, lessThan(const Duration(seconds: 3)));
    });

    test('guardedStep returns the value, null on error and null on timeout', () async {
      expect(await guardedStep(() async => 42), 42);
      expect(await guardedStep<int>(() async => throw StateError('x'), onError: (_) {}), isNull);
      expect(
        await guardedStep<int>(() => Future<int>.delayed(const Duration(days: 1)),
            timeout: const Duration(milliseconds: 50), onError: (_) {}),
        isNull,
      );
    });

    test('main() uses the guards (no bare awaits that can hang before runApp)', () {
      final main = read('lib/main.dart');
      final runApp = main.indexOf('runApp(');
      final before = main.substring(0, runApp);
      expect(before.contains('initFirebaseSafely('), isTrue);
      expect(before.contains(RegExp(r'await\s+Firebase\.initializeApp\(')), isFalse,
          reason: 'bare Firebase.initializeApp before runApp can leave a black screen');
      expect(before.contains(RegExp(r'await\s+FirebaseMessaging\.instance\.getInitialMessage\(')), isFalse);
      expect(before.contains(RegExp(r'await\s+NotificationHelper\.initialize\(')), isFalse);
    });
  });
}
