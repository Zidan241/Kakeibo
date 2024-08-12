import 'package:flutter_svg/svg.dart';
import 'package:kakeibo/helpers/color.helper.dart';
import 'package:kakeibo/widgets/buttons/button.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  final VoidCallback onGetStarted;
  const LandingPage({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/icons/logo_with_name.png',
                height: 50,
              ),
              const SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Text("Redefining expenses tracking!",
                    style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(
                height: 25,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  const Expanded(
                      child: Text("Track your finances and set budgets"))
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  const Expanded(child: Text("Visual expense monitoring"))
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  const Expanded(
                    child: Text("Automated expenses tracking through sms"),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  const Expanded(
                    child: Text("Privacy prioritized, all data stored locally"),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  const Expanded(
                    child: Text(
                        "AI Integrations to get help on setting budgets, extracting information from sms & generate a detailed report to help you better manage your expenses"),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Center(
                  child: Image.asset(
                'assets/icons/rocket.png',
                height: 200,
              )),
              const Expanded(child: SizedBox()),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SvgPicture.asset(
                      'assets/icons/google-gemini-icon.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                  const Text(
                    "Powered by Google Gemini",
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                alignment: Alignment.bottomRight,
                child: AppButton(
                  color: theme.colorScheme.primary,
                  isFullWidth: true,
                  onPressed: onGetStarted,
                  size: AppButtonSize.large,
                  label: "Get Started",
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
