import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_shelf/main.dart';
import 'package:smart_shelf/providers/auth_provider.dart';
import 'package:smart_shelf/repositories/mock_auth_repository.dart';

void main() {
  testWidgets('SmartShelf app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(MockAuthRepository()),
          ),
        ],
        child: const SmartShelfApp(),
      ),
    );

    expect(find.text('Sign In'), findsWidgets);
  });
}
