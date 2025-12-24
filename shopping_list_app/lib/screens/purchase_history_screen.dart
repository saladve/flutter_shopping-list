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
  final CollectionReference _purchaseRecordsRef = FirebaseFirestore.instance
      .collection('purchase_records');
  String _locationFilter = 'すべて';

  Future<void> _deleteRecord(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: const Text('この記録を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _purchaseRecordsRef.doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '購買記録',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _purchaseRecordsRef
            .orderBy('purchaseDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('エラー: ${snapshot.error}'));

          final records = snapshot.data!.docs
              .map(
                (doc) => PurchaseRecord.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          final locations = {'すべて', ...records.map((r) => r.location)};
          final filtered = _locationFilter == 'すべて'
              ? records
              : records.where((r) => r.location == _locationFilter).toList();

          return Column(
            children: [
              _buildFilterBar(locations.toList()..sort()),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('記録がありません'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _buildHistoryCard(filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewPurchaseRecordScreen()),
        ),
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Widget _buildFilterBar(List<String> locations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSmallDropdown(
              '場所で絞り込む',
              _locationFilter,
              locations,
              (v) => setState(() => _locationFilter = v!),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            icon: const Icon(Icons.restart_alt, size: 22, color: Colors.grey),
            onPressed: () => setState(() => _locationFilter = 'すべて'),
            tooltip: 'リセット',
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      height: 40, // 高さを抑えてコンパクトに
      child: DropdownButtonFormField<String>(
        value: value,
        items: options
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 0,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
      ),
    );
  }

  // リストのカード表示
  Widget _buildHistoryCard(PurchaseRecord record) {
    final totalPrice = record.price * record.quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥${record.price.toStringAsFixed(0)} × ${record.quantity} = ¥${totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 14, color: Colors.grey),
                      Text(
                        ' ${record.location} ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      Text(
                        ' ${record.purchaseDate.year}/${record.purchaseDate.month}/${record.purchaseDate.day}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (record.notes?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '備考: ${record.notes}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteRecord(record.id),
            ),
          ],
        ),
      ),
    );
  }
}
