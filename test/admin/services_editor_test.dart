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

    test('needs at least one real service, not only add-ons', () {
      final controller = ServicesEditorController(const [
        ArtistService(
          id: 'x',
          name: 'Head massage',
          price: 300,
          durationMinutes: 30,
          kind: ServiceKind.addOn,
        ),
      ]);
      expect(controller.hasMainService, isFalse);

      controller.add();
      expect(controller.hasMainService, isTrue);
      controller.dispose();
    });

    test('switching a row to an add-on keeps its id and saves the settings',
        () {
      final controller = ServicesEditorController(const [
        ArtistService(
          id: 'keep',
          name: 'Family member makeup',
          price: 2500,
          durationMinutes: 45,
        ),
      ]);
      final row = controller.rows.single;

      controller.setKind(row, ServiceKind.addOn);
      controller.setAllowOnSpot(row, false);
      row.maxQuantity.text = '3';

      final service = controller.toServices().single;
      expect(service.id, 'keep');
      expect(service.isAddOn, isTrue);
      expect(service.maxQuantity, 3);
      expect(service.allowOnSpot, isFalse);
      controller.dispose();
    });

    test('a main service always saves a quantity of one', () {
      final controller = ServicesEditorController(const [
        ArtistService(
          id: 'm',
          name: 'Bridal',
          price: 15000,
          durationMinutes: 180,
        ),
      ]);
      controller.rows.single.maxQuantity.text = '5';

      expect(controller.toServices().single.maxQuantity, 1);
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
