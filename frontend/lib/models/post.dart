/// 留言模型類，用於表示留言板上的貼文
class Post {
  final int id;
  final String username;
  final String content;
  final String timestamp;
  final List<Comment> comments;

  /// 構造函數，初始化留言屬性
  Post({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
    this.comments = const [],
  });

  /// 從 JSON 創建 Post 對象的工廠方法
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      username: json['username'],
      content: json['content'],
      timestamp: json['timestamp'],
      comments: json['comments'] != null
          ? List<Comment>.from(
              json['comments'].map((x) => Comment.fromJson(x)))
          : [],
    );
  }

  /// 將 Post 對象轉換為 JSON 的方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'content': content,
      'timestamp': timestamp,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }
}

/// 評論模型類，用於表示留言的評論
class Comment {
  final int id;
  final String username;
  final String content;
  final String timestamp;

  /// 構造函數，初始化評論屬性
  Comment({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
  });

  /// 從 JSON 創建 Comment 對象的工廠方法
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      username: json['username'],
      content: json['content'],
      timestamp: json['timestamp'],
    );
  }

  /// 將 Comment 對象轉換為 JSON 的方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'content': content,
      'timestamp': timestamp,
    };
  }
}