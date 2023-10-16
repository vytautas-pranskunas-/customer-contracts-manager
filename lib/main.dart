import 'package:customer_contract_manager/pages/home/home.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(400, 800),
      builder: (_, child) => OKToast(
        position: ToastPosition.bottom,
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: 15.sp, color: const Color(0xFF1D3557)),
              bodyMedium: TextStyle(fontSize: 13.sp, color: const Color(0xFF1D3557)),
              displayLarge: TextStyle(fontSize: 36.sp),
              displayMedium: TextStyle(fontSize: 24.sp),
              displaySmall: TextStyle(fontSize: 20.sp),
              headlineSmall: TextStyle(fontSize: 24.sp),
              bodySmall: TextStyle(fontSize: 12.sp),
              titleMedium: TextStyle(fontSize: 15.sp, color: const Color(0xFF1D3557)),
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D3557)),
            useMaterial3: true,
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}
