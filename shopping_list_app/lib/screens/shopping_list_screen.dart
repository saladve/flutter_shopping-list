import 'package:flutter/material.dart';
import '../models/shopping_item.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  // Stateオブジェクトを作成するメソッド
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
//ダミーデータ
  List<ShoppingItem> _shoppingList = [
    const ShoppingItem(name: '牛乳', quantity: 1, isCompleted: false),
    const ShoppingItem(name: 'パン', quantity: 2, isCompleted: true),
    const ShoppingItem(name: '卵'),
    const ShoppingItem(name: 'トマト'),
  ];

  // チェックボックスの状態を切り替えるメソッド（次のステップで利用）
  void _toggleCompletion(int index) {
    // setStateブロック内でデータを変更すると、UIが自動的に再描画されます
    setState(() {
      final currentItem = _shoppingList[index];

      _shoppingList[index] = currentItem.copyWith(
        isCompleted: !currentItem.isCompleted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 画面の基本構造を提供するScaffold
    return Scaffold(
      // 画面上部のAppBar（ヘッダー）
      appBar: AppBar(
        title: const Text('買い物メモ'),
        backgroundColor: Theme.of(context).primaryColor,
      ),

      // 画面のメインコンテンツ（リスト部分）
      body: ListView.builder(
        // リストアイテムの数
        itemCount: _shoppingList.length,
        // 各行をビルドする関数
        itemBuilder: (context, index) {
          final item = _shoppingList[index];

          // 各行（買い物メモアイテム）の表示
          return ListTile(
            title: Text(
              item.name,
              style: TextStyle(
                // 購入済みの場合は文字に打ち消し線を入れる
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: item.isCompleted ? Colors.grey : Colors.black, // 色も少し変えてみる
              ),
            ),
            subtitle: Text('数量: ${item.quantity}'),
            // アイテムの先頭にチェックボックスを表示
            leading: Checkbox(
              value: item.isCompleted,
              // チェックボックスの変更イベント
              onChanged: (bool? newValue) {
                // チェックボックスがタップされたら状態を切り替えるメソッドを呼び出す
                _toggleCompletion(index);
              },
            ),
            // アイテム全体をタップできるようにする
            onTap: () {
              _toggleCompletion(index);
            },
          );
        },
      ),

      // 画面右下のフローティングアクションボタン（アイテム追加用）
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 💡 リストに新しいダミーアイテムを追加し、画面を再描画します
          setState(() {
            _shoppingList.add(
              ShoppingItem(
                name: '新規アイテム ${DateTime.now().second}', // 時刻でユニークな名前に
                quantity: 1,
              ),
            );
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}