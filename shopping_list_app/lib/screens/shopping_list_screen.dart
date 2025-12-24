import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_item.dart';
import '../models/purchase_record.dart';
import '../screens/new_item_screen.dart';
import '../screens/new_purchase_record_screen.dart';

enum SortKey { created, due }

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _categoryFilter = 'すべて';
  String _locationFilter = 'すべて';
  SortKey _sortKey = SortKey.created;
  bool _isDescending = true;

  CollectionReference get _shoppingListRef =>
      _firestore.collection('shopping_list');

  // --- Logic Methods ---

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: const Text('このアイテムを削除してもよろしいですか？'),
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
      try {
        await _shoppingListRef.doc(itemId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('アイテムを削除しました')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
      }
    }
  }

  Future<void> _toggleCompletion(String itemId, ShoppingItem item) async {
    if (!item.isCompleted) {
      final shouldAdd = await _showConfirmDialog(item.name);
      if (shouldAdd == true) {
        await _handleMoveToHistory(itemId, item);
        return;
      }
    }

    await _shoppingListRef.doc(itemId).update({
      'isCompleted': !item.isCompleted,
    });
  }

  Future<bool?> _showConfirmDialog(String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購買記録に追加'),
        content: Text('$itemName を購買記録に追加しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('追加しない'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('追加する'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMoveToHistory(String itemId, ShoppingItem item) async {
    final newRecord = await Navigator.of(context).push<PurchaseRecord>(
      MaterialPageRoute(
        builder: (ctx) => NewPurchaseRecordScreen(
          initialName: item.name,
          initialCategory: item.category,
        ),
      ),
    );

    if (newRecord == null) return;

    try {
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('purchase_records').doc(),
        newRecord.toFirestore(),
      );
      batch.delete(_shoppingListRef.doc(itemId));
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newRecord.name} を記録し、リストから削除しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<ShoppingItem>(
      MaterialPageRoute(builder: (ctx) => const NewItemScreen()),
    );
    if (newItem == null) return;

    await _shoppingListRef.add(newItem.toFirestore());
  }

  List<ShoppingItem> _getFilteredItems(List<ShoppingItem> items) {
    var filtered = items.where((item) {
      final matchCat =
          _categoryFilter == 'すべて' || item.category == _categoryFilter;
      final matchLoc =
          _locationFilter == 'すべて' || item.location == _locationFilter;
      return matchCat && matchLoc;
    }).toList();

    if (_sortKey == SortKey.due) {
      filtered.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return _isDescending ? filtered.reversed.toList() : filtered;
    }

    // Default: CreatedAt sort (StreamBuilder already orders by createdAt descending)
    return _isDescending ? filtered : filtered.reversed.toList();
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '買い物リスト',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _shoppingListRef
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs
              .map(
                (doc) => ShoppingItem.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          final categories = {
            'すべて',
            ...items.map((e) => e.category ?? '').where((e) => e.isNotEmpty),
          };
          final locations = {
            'すべて',
            ...items.map((e) => e.location ?? '').where((e) => e.isNotEmpty),
          };
          final displayItems = _getFilteredItems(items);

          return Column(
            children: [
              _buildFilterBar(
                categories.toList()..sort(),
                locations.toList()..sort(),
              ),
              Expanded(
                child: displayItems.isEmpty
                    ? const Center(child: Text('アイテムがありません'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) =>
                            _buildItemCard(displayItems[index]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        label: const Text('追加'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar(List<String> categories, List<String> locations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _buildSmallDropdown(
              'カテゴリ',
              _categoryFilter,
              categories,
              (v) => setState(() => _categoryFilter = v!),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: _buildSmallDropdown(
              '場所',
              _locationFilter,
              locations,
              (v) => setState(() => _locationFilter = v!),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            icon: Icon(
              _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 20,
            ),
            onPressed: () => setState(() => _isDescending = !_isDescending),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            icon: const Icon(Icons.restart_alt, size: 20),
            onPressed: () => setState(() {
              _categoryFilter = 'すべて';
              _locationFilter = 'すべて';
              _isDescending = true;
            }),
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

  // カード表示
  Widget _buildItemCard(ShoppingItem item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 左側：チェックボックス
            Checkbox(
              value: item.isCompleted,
              onChanged: (_) => _toggleCompletion(item.id, item),
            ),
            const SizedBox(width: 8),

            // 中央：アイテム詳細情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isCompleted ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // カテゴリと個数
                  Row(
                    children: [
                      if (item.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '個数: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 場所と期限
                  Row(
                    children: [
                      if (item.location != null &&
                          item.location!.isNotEmpty) ...[
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        Text(
                          ' ${item.location} ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (item.dueDate != null) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: item.isCompleted
                              ? Colors.grey
                              : Colors.redAccent,
                        ),
                        Text(
                          ' ${item.dueDate!.year}/${item.dueDate!.month}/${item.dueDate!.day}',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isCompleted
                                ? Colors.grey
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteItem(item.id),
            ),
          ],
        ),
      ),
    );
  }
}
