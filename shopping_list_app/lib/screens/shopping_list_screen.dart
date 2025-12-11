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
      MaterialPageRoute(
        builder: (ctx) => const NewItemScreen(),
      ),
    );

    if (newItem == null) {
      return;
    }

    try {
      await _shoppingListRef.add(newItem.toFirestore());

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newItem.name} をリストに追加しました。')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アイテムの追加に失敗しました: $e')),
      );
    }
  }

  @override //UI
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物メモ (Firebase)'),
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
                doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          if (loadedItems.isEmpty) {
            return const Center(child: Text('買い物リストは空です。新しいアイテムを追加しましょう！'));
          }

          return ListView.builder(
            itemCount: loadedItems.length,
            itemBuilder: (context, index) {
              final item = loadedItems[index];

              return ListTile(
                title: Text(
                  item.name,
                  style: TextStyle(
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                subtitle: Text('数量: ${item.quantity}'),
                leading: Checkbox(
                  value: item.isCompleted,
                  onChanged: (bool? newValue) {
                    _toggleCompletion(item.id, item.isCompleted);
                  },
                ),
                onTap: () {
                  _toggleCompletion(item.id, item.isCompleted);
                },
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