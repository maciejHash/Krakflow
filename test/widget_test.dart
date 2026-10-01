import 'package:flutter_test/flutter_test.dart';

import 'package:krakflow/services/notification_service.dart';

void main() {
  group('NotificationService completion trigger', () {
    test('shows notification when task changes from false to true', () {
      expect(
        NotificationService.shouldShowTaskDoneNotification(
          previousValue: false,
          newValue: true,
        ),
        isTrue,
      );
    });

    test('does not show notification when task stays true', () {
      expect(
        NotificationService.shouldShowTaskDoneNotification(
          previousValue: true,
          newValue: true,
        ),
        isFalse,
      );
    });

    test('does not show notification when task changes from true to false', () {
      expect(
        NotificationService.shouldShowTaskDoneNotification(
          previousValue: true,
          newValue: false,
        ),
        isFalse,
      );
    });
  });
}
