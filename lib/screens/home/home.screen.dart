import 'dart:convert';

import 'package:events_emitter/events_emitter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:kakeibo/bloc/cubit/app_cubit.dart';
import 'package:kakeibo/dao/account_dao.dart';
import 'package:kakeibo/dao/category_dao.dart';
import 'package:kakeibo/dao/payment_dao.dart';
import 'package:kakeibo/events.dart';
import 'package:kakeibo/model/account.model.dart';
import 'package:kakeibo/model/category.model.dart';
import 'package:kakeibo/model/payment.model.dart';
import 'package:kakeibo/screens/home/widgets/account_slider.dart';
import 'package:kakeibo/screens/home/widgets/payment_list_item.dart';
import 'package:kakeibo/screens/payment_form.screen.dart';
import 'package:kakeibo/theme/colors.dart';
import 'package:kakeibo/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

String greeting() {
  var hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Morning';
  }
  if (hour < 17) {
    return 'Afternoon';
  }
  return 'Evening';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  final CategoryDao _categoryDao = CategoryDao();
  EventListener? _accountEventListener;
  EventListener? _categoryEventListener;
  EventListener? _paymentEventListener;
  List<Payment> _payments = [];
  List<Account> _accounts = [];
  double _income = 0;
  double _expense = 0;
  //double _savings = 0;
  DateTimeRange _range = DateTimeRange(
      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
      end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0));
  Account? _account;
  Category? _category;
  String? _geminiResponse;

  // Function to request SMS permission
  // Future<void> _requestSmsPermission() async {
  //   if (await Permission.sms.request().isGranted) {
  //     // Permission is granted, query SMS messages
  //     _querySmsMessages();
  //   }
  // }

  // Function to query SMS messages
  Future<void> _querySmsMessages() async {
    // final SmsQuery _query = SmsQuery();
    // final messages = await _query.querySms(
    //   kinds: [
    //     SmsQueryKind.inbox,
    //     SmsQueryKind.sent,
    //   ],
    //   count: 10,
    // );
    // debugPrint('sms messages length: ${messages.length}');
    // debugPrint('sms messages : ${messages.first.toString()}');
    // For purposes of this competition, we will mock the messages
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("sms_loaded") == true) return;
    final messages = [
      SmsMessage.fromJson({
        "id": 1,
        "address": "HSBC",
        "body":
            "From HSBC: 12AUG24 VASKO ELREHAB Purchase from ***-111 EGP 99.00- Your available balance is EGP 7,563.90",
        "date":
            DateTime.now().add(const Duration(days: -4)).millisecondsSinceEpoch,
      }),
      SmsMessage.fromJson({
        "id": 2,
        "address": "HSBC",
        "body":
            "From HSBC: 11AUG24 TINO AND FRIENDS Purchase from ***-111 EGP 105.00- Your available balance is EGP 8,536.88",
        "date":
            DateTime.now().add(const Duration(days: -3)).millisecondsSinceEpoch,
      }),
      SmsMessage.fromJson({
        "id": 3,
        "address": "HSBC",
        "body":
            "From HSBC: 10AUG24 SHAMROO Purchase from ***-111 EGP 1,130.00- Your available balance is EGP 8,849.88",
        "date":
            DateTime.now().add(const Duration(days: -2)).millisecondsSinceEpoch,
      }),
      SmsMessage.fromJson({
        "id": 4,
        "address": "HSBC",
        "body":
            "From HSBC: 10AUG24 YLDEZ FOR KIDZ Purchase from ***-111 EGP 1,335.00- Your available balance is EGP 9,979.88",
        "date":
            DateTime.now().add(const Duration(days: -1)).millisecondsSinceEpoch,
      }),
    ];
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: "application/json",
      ),
      systemInstruction: Content.system(
          'You are an experienced financial advisor who is capable of providing thoughtful and meaningful financial and budgetting advice. Help the user with their monthly budget.'),
    );

    List<Category> categories = await _categoryDao.find();
    List<Account> accounts = await _accountDao.find(withSummery: true);

    final chat = model.startChat(history: [
      Content.multi([
        TextPart(
            'Given this sms message for a bank transaction "From HSBC: 10AUG24 SHAMROO Purchase from ***-111 EGP 1,130.00- Your available balance is EGP 8,849.88", extract all the information in JSON format.'),
      ]),
      Content.model([
        TextPart(
            '```json\n{\n  "bank": "HSBC",\n  "date": "10AUG24",\n  "transaction_type": "Debit",\n  "merchant": "SHAMROO",\n  "category": "Personal Spending",\n  "account_number": "***-111",\n  "currency": "EGP",\n  "amount": "1,130.00",\n  "balance": "8,849.88"\n}\n``` \n'),
      ]),
    ]);
    AlertDialog dialog = AlertDialog(
      content: const Text('Loading your sms messages...'),
      icon: SvgPicture.asset(
        'assets/icons/google-gemini-icon.svg',
        width: 30,
        height: 30,
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 5), () {
          Navigator.of(context).pop(); // Close the dialog
        });
        return dialog;
      },
    );
    for (SmsMessage sms in messages) {
      final message =
          "Given this sms message for a bank transaction `${sms.body}`, extract all the information and select the most suitable category from the following `${categories.map((c) => c.name).join(", ")}`. Return your response in JSON format.";
      final content = Content.text(message);
      final response = await chat.sendMessage(content);
      debugPrint(response.text);
      final responseObj = jsonDecode(response.text ?? "{}");
      if (responseObj == null || responseObj.toString() == "{}") {
        return;
      }
      if (responseObj["transaction_type"] == "Debit") {
        await _paymentDao.upsert(Payment(
            account: accounts.first,
            category: categories.firstWhereOrNull(
                    (c) => c.name == responseObj["category"]) ??
                categories.firstWhere((c) => c.name == "Miscellaneous"),
            amount: double.parse(
                responseObj["amount"].toString().replaceAll(',', '')),
            type: PaymentType.debit,
            datetime: sms.date!,
            title: responseObj["merchant"],
            description: "sms automatically extracted"));
      }
    }
    await prefs.setBool("sms_loaded", true);
    setState(() {});
  }

  void openAddPaymentPage(PaymentType type) async {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (builder) => PaymentForm(type: type)));
  }

  void handleChooseDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        _range = selected;
        _fetchTransactions();
      });
    }
  }

  void _fetchTransactions() async {
    List<Payment> trans = await _paymentDao.find(
        range: _range, category: _category, account: _account);
    double income = 0;
    double expense = 0;
    for (var payment in trans) {
      if (payment.type == PaymentType.credit) income += payment.amount;
      if (payment.type == PaymentType.debit) expense += payment.amount;
    }

    //fetch accounts
    List<Account> accounts = await _accountDao.find(withSummery: true);

    setState(() {
      _payments = trans;
      _income = income;
      _expense = expense;
      _accounts = accounts;
    });
  }

  @override
  void initState() {
    super.initState();

    // Request SMS permission when the app starts
    _querySmsMessages();

    _fetchTransactions();

    _accountEventListener = globalEvent.on("account_update", (data) {
      debugPrint("accounts are changed");
      _fetchTransactions();
    });

    _categoryEventListener = globalEvent.on("category_update", (data) {
      debugPrint("categories are changed");
      _fetchTransactions();
    });

    _paymentEventListener = globalEvent.on("payment_update", (data) {
      debugPrint("payments are changed");
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _accountEventListener?.cancel();
    _categoryEventListener?.cancel();
    _paymentEventListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.menu),
      //     onPressed: (){
      //       Scaffold.of(context).openDrawer();
      //     },
      //   ),
      //   title: const Text("Home", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),),
      // ),
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 15, top: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/logo_with_name.png',
                        height: 45,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: BlocConsumer<AppCubit, AppState>(
                    listener: (context, state) {},
                    builder: (context, state) => Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              stops: const [
                                0.1,
                                0.9
                              ],
                              colors: [
                                Colors.teal.withOpacity(0.7),
                                Colors.teal.withOpacity(1)
                              ]),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CurrencyText(_expense,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.merge(
                                            const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700),
                                          )),
                                  Text(
                                    DateFormat("MMMM").format(_range.start),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.apply(
                                            color:
                                                Colors.white.withOpacity(0.9)),
                                  ),
                                  const Expanded(child: SizedBox()),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            state.username ?? "Guest",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.apply(
                                                    color: Colors.white
                                                        .withOpacity(1),
                                                    fontWeightDelta: 2),
                                          ),
                                          Text(
                                            "Expenses",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.apply(
                                                    color: Colors.white
                                                        .withOpacity(0.5)),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                      const Expanded(child: SizedBox()),
                                      const Icon(Icons.attach_money_rounded,
                                          color: Colors.white)
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        )),
                  ),
                )
              ],
            ),
          ),
          _payments.isNotEmpty
              ? ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, index) {
                    return PaymentListItem(
                        payment: _payments[index],
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (builder) => PaymentForm(
                                    type: _payments[index].type,
                                    payment: _payments[index],
                                  )));
                        });
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Container(
                      width: double.infinity,
                      color: Colors.grey.withAlpha(25),
                      height: 1,
                      margin: const EdgeInsets.only(left: 75, right: 20),
                    );
                  },
                  itemCount: _payments.length,
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  alignment: Alignment.center,
                  child: const Text("No payments!"),
                ),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddPaymentPage(PaymentType.debit),
        child: const Icon(Icons.add),
      ),
    );
  }
}
