
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/transaction.dart';
import '../../blocs/transaction/transaction_cubit.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;

  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _loadingCategories = true;

  static const String _incomeKey = 'custom_income_categories';
  static const String _expenseKey = 'custom_expense_categories';

  static const List<String> _incomeCategories = [
    'Salary',
    'Business',
    'Investment',
    'Gift',
    'Other',
  ];

  static const List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Education',
    'Entertainment',
    'Other',
  ];

  List<String> _customIncomeCategories = [];
  List<String> _customExpenseCategories = [];

  String? _category;

  List<String> get _categories {
    final defaults = _type == TransactionType.income
        ? _incomeCategories
        : _expenseCategories;

    final custom = _type == TransactionType.income
        ? _customIncomeCategories
        : _customExpenseCategories;

    return [...defaults, ...custom];
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == TransactionType.income
        ? _incomeCategories.first
        : _expenseCategories.first;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _customIncomeCategories =
          prefs.getStringList(_incomeKey) ?? [];
      _customExpenseCategories =
          prefs.getStringList(_expenseKey) ?? [];

      _category = _categories.first;
      _loadingCategories = false;
    });
  }

  Future<void> _persistCategories() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _incomeKey,
      _customIncomeCategories,
    );

    await prefs.setStringList(
      _expenseKey,
      _customExpenseCategories,
    );
  }


  Future<void> _addCategory() async {
    String enteredName = '';

    final newCategory = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Category name',
              hintText: 'e.g. Freelance or Pet Care',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              enteredName = value;
            },
            onSubmitted: (value) {
              final name = value.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, name);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final name = enteredName.trim();

                if (name.isEmpty) return;

                Navigator.pop(dialogContext, name);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (!mounted || newCategory == null) return;

    final name = newCategory.trim();

    if (name.isEmpty) return;

    final duplicate = _categories.any(
          (category) =>
      category.toLowerCase() == name.toLowerCase(),
    );

    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This category already exists.'),
        ),
      );
      return;
    }

    setState(() {
      if (_type == TransactionType.income) {
        _customIncomeCategories.add(name);
      } else {
        _customExpenseCategories.add(name);
      }

      _category = name;
    });

    try {
      await _persistCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        if (_type == TransactionType.income) {
          _customIncomeCategories.remove(name);
        } else {
          _customExpenseCategories.remove(name);
        }

        _category = _categories.first;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save category: $error'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _saveTransaction() async {
    if (_loadingCategories) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final transaction = ExpenseTransaction(
        type: _type,
        amount: double.parse(_amountController.text.trim()),
        category: _category!,
        date: _date,
        note: _noteController.text.trim(),
      );

      await context
          .read<TransactionCubit>()
          .addTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save transaction: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isIncome = _type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.north_east_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.south_west_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (values) {
                  setState(() {
                    _type = values.first;
                    _category = _categories.first;
                  });
                },
              ),
              const SizedBox(height: 28),
              Text('Amount', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount =
                  double.tryParse(value?.trim() ?? '');

                  if (amount == null ||
                      !amount.isFinite ||
                      amount <= 0) {
                    return 'Enter a valid amount greater than zero.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Category',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                    _loadingCategories ? null : _addCategory,
                    icon: const Icon(Icons.add_circle_outline, size: 19),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_loadingCategories)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _categories.contains(_category)
                      ? _category
                      : _categories.first,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                  validator: (value) =>
                  value == null ? 'Please select a category.' : null,
                ),
              const SizedBox(height: 22),
              Text('Date', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/'
                      '${_date.year}',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Note (Optional)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'What was this transaction for?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving || _loadingCategories
                      ? null
                      : _saveTransaction,
                  icon: _saving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : 'Save ${isIncome ? 'Income' : 'Expense'}',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isIncome
                        ? const Color(0xFF168568)
                        : colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
