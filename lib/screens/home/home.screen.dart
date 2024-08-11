import 'package:events_emitter/events_emitter.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/events.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/screens/home/widgets/account_slider.dart';
import 'package:fintracker/screens/home/widgets/payment_list_item.dart';
import 'package:fintracker/screens/payment_form.screen.dart';
import 'package:fintracker/theme/colors.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
            padding: const EdgeInsets.only(left: 15, right: 15, top: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text("Hi! Good ${greeting()}"),
                ),
                BlocConsumer<AppCubit, AppState>(
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
                                          color: Colors.white.withOpacity(0.9)),
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
        onPressed: () => openAddPaymentPage(PaymentType.credit),
        child: const Icon(Icons.add),
      ),
    );
  }
}
