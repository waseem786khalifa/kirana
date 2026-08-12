import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_customer/src/customer_ui.dart';
import 'package:kirana_customer/src/domain.dart';

void main() {
  const Map<String, String> seedAssets = <String, String>{
    'Aashirvaad Shuddh Chakki Atta': 'assets/images/products/atta.png',
    'Fortune Kachi Ghani Mustard Oil': 'assets/images/products/mustard_oil.png',
    'Amul Pure Cow Ghee Pouch': 'assets/images/products/ghee.png',
    'Tata Tea Gold': 'assets/images/products/tea.png',
    'India Gate Basmati Rice': 'assets/images/products/basmati_rice.png',
    'Bikanervala Bikaneri Bhujia': 'assets/images/products/bhujia.png',
    'Fortune Sunlite Refined Oil': 'assets/images/products/sunflower_oil.png',
    'Tata Salt': 'assets/images/products/salt.png',
  };

  test('all eight seeded products resolve to their exact local artwork', () {
    var id = 0;
    for (final MapEntry<String, String> entry in seedAssets.entries) {
      id++;
      expect(
        customerProductAsset(
          _product(id: id, name: entry.key, category: 'Unknown'),
        ),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('category aliases and unknown categories resolve predictably', () {
    const Map<String, String> categoryAssets = <String, String>{
      'Atta & Flour': 'assets/images/products/atta.png',
      'Whole Wheat Flour': 'assets/images/products/atta.png',
      'Cooking Oil': 'assets/images/products/mustard_oil.png',
      'Ghee & Dairy': 'assets/images/products/ghee.png',
      'Tea & Coffee': 'assets/images/products/tea.png',
      'Rice': 'assets/images/products/basmati_rice.png',
      'Snacks & Namkeen': 'assets/images/products/bhujia.png',
      'Salt & Staples': 'assets/images/products/salt.png',
      'Dal & Pulses': 'assets/images/categories/all_groceries.png',
      'Something New': 'assets/images/categories/all_groceries.png',
      'All': 'assets/images/categories/all_groceries.png',
    };

    for (final MapEntry<String, String> entry in categoryAssets.entries) {
      expect(customerCategoryAsset(entry.key), entry.value, reason: entry.key);
    }
    expect(
      customerProductAsset(
        _product(name: 'Generic Pantry Item', category: 'Cooking Oil'),
      ),
      'assets/images/products/mustard_oil.png',
    );
    expect(
      customerProductAsset(
        _product(name: 'Generic Pantry Item', category: 'Something New'),
      ),
      'assets/images/categories/all_groceries.png',
    );
  });

  testWidgets('every declared customer raster asset loads from rootBundle', (
    WidgetTester tester,
  ) async {
    final Set<String> paths = <String>{
      ...seedAssets.values,
      'assets/images/categories/all_groceries.png',
      CustomerPromoImage.assetPath,
    };

    for (final String path in paths) {
      final ByteData data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  testWidgets('product artwork renders without overflow at every app size', (
    WidgetTester tester,
  ) async {
    const List<Size> sizes = <Size>[
      Size(52, 52),
      Size(67, 76),
      Size(72, 84),
      Size(124, 85),
      Size(283, 232),
    ];

    for (final Size size in sizes) {
      await tester.pumpWidget(
        _ImageHarness(
          child: SizedBox(
            key: ValueKey<Size>(size),
            width: size.width,
            height: size.height,
            child: CustomerProductImage(
              product: _product(
                name: 'India Gate Basmati Rice',
                category: 'Rice',
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$size');
      final Finder image = find.byType(Image);
      expect(image, findsOneWidget, reason: '$size');
      expect(
        _assetName(tester.widget<Image>(image).image),
        'assets/images/products/basmati_rice.png',
        reason: '$size',
      );
      expect(tester.getSize(find.byKey(ValueKey<Size>(size))), size);
    }
  });

  testWidgets('category and promo artwork render at compact and banner sizes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _ImageHarness(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 52,
              height: 52,
              child: CustomerCategoryImage(category: 'Atta & Flour'),
            ),
            SizedBox(
              width: 76,
              height: 76,
              child: CustomerCategoryImage(category: 'Something New'),
            ),
            SizedBox(width: 320, height: 100, child: CustomerPromoImage()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final List<String> assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((Image image) => _assetName(image.image))
        .toList(growable: false);
    expect(
      assetNames,
      containsAll(<String>[
        'assets/images/products/atta.png',
        'assets/images/categories/all_groceries.png',
        CustomerPromoImage.assetPath,
      ]),
    );
  });
}

String _assetName(ImageProvider<Object> provider) {
  if (provider case AssetImage image) return image.assetName;
  if (provider case ResizeImage image) {
    return _assetName(image.imageProvider);
  }
  throw TestFailure('Expected an asset-backed image, got $provider');
}

CustomerProduct _product({
  int id = 1,
  required String name,
  required String category,
}) {
  return CustomerProduct(
    id: id,
    storeId: 1,
    name: name,
    category: category,
    packSize: '1 unit',
    mrp: 100,
    price: 90,
    stock: 5,
    imageUrl: '',
    available: true,
  );
}

class _ImageHarness extends StatelessWidget {
  const _ImageHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }
}
