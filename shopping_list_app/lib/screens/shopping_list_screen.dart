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
  CollectionReference get _shoppingListRef {
    return FirebaseFirestore.instance.collection('shopping_list');
  }

  String _categoryFilter = 'すべて';
  String _locationFilter = 'すべて';
  SortKey _sortKey = SortKey.created;
  bool _isDescending = true;

  void _toggleCompletion(
    String itemId,
    bool isCurrentlyCompleted,
    ShoppingItem item,
  ) async {
    if (!isCurrentlyCompleted) {
      // チェックを入れる際に確認ダイアログを表示
      final shouldAddToPurchaseHistory = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('購買記録に追加'),
          content: Text('${item.name} を購買記録に追加しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('追加しない'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('追加する'),
            ),
          ],
        ),
      );

      if (shouldAddToPurchaseHistory == true) {
        // 購買記録追加画面を開く（初期値として商品名とカテゴリを設定）
        final newRecord = await Navigator.of(context).push<PurchaseRecord>(
          MaterialPageRoute(
            builder: (ctx) => NewPurchaseRecordScreen(
              initialName: item.name,
              initialCategory: item.category,
            ),
          ),
        );

        if (newRecord != null) {
          try {
            await FirebaseFirestore.instance
                .collection('purchase_records')
                .add(newRecord.toFirestore());

            // 購買記録に追加されたアイテムをリストから削除
            await _shoppingListRef.doc(itemId).delete();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${newRecord.name} を購買記録に追加し、リストから削除しました。'),
              ),
            );
            return; // 削除したのでチェック状態の更新は不要
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('購買記録の追加に失敗しました: $e')));
          }
        }
      }
    }

    // 購買記録に追加されなかった場合のみチェック状態を更新
    await _shoppingListRef.doc(itemId).update({
      'isCompleted': !isCurrentlyCompleted,
    });
  }

  void _addItem(BuildContext context) async {
    final newItem = await Navigator.of(context).push<ShoppingItem>(
      MaterialPageRoute(builder: (ctx) => const NewItemScreen()),
    );

    if (newItem == null) {
      return;
    }

    try {
      await _shoppingListRef.add(newItem.toFirestore());

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${newItem.name} をリストに追加しました。')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('アイテムの追加に失敗しました: $e')));
    }
  }

  List<ShoppingItem> _applyFiltersAndSort(List<ShoppingItem> items) {
    // フィルター
    final filtered = items.where((item) {
      if (_categoryFilter != 'すべて' &&
          (item.category ?? '') != _categoryFilter) {
        return false;
      }
      if (_locationFilter != 'すべて' &&
          (item.location ?? '') != _locationFilter) {
        return false;
      }
      return true;
    }).toList();

    if (_sortKey == SortKey.due) {
      filtered.sort((a, b) {
        final aNull = a.dueDate == null;
        final bNull = b.dueDate == null;
        if (aNull && bNull) return 0;
        if (aNull) return 1;
        if (bNull) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      if (_isDescending) {
        return filtered.reversed.toList();
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '買い物メモアプリ',
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
        stream: _shoppingListRef
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('データの読み込みエラー: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loadedItems = snapshot.data!.docs.map((doc) {
            return ShoppingItem.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          final categories = <String>{'すべて'};
          final locations = <String>{'すべて'};
          for (final it in loadedItems) {
            if (it.category != null && it.category!.isNotEmpty) {
              categories.add(it.category!);
            }
            if (it.location != null && it.location!.isNotEmpty) {
              locations.add(it.location!);
            }
          }
          final categoryOptions = categories.toList()..sort();
          final locationOptions = locations.toList()..sort();

          var displayItems = _applyFiltersAndSort(loadedItems);

          if (_sortKey == SortKey.created && !_isDescending) {
            displayItems = displayItems.reversed.toList();
          }

          if (displayItems.isEmpty) {
            return Column(
              children: [
                _buildFilterBar(categoryOptions, locationOptions),
                const Expanded(child: Center(child: Text('該当するアイテムはありません。'))),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterBar(categoryOptions, locationOptions),
              Expanded(
                child: ListView.builder(
                  itemCount: displayItems.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final item = displayItems[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: item.isCompleted,
                              onChanged: (bool? newValue) {
                                _toggleCompletion(
                                  item.id,
                                  item.isCompleted,
                                  item,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
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
                                          : TextDecoration.none,
                                      color: item.isCompleted
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (item.category != null)
                                        Chip(
                                          label: Text(item.category!),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '個数: ${item.quantity}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  if (item.dueDate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '期限: ${item.dueDate!.year}年${item.dueDate!.month}月${item.dueDate!.day}日',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  if (item.location != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '購入場所: ${item.location}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
        onPressed: () => _addItem(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // アプリ上部のフィルター等
  Widget _buildFilterBar(
    List<String> categoryOptions,
    List<String> locationOptions,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // 全体を一つの Row にまとめます
      child: Row(
        children: [
          // 1. カテゴリフィルタ
          Expanded(
            flex: 2, // 幅の比率を調整
            child: DropdownButtonFormField<String>(
              value: _categoryFilter,
              isExpanded: true, // テキストが溢れないように
              items: categoryOptions
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(
                labelText: 'ジャンル',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onChanged: (v) => setState(() => _categoryFilter = v ?? 'すべて'),
            ),
          ),
          const SizedBox(width: 8),

          // 2. ロケーションフィルタ
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _locationFilter,
              isExpanded: true,
              items: locationOptions
                  .map(
                    (l) => DropdownMenuItem(
                      value: l,
                      child: Text(l, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(
                labelText: '場所',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onChanged: (v) => setState(() => _locationFilter = v ?? 'すべて'),
            ),
          ),
          const SizedBox(width: 8),

          // 3. ソート切替（ボタン化して省スペースに）
          IconButton(
            constraints: const BoxConstraints(), // 余白を詰める
            padding: EdgeInsets.zero,
            tooltip: _isDescending ? '降順' : '昇順',
            icon: Icon(
              _isDescending ? Icons.sort_rounded : Icons.filter_list_rounded,
              color: Colors.blue,
            ),
            onPressed: () => setState(() => _isDescending = !_isDescending),
          ),

          // 4. クリアボタン
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            tooltip: 'クリア',
            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
            onPressed: () {
              setState(() {
                _categoryFilter = 'すべて';
                _locationFilter = 'すべて';
                _sortKey = SortKey.created;
                _isDescending = true;
              });
            },
          ),
        ],
      ),
    );
  }
}
