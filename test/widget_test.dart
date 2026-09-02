// import 'package:flutter_test/flutter_test.dart';
// import 'package:provider/provider.dart';
// import 'package:smart_shelf/main.dart';
// import 'package:smart_shelf/providers/auth_provider.dart';
// import 'package:smart_shelf/repositories/mock_auth_repository.dart';

// void main() {
//   testWidgets('SmartShelf app renders without crashing', (WidgetTester tester) async {
//     await tester.pumpWidget(
//       MultiProvider(
//         providers: [
//           ChangeNotifierProvider<AuthProvider>(
//             create: (_) => AuthProvider(MockAuthRepository()),
//           ),
//         ],
//         child: const SmartShelfApp(),
//       ),
//     );

//     expect(find.text('Sign In'), findsWidgets);
//   });
// }

// version 2

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_shelf/main.dart';
import 'package:smart_shelf/providers/auth_provider.dart';
import 'package:smart_shelf/providers/product_provider.dart';
import 'package:smart_shelf/repositories/mock_auth_repository.dart';
import 'package:smart_shelf/repositories/mock_product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SmartShelf app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(MockAuthRepository()),
          ),
          ChangeNotifierProvider<ProductProvider>(
            create: (_) => ProductProvider(MockProductRepository()),
          ),
        ],
        child: const SmartShelfApp(),
      ),
    );

    // Re-render after state bindings resolve
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsWidgets);
  });
}