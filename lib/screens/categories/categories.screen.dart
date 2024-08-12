import 'package:events_emitter/events_emitter.dart';
import 'package:kakeibo/dao/category_dao.dart';
import 'package:kakeibo/dao/payment_dao.dart';
import 'package:kakeibo/events.dart';
import 'package:kakeibo/model/category.model.dart';
import 'package:kakeibo/model/payment.model.dart';
import 'package:kakeibo/theme/colors.dart';
import 'package:kakeibo/widgets/dialog/category_form.dialog.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryDao _categoryDao = CategoryDao();
  final PaymentDao _paymentDao = PaymentDao();
  EventListener? _categoryEventListener;
  List<Category> _categories = [];
  List<Payment> _payments = [];
  final DateTimeRange _range = DateTimeRange(
      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
      end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0));
  Map<String, double> _categoryTotals = {};

  void _fetchTransactions() async {
    List<Payment> trans =
        await _paymentDao.find(range: _range, category: null, account: null);
    Map<String, double> categoryTotals = {};
    for (Payment payment in trans) {
      if (categoryTotals[payment.category.name] == null) {
        categoryTotals[payment.category.name] = payment.amount;
      } else {
        categoryTotals[payment.category.name] =
            categoryTotals[payment.category.name]! + payment.amount;
      }
    }
    //fetch categories
    List<Category> categories = await _categoryDao.find();

    setState(() {
      _payments = trans;
      _categories = categories;
      _categoryTotals = categoryTotals;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();

    _categoryEventListener = globalEvent.on("category_update", (data) {
      debugPrint("categories are changed");
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _categoryEventListener?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Monthly Budgets",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: ListView.separated(
        itemCount: _categories.length,
        itemBuilder: (builder, index) {
          Category category = _categories[index];
          double expenseProgress =
              (_categoryTotals[category.name] ?? 0) / (category.budget ?? 0);
          bool isBeyondLimit =
              expenseProgress.isFinite && expenseProgress > 1.0;

          return ListTile(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (builder) => CategoryForm(
                        category: category,
                      ));
            },
            leading: CircleAvatar(
              backgroundColor: category.color.withOpacity(0.2),
              child: Icon(
                category.icon,
                color: category.color,
              ),
            ),
            title: Row(
              children: [
                Text(
                  category.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.merge(
                      const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                ),
                if (isBeyondLimit)
                  const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: ThemeColors.error,
                    ),
                  ),
              ],
            ),
            subtitle: expenseProgress.isFinite
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: expenseProgress,
                      semanticsLabel: expenseProgress.toString(),
                    ),
                  )
                : Text("No budget",
                    style: Theme.of(context).textTheme.bodySmall?.apply(
                        color: Colors.grey, overflow: TextOverflow.ellipsis)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return Container(
            width: double.infinity,
            color: Colors.grey.withAlpha(25),
            height: 1,
            margin: const EdgeInsets.only(left: 75, right: 20),
          );
        },
      ),
    );
  }
}
