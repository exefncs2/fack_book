// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';  // 添加此導入
import '../models/post.dart';  // 添加此導入

/// 主頁面，顯示留言板
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _postController = TextEditingController();  // 留言輸入控制器
  final Map<int, TextEditingController> _commentControllers = {};  // 評論輸入控制器映射
  
  @override
  void initState() {
    super.initState();
    // 頁面初始化時加載留言
    Future.microtask(() => 
      Provider.of<PostProvider>(context, listen: false).loadPosts()
    );
  }
  
  @override
  void dispose() {
    // 釋放所有控制器資源
    _postController.dispose();
    _commentControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('留言板'),
        actions: [
          // 用戶信息顯示
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${authProvider.user?.username}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // 登出按鈕
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: '登出',
            onPressed: () async {
              // 顯示確認對話框
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('確認登出'),
                  content: Text('您確定要登出嗎？'),
                  actions: [
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                    TextButton(
                      child: Text('確定'),
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
              );
              
              // 如果用戶確認，則執行登出
              if (confirm == true) {
                await authProvider.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => postProvider.loadPosts(),
        child: Column(
          children: [
            // 發表留言區域
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 留言輸入框
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _postController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '有什麼新鮮事要分享嗎？',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // 發布按鈕
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_postController.text.trim().isNotEmpty) {
                        postProvider.createPost(_postController.text.trim());
                        _postController.clear();
                      }
                    },
                    icon: Icon(Icons.send),
                    label: Text('發布'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // 分隔線
            Divider(thickness: 1),
            
            // 留言列表
            Expanded(
              child: postProvider.isLoading && postProvider.posts.isEmpty
                ? Center(child: CircularProgressIndicator())  // 加載中
                : postProvider.posts.isEmpty
                  ? Center(child: Text('還沒有任何留言，來發布第一條吧！'))  // 空列表
                  : ListView.separated(
                      padding: EdgeInsets.only(bottom: 20),
                      itemCount: postProvider.posts.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final post = postProvider.posts[index];
                        // 確保每個貼文都有自己的評論控制器
                        if (!_commentControllers.containsKey(post.id)) {
                          _commentControllers[post.id] = TextEditingController();
                        }
                        return _buildPostItem(context, post, _commentControllers[post.id]!);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 構建留言項目
  Widget _buildPostItem(BuildContext context, Post post, TextEditingController commentController) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0.5,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 留言頭部：用戶名和時間
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 用戶頭像和名稱
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      post.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                // 時間
                Text(
                  post.timestamp,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // 留言內容
            Text(
              post.content,
              style: TextStyle(fontSize: 16),
            ),
            
            SizedBox(height: 16),
            
            // 留言底部：評論區
            if (post.comments.isNotEmpty) ...[
              Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '評論 (${post.comments.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              ...post.comments.map((comment) => _buildCommentItem(comment)).toList(),
            ],
            
            // 添加評論
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: '添加評論...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (commentController.text.trim().isNotEmpty) {
                      Provider.of<PostProvider>(context, listen: false)
                        .addComment(post.id, commentController.text.trim());
                      commentController.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 構建評論項目
  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(comment.content),
                  SizedBox(height: 4),
                  Text(
                    comment.timestamp,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}