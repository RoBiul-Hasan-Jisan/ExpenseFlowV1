import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/storage_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  DateTime _date = DateTime.now();
  File? _receiptFile;
  String? _existingReceiptUrl;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _categoryId = e.categoryId;
      _amountController.text = e.amount.toStringAsFixed(2);
      _titleController.text = e.title;
      _descriptionController.text = e.description ?? '';
      _tagsController.text = e.tags.join(', ');
      _date = e.date;
      _existingReceiptUrl = e.receiptUrl;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _receiptFile = File(picked.path));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a category')));
      return;
    }
    setState(() => _saving = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final tags = _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final now = DateTime.now();
    final session = ref.read(sessionProvider);

    // Receipts: authenticated users upload to the backend; demo mode
    // keeps the local file path only (never touches the network).
    var receiptUrl = _existingReceiptUrl;
    if (_receiptFile != null) {
      if (!session.isDemo && session.uid != null) {
        try {
          receiptUrl = await StorageService().uploadReceipt(
            uid: session.uid!,
            transactionId: widget.existing?.id ?? const Uuid().v4(),
            file: _receiptFile!,
          );
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt upload failed: $e')));
        }
      } else {
        receiptUrl = _receiptFile!.path;
      }
    }

    final txn = TransactionModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      type: _type,
      amount: amount,
      categoryId: _categoryId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      date: _date,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      tags: tags,
      receiptUrl: receiptUrl,
      isRecurring: widget.existing?.isRecurring ?? false,
      recurringId: widget.existing?.recurringId,
    );

    try {
      if (_isEditing) {
        await ref.read(transactionActionsProvider).update(txn);
      } else {
        await ref.read(transactionActionsProvider).add(txn);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Transaction updated' : 'Transaction saved')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(AppTheme.space(2.5.round()), AppTheme.space(2), AppTheme.space(2.5.round()), AppTheme.space(4)),
            children: [
              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: _TypeToggle(
                      label: 'Expense',
                      selected: _type == TransactionType.expense,
                      color: AppColors.expense,
                      onTap: () => setState(() {
                        _type = TransactionType.expense;
                        _categoryId = null;
                      }),
                    ),
                  ),
                  SizedBox(width: AppTheme.space(1.5.round())),
                  Expanded(
                    child: _TypeToggle(
                      label: 'Income',
                      selected: _type == TransactionType.income,
                      color: AppColors.income,
                      onTap: () => setState(() {
                        _type = TransactionType.income;
                        _categoryId = null;
                      }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.space(3)),

              Text('Amount', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(prefixText: '${CurrencyFormatter.symbolFor(settings.currency)} '),
                validator: (v) {
                  final val = double.tryParse((v ?? '').trim());
                  if (val == null) return 'Enter a valid amount';
                  if (val <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              SizedBox(height: AppTheme.space(2.5.round())),

              Text('Category', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load categories: $e'),
                data: (categories) {
                  final filtered = categories.where((c) => c.type == _type).toList();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in filtered)
                        ChoiceChip(
                          avatar: Icon(c.icon, size: 16, color: _categoryId == c.id ? Colors.white : c.color),
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          selectedColor: c.color,
                          labelStyle: TextStyle(color: _categoryId == c.id ? Colors.white : null, fontWeight: FontWeight.w600),
                          onSelected: (_) => setState(() => _categoryId = c.id),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: AppTheme.space(2.5.round())),

              Text('Title', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'e.g. Grocery shopping'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              SizedBox(height: AppTheme.space(2.5.round())),

              Text('Description', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: 'Optional'),
                maxLines: 2,
              ),
              SizedBox(height: AppTheme.space(2.5.round())),

              Text('Date', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(DateFormatter.monthDayYear(_date)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.space(2.5.round())),

              Text('Tags', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(hintText: 'Optional, comma-separated'),
              ),
              SizedBox(height: AppTheme.space(2.5.round())),

              Text('Receipt', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              if (_receiptFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Image.file(_receiptFile!, height: 140, width: double.infinity, fit: BoxFit.cover),
                )
              else if (_existingReceiptUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: _existingReceiptUrl!.startsWith('http')
                      ? Image.network(_existingReceiptUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(File(_existingReceiptUrl!), height: 140, width: double.infinity, fit: BoxFit.cover),
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickReceipt,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Add receipt'),
                ),
              SizedBox(height: AppTheme.space(4)),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Save Changes' : 'Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: AppTheme.space(1.75.round())),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? color : null, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
