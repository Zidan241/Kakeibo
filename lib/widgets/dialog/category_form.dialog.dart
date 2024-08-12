import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:kakeibo/bloc/cubit/app_cubit.dart';
import 'package:kakeibo/dao/category_dao.dart';
import 'package:kakeibo/dao/payment_dao.dart';
import 'package:kakeibo/data/icons.dart';
import 'package:kakeibo/events.dart';
import 'package:kakeibo/model/category.model.dart';
import 'package:kakeibo/model/payment.model.dart';
import 'package:kakeibo/widgets/buttons/button.dart';
import 'package:kakeibo/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef Callback = void Function();

class CategoryForm extends StatefulWidget {
  final Category? category;
  final Callback? onSave;

  const CategoryForm({super.key, this.category, this.onSave});

  @override
  State<StatefulWidget> createState() => _CategoryForm();
}

class _CategoryForm extends State<CategoryForm> {
  final CategoryDao _categoryDao = CategoryDao();
  final PaymentDao _paymentDao = PaymentDao();
  final TextEditingController _nameController = TextEditingController();
  String? _geminiResponse;
  Category _category =
      Category(name: "", icon: Icons.wallet_outlined, color: Colors.pink);

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _category = widget.category ??
          Category(name: "", icon: Icons.wallet_outlined, color: Colors.pink);
      _fetchTransactions();
    }
  }

  void _fetchTransactions() async {
    final DateTimeRange range = DateTimeRange(
        start: DateTime(DateTime.now().year, DateTime.now().month - 3, 1),
        end: DateTime(DateTime.now().year, DateTime.now().month, 0));
    List<Payment> trans = await _paymentDao.find(
        range: range, category: _category, account: null);
    DateTime curr = range.start;
    List<double> sum = [];
    while (curr.isBefore(range.end)) {
      double monthSum = 0;
      for (Payment payment in trans) {
        if (payment.datetime.month == curr.month) {
          monthSum += payment.amount;
        }
      }
      sum.add(monthSum);
      curr = DateTime(curr.year, curr.month + 1, 1);
    }
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: "text/plain",
      ),
      systemInstruction: Content.system(
          'You are an experienced financial advisor who is capable of providing thoughtful and meaningful financial and budgetting advice. Help the user with their monthly budget.'),
    );

    final state = await AppState.getState();
    print(state.dob);
    final int age = DateTimeRange(
                start: DateFormat('dd-mm-yy').parse(state.dob!),
                end: DateTime.now())
            .duration
            .inDays ~/
        365;
    final chat = model.startChat(history: [
      Content.multi([
        TextPart(
            'Here is my personal information:\nI am $age years old ${state.gender}\nI live in ${state.address}\nSuggest a monthly financial budget for me in my local currency which is ${state.currency}, taking into consideration local pricing.'),
      ]),
    ]);
    final message =
        'Here is the amount of my total expenses in the `${widget.category!.name}` category for the last 3 months in order: ${sum.join(", ")}. Based on this information suggest a budget value for this month. Return a single number only.';
    final content = Content.text(message);

    final response = await chat.sendMessage(content);
    setState(() {
      _geminiResponse = response.text ?? "";
    });
  }

  void onSave(context) async {
    await _categoryDao.upsert(_category);
    if (widget.onSave != null) {
      widget.onSave!();
    }
    Navigator.pop(context);
    globalEvent.emit("category_update");
  }

  void pickIcon(context) async {}
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.all(10),
      title: Text(
        widget.category != null ? "Edit Category" : "New Category",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 15,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      color: _category.color,
                      borderRadius: BorderRadius.circular(40)),
                  alignment: Alignment.center,
                  child: Icon(
                    _category.icon,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                    child: TextFormField(
                  enabled: false, // disable name edit
                  initialValue: _category.name,
                  decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter Category name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 15)),
                  onChanged: (String text) {
                    setState(() {
                      _category.name = text;
                    });
                  },
                ))
              ],
            ),
            Container(
              padding: const EdgeInsets.only(top: 20),
              child: TextFormField(
                initialValue:
                    _category.budget == null ? "" : _category.budget.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Budget',
                  hintText: 'Enter budget',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: CurrencyText(null)),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
                onChanged: (String text) {
                  setState(() {
                    _category.budget = double.parse(text.isEmpty ? "0" : text);
                  });
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SvgPicture.asset(
                    'assets/icons/google-gemini-icon.svg',
                    width: 30,
                    height: 30,
                  ),
                ),
                _geminiResponse != null
                    ? Text(
                        'Gemini recommends using a buget of ${_geminiResponse!.replaceAll("\n", "")}')
                    : const Text(
                        "Gemini is thinking...",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
              ],
            )
          ],
        ),
      ),
      actions: [
        AppButton(
          height: 45,
          isFullWidth: true,
          onPressed: () {
            onSave(context);
          },
          color: Theme.of(context).colorScheme.primary,
          label: "Save",
        )
      ],
    );
  }
}
