import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/bill.dart';
import 'bill_detail_screen.dart';

enum _DateFilter { all, today, yesterday, thisWeek, thisMonth, custom }

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  List<Bill> _allBills = [];
  List<Bill> _filteredBills = [];
  _DateFilter _activeFilter = _DateFilter.all;
  DateTime? _customDate;

  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');
  final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
  final _dateHeaderFmt = DateFormat('EEEE, dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    final bills = await DBHelper.instance.getAllBills();
    setState(() {
      _allBills = bills;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    switch (_activeFilter) {
      case _DateFilter.all:
        _filteredBills = _allBills;
        break;
      case _DateFilter.today:
        _filteredBills =
            _allBills.where((b) => isSameDay(b.createdAt, now)).toList();
        break;
      case _DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        _filteredBills =
            _allBills.where((b) => isSameDay(b.createdAt, yesterday)).toList();
        break;
      case _DateFilter.thisWeek:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        _filteredBills = _allBills
            .where((b) => !b.createdAt.isBefore(startOfWeek))
            .toList();
        break;
      case _DateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        _filteredBills = _allBills
            .where((b) => !b.createdAt.isBefore(startOfMonth))
            .toList();
        break;
      case _DateFilter.custom:
        if (_customDate != null) {
          _filteredBills = _allBills
              .where((b) => isSameDay(b.createdAt, _customDate!))
              .toList();
        } else {
          _filteredBills = _allBills;
        }
        break;
    }
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _customDate = picked;
        _activeFilter = _DateFilter.custom;
        _applyFilter();
      });
    }
  }

  void _selectFilter(_DateFilter filter) {
    setState(() {
      _activeFilter = filter;
      if (filter != _DateFilter.custom) _customDate = null;
      _applyFilter();
    });
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text(
            'Delete this bill? Stock quantities will be restored to inventory.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && bill.id != null) {
      await DBHelper.instance.deleteBill(bill.id!);
      _loadBills();
    }
  }

  String _chipLabel(_DateFilter f) {
    switch (f) {
      case _DateFilter.all:
        return 'All';
      case _DateFilter.today:
        return 'Today';
      case _DateFilter.yesterday:
        return 'Yesterday';
      case _DateFilter.thisWeek:
        return 'This Week';
      case _DateFilter.thisMonth:
        return 'This Month';
      case _DateFilter.custom:
        return _customDate != null
            ? DateFormat('dd MMM').format(_customDate!)
            : 'Pick Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue =
        _filteredBills.fold<double>(0, (sum, b) => sum + b.grandTotal);

    // Group bills by day for clear date-wise headers
    final Map<String, List<Bill>> grouped = {};
    for (final bill in _filteredBills) {
      final key = _dateHeaderFmt.format(bill.createdAt);
      grouped.putIfAbsent(key, () => []).add(bill);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Pick a specific date',
            onPressed: _pickCustomDate,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _DateFilter.all,
                _DateFilter.today,
                _DateFilter.yesterday,
                _DateFilter.thisWeek,
                _DateFilter.thisMonth,
                if (_customDate != null) _DateFilter.custom,
              ].map((f) {
                final selected = _activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_chipLabel(f)),
                    selected: selected,
                    onSelected: (_) => f == _DateFilter.custom
                        ? _pickCustomDate()
                        : _selectFilter(f),
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: selected
                              ? AppColors.accent
                              : Colors.grey.shade300),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_filteredBills.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_filteredBills.length} bill${_filteredBills.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(_currency.format(totalRevenue),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          Expanded(
            child: _filteredBills.isEmpty
                ? Center(
                    child: Text(
                      _allBills.isEmpty
                          ? 'No bills generated yet.'
                          : 'No bills found for this period.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 6, left: 2),
                            child: Text(entry.key,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600)),
                          ),
                          ...entry.value.map((bill) => Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.accent.withOpacity(0.15),
                                    child: const Icon(Icons.receipt, color: AppColors.accent),
                                  ),
                                  title: Text(bill.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(_dateFmt.format(bill.createdAt)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_currency.format(bill.grandTotal),
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      GestureDetector(
                                        onTap: () => _deleteBill(bill),
                                        child: const Icon(Icons.delete_outline,
                                            size: 18, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => BillDetailScreen(bill: bill)),
                                    );
                                  },
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
