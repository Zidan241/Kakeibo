import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryTextField extends StatelessWidget {
  final Widget icon;
  final bool enable;
  final TextInputType textInput;
  final int inputLimit;
  final TextEditingController controller;
  final String? hint;
  final String? label;

  const PrimaryTextField({
    super.key,
    required this.icon,
    required this.controller,
    this.hint,
    this.textInput = TextInputType.text,
    this.enable = true,
    this.inputLimit = 100,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextFormField(
        keyboardType: textInput,
        controller: controller,
        inputFormatters: [
          LengthLimitingTextInputFormatter(inputLimit),
          if (textInput == TextInputType.number)
            FilteringTextInputFormatter.digitsOnly,
          if (textInput == TextInputType.datetime) _DateInputFormatter(),
        ],
        cursorColor: Theme.of(context).colorScheme.primary,
        decoration: InputDecoration(
          filled: true,
          prefixIcon: icon,
          hintText: hint,
          border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18.0))),
          label: Text(label ?? ""),
        ),
      ),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    int c = oldValue.text.length;
    // Deleting
    if (c > newValue.text.length) {
      return newValue;
    }
    // Appending
    if (c > 3 && oldValue.text.endsWith('-')) {
      c--;
    }
    if (oldValue.text.isNotEmpty &&
        oldValue.text.endsWith('-') &&
        c > newValue.text.length) {
      return newValue.copyWith(
        text: oldValue.text.substring(0, oldValue.text.length - 1),
        selection: TextSelection.collapsed(
          offset: oldValue.text.length - 1,
        ),
      );
    }

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var dateText = _addSlashes(newValue.text);
    return newValue.copyWith(
      text: dateText,
      selection: TextSelection.collapsed(offset: dateText.length),
    );
  }

  String _addSlashes(String input) {
    input = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (input.length >= 2) {
      input = '${_validateDay(input.substring(0, 2))}-${input.substring(2)}';
    }
    if (input.length >= 5) {
      input =
          '${input.substring(0, 3)}${_validateMonth(input.substring(3, 5))}-${input.substring(5)}';
    }
    if (input.length >= 10) {
      input = input.substring(0, 6) + _validateYear(input.substring(6));
    }
    return input;
  }

  String _validateDay(String day) {
    if (day.isEmpty) return '01';

    int dayValue = int.parse(day);
    if (dayValue < 1) {
      return '01';
    } else if (dayValue > 31) {
      return '31';
    } else {
      return day.padLeft(2, '0');
    }
  }

  String _validateMonth(String month) {
    if (month.isEmpty) return '01';
    int monthValue = int.parse(month);
    if (monthValue < 1) {
      return '01';
    } else if (monthValue > 12) {
      return '12';
    } else if (monthValue < 10) {
      return month.padLeft(2, '0');
    } else {
      return monthValue.toString();
    }
  }

  String _validateYear(String year) {
    if (year.isEmpty) return '0000';

    int yearValue = int.parse(year);
    int startYear = DateTime.now().year - 100;
    int endYear = DateTime.now().year;

    if (yearValue < startYear) {
      return startYear.toString();
    } else if (yearValue > endYear) {
      return endYear.toString();
    } else {
      return year;
    }
  }
}
