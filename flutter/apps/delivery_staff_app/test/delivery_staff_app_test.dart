import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_delivery/main.dart';

void main() {
  testWidgets('shows the rider login form', (tester) async {
    await tester.pumpWidget(const KiranaDeliveryApp());

    expect(find.text('Delivery Partner'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('4-digit PIN'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('validates mobile number and PIN before calling the API', (
    tester,
  ) async {
    await tester.pumpWidget(const KiranaDeliveryApp());

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('10-digit mobile enter karein'), findsOneWidget);
    expect(find.text('4-digit PIN enter karein'), findsOneWidget);
  });
}
