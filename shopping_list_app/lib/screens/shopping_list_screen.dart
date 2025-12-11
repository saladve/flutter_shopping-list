import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_item.dart';
import '../screens/new_item_screen.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  CollectionReference get _shoppingListRef {
    return FirebaseFirestore.instance.collection('shopping_list');
  }

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

  @override //UI
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物メモアプリ'),
        backgroundColor: Theme.of(context).primaryColor,
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

          if (loadedItems.isEmpty) {
            return const Center(child: Text('買い物リストは空です。新しいアイテムを追加しましょう！'));
          }

          return ListView.builder(
            itemCount: loadedItems.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final item = loadedItems[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
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
          );
        },
      ),

      // 追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItem(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
