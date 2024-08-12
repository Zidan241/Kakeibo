import 'package:kakeibo/bloc/cubit/app_cubit.dart';
import 'package:kakeibo/helpers/color.helper.dart';
import 'package:kakeibo/screens/onboard/widgets/primary_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csc_picker/csc_picker.dart';

class ProfileWidget extends StatefulWidget {
  final VoidCallback onGetStarted;
  const ProfileWidget({super.key, required this.onGetStarted});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  // Male, Female
  List<bool> gender = [false, false];

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppCubit cubit = context.read<AppCubit>();
    GlobalKey<CSCPickerState> _cscPickerKey = GlobalKey();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/icons/logo_with_name.png', height: 75),
              const SizedBox(
                height: 25,
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    prefixIcon: const Icon(Icons.account_circle),
                    label: const Text("Name")),
              ),
              const SizedBox(
                height: 20,
              ),
              PrimaryTextField(
                hint: 'dd-MM-yyyy',
                controller: dobController,
                textInput: TextInputType.datetime,
                inputLimit: 10,
                icon: const Icon(Icons.calendar_month_outlined),
                label: "Date Of Birth",
              ),
              const SizedBox(
                height: 20,
              ),
              ToggleButtons(
                borderRadius: BorderRadius.circular(18.0),
                isSelected: gender,
                onPressed: (index) {
                  for (int i = 0; i < gender.length; i++) {
                    setState(() {
                      gender[i] = i == index;
                    });
                  }
                },
                children: const [
                  Icon(Icons.male_rounded),
                  Icon(Icons.female_rounded),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: countryController,
                decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    prefixIcon: const Icon(Icons.flag),
                    label: const Text("Country")),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: cityController,
                decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    label: const Text("City")),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (nameController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter your name")));
            return;
          } else {
            cubit.updateUsername(nameController.text).then((value) {});
          }
          if (dobController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Please enter your date of birth")));
            return;
          } else {
            cubit.updateDob(dobController.text).then((value) {});
          }
          if (!gender.contains(true)) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select your gender")));
            return;
          } else {
            String genderStr = gender[0] ? "Male" : "Female";
            cubit.updateGender(genderStr).then((value) {});
          }
          if (countryController.text.isEmpty || cityController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Please enter your country & city")));
            return;
          } else {
            String address =
                "${countryController.text}, ${cityController.text}";
            cubit.updateAddress(address).then((value) {});
          }
          widget.onGetStarted();
        },
        label: const Row(
          children: <Widget>[
            Text("Next"),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.arrow_forward)
          ],
        ),
      ),
    );
  }
}
