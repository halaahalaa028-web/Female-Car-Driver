import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';

void main() {
  test('resetNavBar returns to the Home tab (used on logout)', () {
    final c = BottomMenuController();
    c.setTabIndex(2);
    expect(c.currentTab, 2);
    c.resetNavBar();
    expect(c.currentTab, 0);
  });
}
