import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_record.dart';
import 'new_purchase_record_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  CollectionReference get _purchaseRecordsRef {
    return FirebaseFirestore.instance.collection('purchase_records');
  }

  String _locationFilter = 'すべて';

  void _addPurchaseRecord(BuildContext context, [String? initialName]) async {
    final newRecord = await Navigator.of(context).push<PurchaseRecord>(
      MaterialPageRoute(
        builder: (ctx) => NewPurchaseRecordScreen(initialName: initialName),
      ),
    );

    if (newRecord == null) {
      return;
    }

    try {
      await _purchaseRecordsRef.add(newRecord.toFirestore());

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newRecord.name} を購買記録に追加しました。')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('購買記録の追加に失敗しました: $e')));
    }
  }

  void _deletePurchaseRecord(String recordId) async {
    try {
      await _purchaseRecordsRef.doc(recordId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('購買記録を削除しました。')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
    }
  }

  List<PurchaseRecord> _applyFilters(List<PurchaseRecord> records) {
    if (_locationFilter == 'すべて') {
      return records;
    }
    return records
        .where((record) => record.location == _locationFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '購買記録',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _purchaseRecordsRef
            .orderBy('purchaseDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }

          final records = snapshot.data!.docs
              .map(
                (doc) => PurchaseRecord.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          // 購入場所のリストを取得
          final locations = {'すべて', ...records.map((r) => r.location)};

          final filteredRecords = _applyFilters(records);

          return Column(
            children: [
              // フィルター
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text('購入場所: '),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: DropdownButton<String>(
                          value: _locationFilter,
                          isExpanded: true,
                          items: locations
                              .map(
                                (location) => DropdownMenuItem(
                                  value: location,
                                  child: Text(location),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _locationFilter = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 購買記録リスト
              Expanded(
                child: filteredRecords.isEmpty
                    ? const Center(child: Text('購買記録がありません'))
                    : ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(record.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '¥${record.price.toStringAsFixed(0)} × ${record.quantity}個 = ¥${(record.price * record.quantity).toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '場所: ${record.location}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '日時: ${record.purchaseDate.year}/${record.purchaseDate.month}/${record.purchaseDate.day} ${record.purchaseDate.hour.toString().padLeft(2, '0')}:${record.purchaseDate.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (record.notes != null &&
                                      record.notes!.isNotEmpty)
                                    Text(
                                      '備考: ${record.notes}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deletePurchaseRecord(record.id),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPurchaseRecord(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
