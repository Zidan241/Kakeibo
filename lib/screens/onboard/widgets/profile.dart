import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/helpers/color.helper.dart';
import 'package:fintracker/screens/onboard/widgets/primary_text_field.dart';
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
  // Male, Female
  List<bool> gender = [false, false];
  String countryValue = "";
  String stateValue = "";
  String cityValue = "";
  String address = "";
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
              const Icon(
                Icons.account_balance_wallet,
                size: 70,
              ),
              const SizedBox(
                height: 25,
              ),
              Text(
                "Hi! welcome to Fintracker",
                style: theme.textTheme.headlineMedium!.apply(
                    color: theme.colorScheme.primary, fontWeightDelta: 1),
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
                    hintText: "Enter your name",
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
              CSCPicker(
                ///Enable disable state dropdown [OPTIONAL PARAMETER]
                showStates: true,

                /// Enable disable city drop down [OPTIONAL PARAMETER]
                showCities: true,

                ///Enable (get flag with country name) / Disable (Disable flag) / ShowInDropdownOnly (display flag in dropdown only) [OPTIONAL PARAMETER]
                flagState: CountryFlag.DISABLE,

                ///Dropdown box decoration to style your dropdown selector [OPTIONAL PARAMETER] (USE with disabledDropdownDecoration)
                dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 1)),

                ///Disabled Dropdown box decoration to style your dropdown selector [OPTIONAL PARAMETER]  (USE with disabled dropdownDecoration)
                disabledDropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    color: Colors.grey.shade300,
                    border: Border.all(color: Colors.grey.shade300, width: 1)),

                ///placeholders for dropdown search field
                countrySearchPlaceholder: "Country",
                stateSearchPlaceholder: "State",
                citySearchPlaceholder: "City",

                ///labels for dropdown
                countryDropdownLabel: "Country",
                stateDropdownLabel: "State",
                cityDropdownLabel: "City",

                ///Dialog box radius [OPTIONAL PARAMETER]
                dropdownDialogRadius: 10.0,

                ///Search bar radius [OPTIONAL PARAMETER]
                searchBarRadius: 10.0,

                ///triggers once country selected in dropdown
                onCountryChanged: (value) {
                  setState(() {
                    ///store value in country variable
                    countryValue = value;
                  });
                },

                ///triggers once state selected in dropdown
                onStateChanged: (value) {
                  setState(() {
                    ///store value in state variable
                    stateValue = value!;
                  });
                },

                ///triggers once city selected in dropdown
                onCityChanged: (value) {
                  setState(() {
                    ///store value in city variable
                    cityValue = value!;
                  });
                },

                ///Show only specific countries using country filter
                // countryFilter: ["United States", "Canada", "Mexico"],
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
            cubit.updateUsername(nameController.text).then((value) {});
          }
          if (!gender.contains(true)) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select your gender")));
            return;
          } else {
            String genderStr = gender[0] ? "Male" : "Female";
            cubit.updateGender(genderStr).then((value) {});
          }
          if (countryValue.isEmpty || stateValue.isEmpty || cityValue.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select your location")));
            return;
          } else {
            String address = "$cityValue, $stateValue, $countryValue";
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
