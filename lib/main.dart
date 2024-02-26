import 'package:flutter/material.dart';
import 'package:qnversion_flutter_2/main_product_screen.dart';
import 'package:qonversion_flutter/qonversion_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = QonversionConfigBuilder(
          'your_qonversion_key', QLaunchMode.subscriptionManagement)

      //  sandbox is used only for the testing
      .setEnvironment(QEnvironment.sandbox)
      .build();
  Qonversion.initialize(config);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainProductScreen(),
    );
  }
}
