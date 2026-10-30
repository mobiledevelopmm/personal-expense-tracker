import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/transaction.dart';
import '../../../data/services/category_service.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../notification/notification_cubit.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;
  final ExpenseTransaction? transaction;

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.transaction,
  });

  bool get isEditing => transaction != null;

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final CategoryService _categoryService = CategoryService();

  late TransactionType _type;
  late DateTime _date;

  bool _saving = false;
  bool _loadingCategories = true;

  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];

  String? _category;

  List<String> get _categories => _type == TransactionType.income
      ? _incomeCategories
      : _expenseCategories;

  @override
  void initState() {
    super.initState();
    final existing = widget.transaction;
    _type = existing?.type ?? widget.initialType;
    _date = existing?.date ?? DateTime.now();
    _category = existing?.category;

    if (existing != null) {
      _amountController.text = existing.amount.toString();
      _noteController.text = existing.note;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      await _categoryService.initializeDefaultCategories();

      final results = await Future.wait([
        _categoryService.getCategories('income'),
        _categoryService.getCategories('expense'),
      ]);

      var incomeCategories = results[0];
      var expenseCategories = results[1];

      final existingCategory = _category;
      if (existingCategory != null && existingCategory.trim().isNotEmpty) {
        final currentList = _type == TransactionType.income
            ? incomeCategories
            : expenseCategories;
        final exists = currentList.any(
              (item) => item.toLowerCase() == existingCategory.toLowerCase(),
        );

        if (!exists) {
          await _categoryService.addCategory(
            name: existingCategory,
            type: _type == TransactionType.income ? 'income' : 'expense',
          );
          final refreshed = await _categoryService.getCategories(
            _type == TransactionType.income ? 'income' : 'expense',
          );
          if (_type == TransactionType.income) {
            incomeCategories = refreshed;
          } else {
            expenseCategories = refreshed;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _incomeCategories = incomeCategories;
        _expenseCategories = expenseCategories;
        _category ??= _categories.isNotEmpty ? _categories.first : null;
        if (_category != null && !_categories.contains(_category)) {
          _category = _categories.isNotEmpty ? _categories.first : null;
        }
        _loadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load categories: $error')),
      );
    }
  }

  Future<void> _addCategory() async {
    String enteredName = '';

    final newCategory = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
          onChanged: (value) => enteredName = value,
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isNotEmpty) Navigator.pop(dialogContext, name);
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
              if (name.isNotEmpty) Navigator.pop(dialogContext, name);
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );

    if (!mounted || newCategory == null) return;
    final name = newCategory.trim();
    if (name.isEmpty) return;

    final duplicate = _categories.any(
          (category) => category.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This category already exists.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _categoryService.addCategory(
        name: name,
        type: _type == TransactionType.income ? 'income' : 'expense',
      );
      final updatedCategories = await _categoryService.getCategories(
        _type == TransactionType.income ? 'income' : 'expense',
      );

      if (!mounted) return;
      setState(() {
        if (_type == TransactionType.income) {
          _incomeCategories = updatedCategories;
        } else {
          _expenseCategories = updatedCategories;
        }
        _category = name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category saved successfully!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save category: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _saveTransaction() async {
    if (_loadingCategories || _saving) return;
    if (!_formKey.currentState!.validate()) return;

    final category = _category;
    if (category == null) return;

    setState(() => _saving = true);
    try {
      final existing = widget.transaction;
      final updatedTransaction = ExpenseTransaction(
        id: existing?.id ?? '',
        type: _type,
        amount: double.parse(_amountController.text.trim()),
        category: category,
        date: _date,
        note: _noteController.text.trim(),
      );

      final cubit = context.read<TransactionCubit>();
      if (existing != null) {
        await cubit.updateTransaction(existing.id, updatedTransaction);
      } else {
        await cubit.addTransaction(updatedTransaction);
        if (!mounted) return;

        final notificationCubit = context.read<NotificationCubit>();
        final isIncome = _type == TransactionType.income;
        await notificationCubit.addNotification(
          title: isIncome ? 'Income Added' : 'Expense Added',
          message:
          '${isIncome ? 'Income' : 'Expense'} of '
              '\$${updatedTransaction.amount.toStringAsFixed(2)} '
              'in $category was saved successfully.',
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not ${widget.isEditing ? 'update' : 'save'} '
                'transaction: $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isIncome = _type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
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
                    _category = _categories.isNotEmpty ? _categories.first : null;
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
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || !amount.isFinite || amount <= 0) {
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
                    _loadingCategories || _saving ? null : _addCategory,
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
              else if (_categories.isEmpty)
                const Text('No categories available.')
              else
                DropdownButtonFormField<String>(
                  key: ValueKey('$_type-$_category'),
                  initialValue: _categories.contains(_category)
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
                    if (value != null) setState(() => _category = value);
                  },
                  validator: (value) => value == null
                      ? 'Please select a category.'
                      : null,
                ),
              const SizedBox(height: 22),
              Text('Date', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(_formatDate(_date)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 22),
              Text('Note (Optional)', style: theme.textTheme.titleMedium),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : widget.isEditing
                        ? 'Update Transaction'
                        : 'Save ${isIncome ? 'Income' : 'Expense'}',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    isIncome ? const Color(0xFF168568) : colors.primary,
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