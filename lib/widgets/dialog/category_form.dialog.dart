import 'package:kakeibo/dao/category_dao.dart';
import 'package:kakeibo/data/icons.dart';
import 'package:kakeibo/events.dart';
import 'package:kakeibo/model/category.model.dart';
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
  final TextEditingController _nameController = TextEditingController();
  Category _category =
      Category(name: "", icon: Icons.wallet_outlined, color: Colors.pink);

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _category = widget.category ??
          Category(name: "", icon: Icons.wallet_outlined, color: Colors.pink);
    }
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
