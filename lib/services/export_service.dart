import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Generates CSV and PDF exports for transaction history and monthly
/// reports. Files are written to the app documents directory and can
/// be shared via the OS share sheet (see printing package for PDFs).
class ExportService {
  Future<File> exportTransactionsCsv(List<TransactionModel> transactions, List<CategoryModel> categories) async {
    final categoryNames = {for (final c in categories) c.id: c.name};
    final rows = <List<dynamic>>[
      ['Date', 'Type', 'Category', 'Title', 'Amount', 'Description', 'Tags'],
      ...transactions.map((t) => [
            DateFormatter.monthDayYear(t.date),
            t.type.name,
            categoryNames[t.categoryId] ?? 'Other',
            t.title,
            t.amount.toStringAsFixed(2),
            t.description ?? '',
            t.tags.join('; '),
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expenseflow_transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
    return file.writeAsString(csv);
  }

  Future<File> exportMonthlyReportPdf({
    required String currency,
    required DateTime monthStart,
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryBreakdown,
    required List<TransactionModel> topExpenses,
    required List<CategoryModel> categories,
  }) async {
    final categoryNames = {for (final c in categories) c.id: c.name};
    final doc = pw.Document();
    final net = totalIncome - totalExpenses;
    final savingsRate = totalIncome <= 0 ? 0 : (net / totalIncome * 100);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('ExpenseFlow — Monthly Report', style: const pw.TextStyle(fontSize: 22))),
          pw.Text(DateFormatter.fullMonth(monthStart), style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _summaryBlock('Income', CurrencyFormatter.format(totalIncome, currency)),
            _summaryBlock('Expenses', CurrencyFormatter.format(totalExpenses, currency)),
            _summaryBlock('Net Savings', CurrencyFormatter.format(net, currency)),
            _summaryBlock('Savings Rate', '${savingsRate.toStringAsFixed(1)}%'),
          ]),
          pw.SizedBox(height: 20),
          pw.Text('Category Breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Category', 'Amount', '% of Expenses'],
            data: categoryBreakdown.entries.map((e) {
              final pct = totalExpenses <= 0 ? 0 : (e.value / totalExpenses * 100);
              return [categoryNames[e.key] ?? 'Other', CurrencyFormatter.format(e.value, currency), '${pct.toStringAsFixed(1)}%'];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Top Expenses', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Amount'],
            data: topExpenses.map((t) => [
                  DateFormatter.monthDay(t.date),
                  t.title,
                  categoryNames[t.categoryId] ?? 'Other',
                  CurrencyFormatter.format(t.amount, currency),
                ]).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expenseflow_report_${monthStart.year}_${monthStart.month}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> shareFile(File file) => Printing.sharePdf(bytes: file.readAsBytesSync(), filename: file.uri.pathSegments.last);

  static pw.Widget _summaryBlock(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      );
}
