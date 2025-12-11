import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_item.dart';
import '../screens/new_item_screen.dart';

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
  String _locationSearch = '';

  void _toggleCompletion(String itemId, bool isCurrentlyCompleted) async {
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
      if (_categoryFilter != 'すべて' && (item.category ?? '') != _categoryFilter) {
        return false;
      }
      if (_locationFilter != 'すべて' && (item.location ?? '') != _locationFilter) {
        return false;
      }
      if (_locationSearch.isNotEmpty && !(item.location ?? '').contains(_locationSearch)) {
        return false;
      }
      return true;
    }).toList();

    // ソート（期日でソートする場合のみここで処理）
    if (_sortKey == SortKey.due) {
      filtered.sort((a, b) {
        // null を末尾に置く（降順なら先頭か末尾かを下で調整）
        final aNull = a.dueDate == null;
        final bNull = b.dueDate == null;
        if (aNull && bNull) return 0;
        if (aNull) return 1;
        if (bNull) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      // 期日の降順を要求している場合は反転
      if (_isDescending) {
        return filtered.reversed.toList();
      }
    }

    // 追加順（作成日時）については Stream 側で作成日時降順に取得しているため、
    // ここではそのまま返し、必要なら呼び出し側で反転する。
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物メモアプリ'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // デフォルトは作成日時降順で取得
        stream: _shoppingListRef.orderBy('createdAt', descending: true).snapshots(),
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

          // フィルタ用の選択肢を動的に生成
          final categories = <String>{'すべて'};
          final locations = <String>{'すべて'};
          for (final it in loadedItems) {
            if (it.category != null && it.category!.isNotEmpty) categories.add(it.category!);
            if (it.location != null && it.location!.isNotEmpty) locations.add(it.location!);
          }
          final categoryOptions = categories.toList()..sort();
          final locationOptions = locations.toList()..sort();

          // フィルター・ソート適用
          var displayItems = _applyFiltersAndSort(loadedItems);

          // 追加順（作成日時）で並べ替える場合：Stream 側は降順なので、降順を要求していればそのまま、
          // 昇順を要求していれば反転する
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
                                _toggleCompletion(item.id, item.isCompleted);
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
                                        '場所: ${item.location}',
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

  Widget _buildFilterBar(List<String> categoryOptions, List<String> locationOptions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // カテゴリフィルタ
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _categoryFilter,
                  items: categoryOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  decoration: const InputDecoration(labelText: 'ジャンルで絞る'),
                  onChanged: (v) {
                    setState(() {
                      _categoryFilter = v ?? 'すべて';
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // ロケーションフィルタ
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _locationFilter,
                  items: locationOptions
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  decoration: const InputDecoration(labelText: '購入場所で絞る'),
                  onChanged: (v) {
                    setState(() {
                      _locationFilter = v ?? 'すべて';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 場所検索（部分一致）
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '場所で検索（部分一致）',
                    prefixIcon: Icon(Icons.search),
                  ),
                  controller: TextEditingController(text: _locationSearch),
                  onChanged: (v) {
                    setState(() {
                      _locationSearch = v.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 並べ替え（キー選択）
              DropdownButton<SortKey>(
                value: _sortKey,
                items: const [
                  DropdownMenuItem(value: SortKey.created, child: Text('追加順')),
                  DropdownMenuItem(value: SortKey.due, child: Text('期日順')),
                ],
                onChanged: (v) {
                  setState(() {
                    _sortKey = v ?? SortKey.created;
                  });
                },
              ),
              const SizedBox(width: 8),
              // 順序反転ボタン
              IconButton(
                tooltip: _isDescending ? '降順に表示（クリックで昇順へ）' : '昇順に表示（クリックで降順へ）',
                icon: Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward),
                onPressed: () {
                  setState(() {
                    _isDescending = !_isDescending;
                  });
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'フィルタをクリア',
                icon: const Icon(Icons.clear_all),
                onPressed: () {
                  setState(() {
                    _categoryFilter = 'すべて';
                    _locationFilter = 'すべて';
                    _locationSearch = '';
                    _sortKey = SortKey.created;
                    _isDescending = true;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
