import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // I should add this if not present
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class ReportService {
  static Future<void> generatePdfReport(List<TransactionModel> transactions) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('FinSight Wealth Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Amount', 'Type'],
            data: transactions.map((t) => [
              dateFormat.format(t.date),
              t.title,
              t.category,
              '₹${t.amount.toStringAsFixed(2)}',
              t.isExpense ? 'Expense' : 'Income'
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'FinSight_Report.pdf');
  }

  static Future<void> generateCsvReport(List<TransactionModel> transactions) async {
    final dateFormat = DateFormat('dd MMM yyyy');
    List<List<dynamic>> rows = [
      ['Date', 'Title', 'Category', 'Amount', 'Type'],
    ];

    for (var t in transactions) {
      rows.add([
        dateFormat.format(t.date),
        t.title,
        t.category,
        t.amount,
        t.isExpense ? 'Expense' : 'Income'
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/FinSight_Report.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(path)], text: 'FinSight Transaction Report');
  }
}
