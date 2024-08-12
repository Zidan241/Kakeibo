import 'package:kakeibo/bloc/cubit/app_cubit.dart';
import 'package:kakeibo/screens/accounts/accounts.screen.dart';
import 'package:kakeibo/screens/categories/categories.screen.dart';
import 'package:kakeibo/screens/home/home.screen.dart';
import 'package:kakeibo/screens/onboard/onboard_screen.dart';
import 'package:kakeibo/screens/settings/settings.screen.dart';
import 'package:kakeibo/screens/transactions/trasations.screen.dart';
import 'package:kakeibo/screens/gemini/ai.screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _controller = PageController(keepPage: true);
  int _selected = 0;

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
              AIScreen(),
              CategoriesScreen(),
              SettingsScreen(),
            ],
            onPageChanged: (int index) {
              setState(() {
                _selected = index;
              });
            },
          ),
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0)),
            child: NavigationBar(
              selectedIndex: _selected,
              destinations: [
                const NavigationDestination(
                  icon: Icon(
                    Symbols.home,
                    fill: 1,
                  ),
                  label: "Home",
                ),
                const NavigationDestination(
                  icon: Icon(
                    Symbols.wallet,
                    fill: 1,
                  ),
                  label: "Payments",
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icons/google-gemini-icon.svg',
                    width: 30,
                    height: 30,
                  ),
                  label: "Gemini",
                ),
                const NavigationDestination(
                  icon: Icon(
                    Symbols.category,
                    fill: 1,
                  ),
                  label: "Budgets",
                ),
                const NavigationDestination(
                  icon: Icon(
                    Symbols.settings,
                    fill: 1,
                  ),
                  label: "Settings",
                ),
              ],
              onDestinationSelected: (int selected) {
                _controller.jumpToPage(selected);
              },
            ),
          ),
        );
      },
    );
  }
}
