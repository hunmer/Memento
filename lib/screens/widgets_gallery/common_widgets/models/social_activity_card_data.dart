import 'dart:convert';

/// 社交用户数据模型
class SocialUser {
  final String name;
  final String username;
  final String avatarUrl;
  final int followerCount;

  const SocialUser({
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.followerCount,
  });

  /// 从 JSON 创建
  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      name: json['name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String,
      followerCount: json['followerCount'] as int,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'avatarUrl': avatarUrl,
      'followerCount': followerCount,
    };
  }

  /// 复制并修改部分属性
  SocialUser copyWith({
    String? name,
    String? username,
    String? avatarUrl,
    int? followerCount,
  }) {
    return SocialUser(
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
    );
  }
}

/// 社交动态数据模型
class SocialPost {
  final String hashtag;
  final String content;
  final int commentCount;
  final int repostCount;
  final String imageUrl;

  const SocialPost({
    required this.hashtag,
    required this.content,
    required this.commentCount,
    required this.repostCount,
    required this.imageUrl,
  });

  /// 从 JSON 创建
  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      hashtag: json['hashtag'] as String,
      content: json['content'] as String,
      commentCount: json['commentCount'] as int,
      repostCount: json['repostCount'] as int,
      imageUrl: json['imageUrl'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'hashtag': hashtag,
      'content': content,
      'commentCount': commentCount,
      'repostCount': repostCount,
      'imageUrl': imageUrl,
    };
  }

  /// 复制并修改部分属性
  SocialPost copyWith({
    String? hashtag,
    String? content,
    int? commentCount,
    int? repostCount,
    String? imageUrl,
  }) {
    return SocialPost(
      hashtag: hashtag ?? this.hashtag,
      content: content ?? this.content,
      commentCount: commentCount ?? this.commentCount,
      repostCount: repostCount ?? this.repostCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// 社交活动动态卡片数据模型
class SocialActivityCardData {
  final SocialUser user;
  final List<SocialPost> posts;

  const SocialActivityCardData({
    required this.user,
    required this.posts,
  });

  /// 从 JSON 创建
  factory SocialActivityCardData.fromJson(Map<String, dynamic> json) {
    return SocialActivityCardData(
      user: SocialUser.fromJson(json['user'] as Map<String, dynamic>),
      posts: (json['posts'] as List)
          .map((item) => SocialPost.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'posts': posts.map((post) => post.toJson()).toList(),
    };
  }

  /// 序列化为 JSON 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 从 JSON 字符串创建
  factory SocialActivityCardData.fromJsonString(String jsonString) {
    return SocialActivityCardData.fromJson(jsonDecode(jsonString));
  }

  /// 复制并修改部分属性
  SocialActivityCardData copyWith({
    SocialUser? user,
    List<SocialPost>? posts,
  }) {
    return SocialActivityCardData(
      user: user ?? this.user,
      posts: posts ?? this.posts,
    );
  }

  /// 创建默认示例数据
  static SocialActivityCardData get defaultData {
    return SocialActivityCardData(
      user: const SocialUser(
        name: 'Sammy Lawson',
        username: '@CoRay',
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDzpJQv6FKOjR43geXnHpsz8Npw1GNObnjUa4a3rMQMhzgh_Ve97KVQFW2t3lmVLLpxubY1Ij4YjjtZja3z1gx65I9Z-nhCYBZ9BvLuskC7U8Sw_3XzG0JPVacFep_ILPA18Xzs4yfFMKnCahkfdVUbs02DabzlfaajQAqdlz2HpOOA8RSmsUDDVuvexDm3FSCTBEWNnmqrT3WUQcz0HFRaIGdRRirVYatc5fUOPzltq8H7dNLxkzrbMheMDzFe-Ljb4_HjIBos9A',
        followerCount: 3600,
      ),
      posts: const [
        SocialPost(
          hashtag: '#iphone',
          content: 'It\'s incredible to see art, creativity and technology come together in celebration',
          commentCount: 3600,
          repostCount: 12000,
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDv-L2GqLDB3xFsxjxb-FZwDal1ZHLI_iIfHb2QF0ikj7mDKw_uXQBE0SDqqd8v_UTM-S3b_TfJP9xvcHVXstPR6dA00hqTl4QXeEzf0w0kkoq6pPgX9wJ-Jyw4TScj-Jxhk4Ztcw8TGBKqEHPm-BkbGvU4YRkJ015N3PSkDQCPbl1Z7sXAFlGv_OCdtMJteF3FeWWI8HgKWhM9oy8E-CGBCfmjdJ6Q1JyYzXk_QkRe7Ml1mIGACbUjWOcUlFhKh6oeuMSF4vYS4Q',
        ),
        SocialPost(
          hashtag: '#technology',
          content: 'The most powerful technology empowers everyone',
          commentCount: 4900,
          repostCount: 14000,
          imageUrl:
              'https://lh3.googleusercontent.com/ida-public/AB6AXuACh19veuHbJJdX79BnZ9ZaBiWnr328sjaUQBL9kSyEcXsvq55v66Dh3qEtWkU1nt6DDmrlTyUg7lQPv9D7dswYcBBEs3JCZn1g0EunLyU0ORUz0yZMOSrsCDJOC9E42OEC_0Ti8L5Ig8lPhgdONolkEb5LCqstFHzsberQnrbMNofpMYxRM2mWwG-9v9y7z7JgT81yAuLt5Tb-SAK1NfMCCOS8VM2bMaHaKluQDJz2_uFHWptoqG66NxwrX7rpca3Z6XxyMvLlYA',
        ),
      ],
    );
  }
}
