import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/admin/features/artists/presentation/widgets/services_editor.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

void main() {
  group('ServicesEditorController', () {
    test('loads existing services and keeps their ids', () {
      final controller = ServicesEditorController(const [
        ArtistService(
          id: 'keep-me',
          name: 'Bridal',
          price: 15000,
          durationMinutes: 180,
        ),
      ]);

      expect(controller.rows, hasLength(1));
      final service = controller.toServices().single;
      expect(service.id, 'keep-me');
      expect(service.price, 15000);
      expect(service.durationMinutes, 180);
      controller.dispose();
    });

    test('add and remove change the rows', () {
      final controller = ServicesEditorController(const []);
      expect(controller.isEmpty, isTrue);

      controller.add();
      controller.add();
      expect(controller.rows, hasLength(2));

      controller.remove(controller.rows.first);
      expect(controller.rows, hasLength(1));
      controller.dispose();
    });

    test('notifies listeners when rows change', () {
      final controller = ServicesEditorController(const []);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.add();
      controller.remove(controller.rows.single);

      expect(notifications, 2);
      controller.dispose();
    });

    test('new rows get distinct ids', () {
      final controller = ServicesEditorController(const [])
        ..add()
        ..add();
      final ids = controller.rows.map((r) => r.id).toSet();
      expect(ids, hasLength(2));
      controller.dispose();
    });
  });
}
