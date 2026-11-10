// Pins the iOS bundle id used for the App Store / TestFlight build.
// If you change it, change the plist, firebase_options.dart and the Xcode
// project together (ios_release_config_test.dart checks they stay consistent).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS bundle id and Firebase app id are the registered Apple ones', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
        .allMatches(pbx)
        .map((m) => m.group(1)!.trim())
        .where((i) => !i.contains('RunnerTests'))
        .toSet();
    expect(ids, {'com.femalecarrider.eon'});

    final plist = File('ios/Runner/GoogleService-Info.plist').readAsStringSync();
    expect(plist.contains('<string>com.femalecarrider.eon</string>'), isTrue);
    expect(plist.contains('<string>1:993077501425:ios:a0ccaa680ebefc0ca2b850</string>'), isTrue);

    final dart = File('lib/firebase_options.dart').readAsStringSync();
    expect(dart.contains("iosBundleId: 'com.femalecarrider.eon'"), isTrue);
    expect(dart.contains("appId: '1:993077501425:ios:a0ccaa680ebefc0ca2b850'"), isTrue);
  });
}
