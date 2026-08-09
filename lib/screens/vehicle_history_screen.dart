import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/bill.dart';
import 'bill_detail_screen.dart';

class VehicleHistoryScreen extends StatefulWidget {
  const VehicleHistoryScreen({super.key});

  @override
  State<VehicleHistoryScreen> createState() => _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState extends State<VehicleHistoryScreen> {
  final _searchCtrl = TextEditingController();
  List<Bill> _results = [];
  bool _searched = false;
  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');
  final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    final bills = await DBHelper.instance.getBillsByVehicleNumber(query.trim());
    setState(() {
      _results = bills;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Service History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Enter bike number (e.g. LEA-1234)...',
                prefixIcon: const Icon(Icons.two_wheeler),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: !_searched
                ? const Center(
                    child: Text(
                        'Search a bike number to see its\nfull service & repair history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54)))
                : _results.isEmpty
                    ? const Center(child: Text('No service records found for this bike.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) {
                          final bill = _results[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.build_circle)),
                              title: Text(
                                  '${bill.vehicleNumber}${bill.vehicleModel.isNotEmpty ? ' · ${bill.vehicleModel}' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${bill.customerName}\n${_dateFmt.format(bill.createdAt)}'),
                              isThreeLine: true,
                              trailing: Text(_currency.format(bill.grandTotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => BillDetailScreen(bill: bill)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
