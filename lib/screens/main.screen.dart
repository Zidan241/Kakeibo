import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/screens/accounts/accounts.screen.dart';
import 'package:fintracker/screens/categories/categories.screen.dart';
import 'package:fintracker/screens/home/home.screen.dart';
import 'package:fintracker/screens/onboard/onboard_screen.dart';
import 'package:fintracker/screens/settings/settings.screen.dart';
import 'package:fintracker/screens/transactions/trasations.screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _controller = PageController(keepPage: true);
  int _selected = 0;
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Request SMS permission when the app starts
    _requestSmsPermission();
  }

  // Function to request SMS permission
  Future<void> _requestSmsPermission() async {
    if (await Permission.sms.request().isGranted) {
      // Permission is granted, query SMS messages
      _querySmsMessages();
    }
  }

  // Function to query SMS messages
  Future<void> _querySmsMessages() async {
    final messages = await _query.querySms(
      kinds: [
        SmsQueryKind.inbox,
        SmsQueryKind.sent,
      ],
      count: 10,
    );
    debugPrint('sms messages length: ${messages.length}');
    debugPrint('sms messages : ${messages.first.toString()}');

    setState(() => _messages = messages);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        AppCubit cubit = context.read<AppCubit>();
        if (cubit.state.currency == null || cubit.state.username == null) {
          return OnboardScreen();
        }
        return Scaffold(
          body: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              HomeScreen(),
              TransactionsScreen(),
              CategoriesScreen(),
              SettingsScreen()
            ],
            onPageChanged: (int index) {
              setState(() {
                _selected = index;
              });
            },
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selected,
            destinations: const [
              NavigationDestination(
                  icon: Icon(
                    Symbols.home,
                    fill: 1,
                  ),
                  label: "Home"),
              NavigationDestination(
                  icon: Icon(
                    Symbols.wallet,
                    fill: 1,
                  ),
                  label: "Accounts"),
              NavigationDestination(
                  icon: Icon(
                    Symbols.category,
                    fill: 1,
                  ),
                  label: "Budgets"),
              NavigationDestination(
                  icon: Icon(
                    Symbols.settings,
                    fill: 1,
                  ),
                  label: "Settings"),
            ],
            onDestinationSelected: (int selected) {
              _controller.jumpToPage(selected);
            },
          ),
        );
      },
    );
  }
}
