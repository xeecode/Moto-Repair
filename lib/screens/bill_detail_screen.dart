import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/db_helper.dart';
import '../models/bill.dart';
import '../services/settings_service.dart';

class BillDetailScreen extends StatefulWidget {
  final Bill bill;
  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  List<BillItem> _items = [];
  bool _generatingPdf = false;
  ShopSettings _settings = ShopSettings();
  late NumberFormat _currency;
  final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');
    _loadItems();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    setState(() {
      _settings = settings;
      _currency =
          NumberFormat.currency(locale: 'en_PK', symbol: settings.currencySymbol);
    });
  }

  Future<void> _loadItems() async {
    if (widget.bill.items.isNotEmpty) {
      setState(() => _items = widget.bill.items);
      return;
    }
    final items = await DBHelper.instance.getBillItems(widget.bill.id!);
    setState(() => _items = items);
  }

  Future<void> _shareBillAsPdf() async {
    setState(() => _generatingPdf = true);
    try {
      final bill = widget.bill;
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(_settings.shopName,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                if (_settings.shopAddress.isNotEmpty)
                  pw.Text(_settings.shopAddress,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                if (_settings.shopPhone.isNotEmpty)
                  pw.Text('Phone: ${_settings.shopPhone}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text('Invoice #${bill.id}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.Divider(),
                pw.SizedBox(height: 6),
                pw.Text('Customer: ${bill.customerName}'),
                if (bill.customerPhone.isNotEmpty)
                  pw.Text('Phone: ${bill.customerPhone}'),
                if (bill.vehicleNumber.isNotEmpty)
                  pw.Text(
                      'Vehicle: ${bill.vehicleNumber}${bill.vehicleModel.isNotEmpty ? ' (${bill.vehicleModel})' : ''}'),
                pw.Text('Date: ${_dateFmt.format(bill.createdAt)}'),
                pw.SizedBox(height: 14),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.4),
                    3: const pw.FlexColumnWidth(1.4),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _pdfCell('Part', bold: true),
                        _pdfCell('Qty', bold: true),
                        _pdfCell('Price', bold: true),
                        _pdfCell('Total', bold: true),
                      ],
                    ),
                    ..._items.map((item) => pw.TableRow(children: [
                          _pdfCell(item.productName),
                          _pdfCell('${item.quantity}'),
                          _pdfCell(_currency.format(item.price)),
                          _pdfCell(_currency.format(item.total)),
                        ])),
                  ],
                ),
                pw.SizedBox(height: 14),
                _pdfSummaryRow('Parts Subtotal', _currency.format(bill.totalAmount)),
                _pdfSummaryRow('Labour Charges', _currency.format(bill.labourCost)),
                _pdfSummaryRow('Discount', '- ${_currency.format(bill.discount)}'),
                pw.Divider(),
                _pdfSummaryRow('Grand Total', _currency.format(bill.grandTotal), bold: true),
                pw.SizedBox(height: 24),
                pw.Text(_settings.invoiceFooter,
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              ],
            );
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
          bytes: bytes, filename: 'invoice_${bill.id}.pdf');
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  pw.Widget _pdfSummaryRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: bold ? 13 : 11,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: bold ? 13 : 11,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return Scaffold(
      appBar: AppBar(title: Text('Bill #${bill.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(_settings.shopName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text('#${bill.id}',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    if (_settings.shopAddress.isNotEmpty)
                      Text(_settings.shopAddress,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                    if (_settings.shopPhone.isNotEmpty)
                      Text('Phone: ${_settings.shopPhone}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                    const Divider(),
                    Text('Customer: ${bill.customerName}'),
                    if (bill.customerPhone.isNotEmpty)
                      Text('Phone: ${bill.customerPhone}'),
                    if (bill.vehicleNumber.isNotEmpty)
                      Text(
                          'Vehicle: ${bill.vehicleNumber}${bill.vehicleModel.isNotEmpty ? ' (${bill.vehicleModel})' : ''}'),
                    Text('Date: ${_dateFmt.format(bill.createdAt)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName),
                    subtitle: Text(
                        '${_currency.format(item.price)} x ${item.quantity}'),
                    trailing: Text(_currency.format(item.total),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Parts Subtotal'),
                Text(_currency.format(bill.totalAmount)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Labour Charges'),
                Text(_currency.format(bill.labourCost)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount'),
                Text('- ${_currency.format(bill.discount)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(_currency.format(bill.grandTotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _generatingPdf ? null : _shareBillAsPdf,
                icon: _generatingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.share),
                label: Text(_generatingPdf
                    ? 'Preparing PDF...'
                    : 'Share Bill as PDF (WhatsApp/Print)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
