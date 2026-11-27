import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/transaction_entry.dart';
import 'download_helper.dart';

class ExcelExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Export an individual customer's transaction report as an Excel file
  static Future<void> exportSingleCustomer(Contact contact) async {
    final excel = Excel.createExcel();
    final String sheetName = _sanitizeSheetName(contact.name);

    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    final txns = contact.transactions.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time)); // Chronological order

    int totalGave = 0;
    int totalGot = 0;
    for (var t in txns) {
      if (t.amount > 0) {
        totalGave += t.amount;
      } else {
        totalGot += t.amount.abs();
      }
    }

    final netBalance = totalGave - totalGot;
    final status = netBalance > 0
        ? "You'll Get ₹${netBalance.abs()}"
        : (netBalance < 0 ? "You'll Give ₹${netBalance.abs()}" : "Settled (₹0)");

    // Title
    _addCell(sheet, 0, 0, 'POCKET KHATA - CUSTOMER TRANSACTION REPORT', bold: true);
    _addCell(sheet, 1, 0, 'Customer Name: ${contact.name}');
    _addCell(sheet, 2, 0, 'Export Date: ${_dateFormat.format(DateTime.now())}');
    _addCell(sheet, 3, 0, '');

    // Summary Card Box
    _addCell(sheet, 4, 0, 'SUMMARY STATEMENT', bold: true);
    _addCell(sheet, 5, 0, 'Total Entries:');
    _addCell(sheet, 5, 1, txns.length);
    _addCell(sheet, 6, 0, 'Total You Gave (Out):');
    _addCell(sheet, 6, 1, '₹$totalGave');
    _addCell(sheet, 7, 0, 'Total You Got (In):');
    _addCell(sheet, 7, 1, '₹$totalGot');
    _addCell(sheet, 8, 0, 'Net Balance:');
    _addCell(sheet, 8, 1, '₹${netBalance.abs()}');
    _addCell(sheet, 9, 0, 'Status:');
    _addCell(sheet, 9, 1, status);
    _addCell(sheet, 10, 0, '');

    // Transaction Table Headers
    final headers = [
      'S.No',
      'Date & Time',
      'Note / Particulars',
      'You Gave (Out / Debit) [₹]',
      'You Got (In / Credit) [₹]',
      'Running Balance [₹]',
      'Type'
    ];

    for (int col = 0; col < headers.length; col++) {
      _addCell(sheet, 11, col, headers[col], bold: true);
    }

    int runningBalance = 0;
    int rowIdx = 12;

    for (int i = 0; i < txns.length; i++) {
      final t = txns[i];
      final isGave = t.amount > 0;
      final gaveAmt = isGave ? t.amount : 0;
      final gotAmt = !isGave ? t.amount.abs() : 0;
      runningBalance += t.amount;

      _addCell(sheet, rowIdx, 0, i + 1);
      _addCell(sheet, rowIdx, 1, _dateFormat.format(t.time));
      _addCell(sheet, rowIdx, 2, t.note);
      _addCell(sheet, rowIdx, 3, gaveAmt);
      _addCell(sheet, rowIdx, 4, gotAmt);
      _addCell(sheet, rowIdx, 5, runningBalance);
      _addCell(sheet, rowIdx, 6, isGave ? 'YOU GAVE' : 'YOU GOT');
      rowIdx++;
    }

    // Totals Footer Row
    _addCell(sheet, rowIdx, 0, 'TOTALS', bold: true);
    _addCell(sheet, rowIdx, 1, '');
    _addCell(sheet, rowIdx, 2, '');
    _addCell(sheet, rowIdx, 3, totalGave, bold: true);
    _addCell(sheet, rowIdx, 4, totalGot, bold: true);
    _addCell(sheet, rowIdx, 5, runningBalance, bold: true);
    _addCell(sheet, rowIdx, 6, status, bold: true);

    final bytes = excel.save();
    if (bytes != null) {
      final fileName = '${_cleanFileName(contact.name)}_Khata_Statement.xlsx';
      await DownloadHelper.saveAndDownload(bytes, fileName);
    }
  }

  /// Export All Customers together in a single Master Excel Workbook
  static Future<void> exportAllCustomers(List<Contact> contacts) async {
    final excel = Excel.createExcel();

    // Sheet 1: Master Overall Summary
    const summarySheetName = 'Overall Summary';
    final summarySheet = excel[summarySheetName];
    excel.setDefaultSheet(summarySheetName);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    int overallGave = 0;
    int overallGot = 0;
    int totalEntriesCount = 0;

    for (var c in contacts) {
      totalEntriesCount += c.transactions.length;
      for (var t in c.transactions.values) {
        if (t.amount > 0) {
          overallGave += t.amount;
        } else {
          overallGot += t.amount.abs();
        }
      }
    }

    final overallNet = overallGave - overallGot;
    final overallStatus = overallNet > 0
        ? "Overall You'll Get ₹${overallNet.abs()}"
        : (overallNet < 0 ? "Overall You'll Give ₹${overallNet.abs()}" : "Overall Settled (₹0)");

    // Header Title
    _addCell(summarySheet, 0, 0, 'POCKET KHATA - MASTER CUSTOMERS SUMMARY REPORT', bold: true);
    _addCell(summarySheet, 1, 0, 'Export Date: ${_dateFormat.format(DateTime.now())}');
    _addCell(summarySheet, 2, 0, '');

    // Overall Metrics Box
    _addCell(summarySheet, 3, 0, 'OVERALL FINANCIAL METRICS', bold: true);
    _addCell(summarySheet, 4, 0, 'Total Customers:');
    _addCell(summarySheet, 4, 1, contacts.length);
    _addCell(summarySheet, 5, 0, 'Total Entries:');
    _addCell(summarySheet, 5, 1, totalEntriesCount);
    _addCell(summarySheet, 6, 0, 'Total You Gave (Out):');
    _addCell(summarySheet, 6, 1, '₹$overallGave');
    _addCell(summarySheet, 7, 0, 'Total You Got (In):');
    _addCell(summarySheet, 7, 1, '₹$overallGot');
    _addCell(summarySheet, 8, 0, 'Overall Net Position:');
    _addCell(summarySheet, 8, 1, overallStatus);
    _addCell(summarySheet, 9, 0, '');

    // Summary Table Headers
    final summaryHeaders = [
      'S.No',
      'Customer Name',
      'Total You Gave (Out) [₹]',
      'Total You Got (In) [₹]',
      'Net Balance [₹]',
      'Status',
      'Total Entries'
    ];

    for (int col = 0; col < summaryHeaders.length; col++) {
      _addCell(summarySheet, 10, col, summaryHeaders[col], bold: true);
    }

    int rowIdx = 11;
    for (int i = 0; i < contacts.length; i++) {
      final c = contacts[i];
      int cGave = 0;
      int cGot = 0;
      for (var t in c.transactions.values) {
        if (t.amount > 0) {
          cGave += t.amount;
        } else {
          cGot += t.amount.abs();
        }
      }
      final cNet = cGave - cGot;
      final cStatus = cNet > 0
          ? "You'll Get ₹${cNet.abs()}"
          : (cNet < 0 ? "You'll Give ₹${cNet.abs()}" : "Settled");

      _addCell(summarySheet, rowIdx, 0, i + 1);
      _addCell(summarySheet, rowIdx, 1, c.name);
      _addCell(summarySheet, rowIdx, 2, cGave);
      _addCell(summarySheet, rowIdx, 3, cGot);
      _addCell(summarySheet, rowIdx, 4, cNet);
      _addCell(summarySheet, rowIdx, 5, cStatus);
      _addCell(summarySheet, rowIdx, 6, c.transactions.length);
      rowIdx++;
    }

    // Grand Totals Row
    _addCell(summarySheet, rowIdx, 0, 'GRAND TOTAL', bold: true);
    _addCell(summarySheet, rowIdx, 1, '');
    _addCell(summarySheet, rowIdx, 2, overallGave, bold: true);
    _addCell(summarySheet, rowIdx, 3, overallGot, bold: true);
    _addCell(summarySheet, rowIdx, 4, overallNet, bold: true);
    _addCell(summarySheet, rowIdx, 5, overallStatus, bold: true);
    _addCell(summarySheet, rowIdx, 6, totalEntriesCount, bold: true);

    // Create Individual Sheets for Each Customer
    final Set<String> usedSheetNames = {summarySheetName};

    for (var c in contacts) {
      String customerSheetName = _sanitizeSheetName(c.name);
      int dupCount = 1;
      while (usedSheetNames.contains(customerSheetName)) {
        customerSheetName = '${_sanitizeSheetName(c.name)}_$dupCount';
        dupCount++;
      }
      usedSheetNames.add(customerSheetName);

      final cSheet = excel[customerSheetName];
      _populateIndividualCustomerSheet(cSheet, c);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await DownloadHelper.saveAndDownload(bytes, 'PocketKhata_Master_Report.xlsx');
    }
  }

  static void _populateIndividualCustomerSheet(Sheet sheet, Contact contact) {
    final txns = contact.transactions.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    int totalGave = 0;
    int totalGot = 0;
    for (var t in txns) {
      if (t.amount > 0) {
        totalGave += t.amount;
      } else {
        totalGot += t.amount.abs();
      }
    }

    final netBalance = totalGave - totalGot;
    final status = netBalance > 0
        ? "You'll Get ₹${netBalance.abs()}"
        : (netBalance < 0 ? "You'll Give ₹${netBalance.abs()}" : "Settled (₹0)");

    _addCell(sheet, 0, 0, 'CUSTOMER STATEMENT - ${contact.name.toUpperCase()}', bold: true);
    _addCell(sheet, 1, 0, 'Export Date: ${_dateFormat.format(DateTime.now())}');
    _addCell(sheet, 2, 0, '');

    _addCell(sheet, 3, 0, 'Total Entries: ${txns.length}');
    _addCell(sheet, 4, 0, 'Total You Gave: ₹$totalGave | Total You Got: ₹$totalGot');
    _addCell(sheet, 5, 0, 'Net Balance: ₹${netBalance.abs()} ($status)', bold: true);
    _addCell(sheet, 6, 0, '');

    final headers = [
      'S.No',
      'Date & Time',
      'Note / Particulars',
      'You Gave (Out) [₹]',
      'You Got (In) [₹]',
      'Running Balance [₹]',
      'Type'
    ];

    for (int col = 0; col < headers.length; col++) {
      _addCell(sheet, 7, col, headers[col], bold: true);
    }

    int runningBalance = 0;
    int rowIdx = 8;

    for (int i = 0; i < txns.length; i++) {
      final t = txns[i];
      final isGave = t.amount > 0;
      final gaveAmt = isGave ? t.amount : 0;
      final gotAmt = !isGave ? t.amount.abs() : 0;
      runningBalance += t.amount;

      _addCell(sheet, rowIdx, 0, i + 1);
      _addCell(sheet, rowIdx, 1, _dateFormat.format(t.time));
      _addCell(sheet, rowIdx, 2, t.note);
      _addCell(sheet, rowIdx, 3, gaveAmt);
      _addCell(sheet, rowIdx, 4, gotAmt);
      _addCell(sheet, rowIdx, 5, runningBalance);
      _addCell(sheet, rowIdx, 6, isGave ? 'YOU GAVE' : 'YOU GOT');
      rowIdx++;
    }

    _addCell(sheet, rowIdx, 0, 'TOTALS', bold: true);
    _addCell(sheet, rowIdx, 1, '');
    _addCell(sheet, rowIdx, 2, '');
    _addCell(sheet, rowIdx, 3, totalGave, bold: true);
    _addCell(sheet, rowIdx, 4, totalGot, bold: true);
    _addCell(sheet, rowIdx, 5, runningBalance, bold: true);
    _addCell(sheet, rowIdx, 6, status, bold: true);
  }

  static void _addCell(Sheet sheet, int row, int col, dynamic value, {bool bold = false}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else {
      cell.value = TextCellValue(value.toString());
    }

    if (bold) {
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
      );
    }
  }

  static String _sanitizeSheetName(String name) {
    String clean = name.replaceAll(RegExp(r'[\\/*?:\[\]]'), '_').trim();
    if (clean.length > 28) {
      clean = clean.substring(0, 28);
    }
    return clean.isEmpty ? 'Customer' : clean;
  }

  static String _cleanFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_').trim();
  }
}
