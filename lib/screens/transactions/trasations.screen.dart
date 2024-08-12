import 'dart:math';

import 'package:events_emitter/events_emitter.dart';
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
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final CategoryDao _categoryDao = CategoryDao();
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  EventListener? _accountEventListener;
  EventListener? _categoryEventListener;
  EventListener? _paymentEventListener;
  List<Payment> _payments = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  double _income = 0;
  double _expense = 0;
  final List<bool> _lineChartIsSelected = [true, false];
  int _pieChartTouchedIndex = 0;
  late PageController _pageController;

  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: DateTime.now().day - 1)),
      end: DateTime.now());
  Account? _account;
  Category? _category;

  void openAddPaymentPage(PaymentType type) async {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (builder) => PaymentForm(type: type)));
  }

  void handleChooseDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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

    //fetch categories
    List<Category> categories = await _categoryDao.find();

    setState(() {
      _payments = trans;
      _income = income;
      _expense = expense;
      _accounts = accounts;
      _categories = categories;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  List<Color> gradientColors = [
    const Color(0xFF6200EE),
    ThemeColors.infoAccent
  ];

  List<Color> lightGradientColors = [
    const Color(0xff6200EE).withOpacity(0.3),
    ThemeColors.infoAccent.withOpacity(0.3)
  ];

  LineChartData lineChartData() {
    final List<FlSpot> spots = [];
    DateTime cur = _range.start;
    DateTime end = _range.end.add(const Duration(seconds: 1));
    double x = 0;
    double maxY = 0;
    while (cur.isBefore(end)) {
      double y = 0;
      for (Payment payment in _payments) {
        if (payment.datetime.isSameDate(cur)) {
          y += payment.amount;
        }
      }
      maxY = max(y, maxY);
      spots.add(FlSpot(x, y));
      x++;
      cur = cur.add(const Duration(days: 1));
    }
    return LineChartData(
      gridData: const FlGridData(
        show: true,
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: x - 1,
      minY: -maxY * 0.1,
      maxY: maxY * 1.1, // 10% free
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: lightGradientColors,
            ),
          ),
        ),
      ],
    );
  }

  PieChartData pieChartData() {
    Map<String, double> categoryTotals = {};
    for (Payment payment in _payments) {
      if (categoryTotals[payment.category.name] == null) {
        categoryTotals[payment.category.name] = payment.amount;
      } else {
        categoryTotals[payment.category.name] =
            categoryTotals[payment.category.name]! + payment.amount;
      }
    }
    final List<PieChartSectionData> sections = [];
    for (int i = 0; i < categoryTotals.values.length; i++) {
      final category = _categories.firstWhere((Category category) =>
          category.name == categoryTotals.keys.elementAt(i));
      final isTouched = i == _pieChartTouchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      sections.add(PieChartSectionData(
        color: category.color,
        value: categoryTotals.values.elementAt(i),
        title:
            '${((categoryTotals.values.elementAt(i) / _expense) * 100).toStringAsFixed(2)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
          shadows: shadows,
        ),
        badgeWidget: _Badge(
          category.icon,
          size: widgetSize,
          borderColor: Colors.grey,
        ),
        badgePositionPercentageOffset: .98,
      ));
    }
    return PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              _pieChartTouchedIndex = -1;
              return;
            }
            _pieChartTouchedIndex =
                pieTouchResponse.touchedSection!.touchedSectionIndex;
          });
        },
      ),
      borderData: FlBorderData(
        show: false,
      ),
      sectionsSpace: 2,
      centerSpaceRadius: 5,
      sections: sections,
    );
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
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                PageView(
                  padEnds: false,
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // -- Line Chart --
                    AspectRatio(
                        aspectRatio: 1.6, child: LineChart(lineChartData())),
                    // -- Pie Chart --
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: lightGradientColors,
                        ),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.3,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: PieChart(pieChartData()),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: Colors.white.withOpacity(0.80),
                    ),
                    child: ToggleButtons(
                      color: Colors.black.withOpacity(0.60),
                      selectedColor: Color(0xFF6200EE),
                      selectedBorderColor: Color(0xFF6200EE),
                      fillColor: Color(0xFF6200EE).withOpacity(0.08),
                      splashColor: Color(0xFF6200EE).withOpacity(0.12),
                      hoverColor: Color(0xFF6200EE).withOpacity(0.04),
                      borderRadius: BorderRadius.circular(4.0),
                      isSelected: _lineChartIsSelected,
                      onPressed: (index) {
                        // Respond to button selection
                        setState(() {
                          _pageController.animateToPage(index,
                              duration: Durations.medium4,
                              curve: Curves.linear);
                          for (int i = 0;
                              i < _lineChartIsSelected.length;
                              i++) {
                            _lineChartIsSelected[i] = i == index;
                          }
                        });
                      },
                      children: const [
                        Icon(Icons.area_chart_rounded),
                        Icon(Icons.pie_chart_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18.0),
                    bottomRight: Radius.circular(18.0)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: lightGradientColors,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(149, 157, 165, 0.2),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MaterialButton(
                    onPressed: () {
                      handleChooseDateRange();
                    },
                    height: double.minPositive,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    child: Row(
                      children: [
                        Text(
                          "${DateFormat("dd MMM").format(_range.start)} - ${DateFormat("dd MMM").format(_range.end)}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Icon(Icons.arrow_drop_down_outlined)
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text.rich(TextSpan(children: [
                          //TextSpan(text: "▲", style: TextStyle(color: ThemeColors.error)),
                          TextSpan(
                              text: "Total",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ])),
                        const SizedBox(
                          height: 5,
                        ),
                        CurrencyText(
                          _expense,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              )),
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

class _Badge extends StatelessWidget {
  const _Badge(
    this.icon, {
    required this.size,
    required this.borderColor,
  });
  final IconData icon;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(child: Icon(icon)),
    );
  }
}
