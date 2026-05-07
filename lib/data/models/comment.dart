import 'user.dart';

/// Comment Model
class Comment {
  final String id;
  final String content;
  final User? user;
  final int? likedCount;
  final bool? liked;
  final int time;
  final String? ipLocation;
  final Comment? replyToComment;
  final User? replyToUser;
  final List<Comment>? replies;
  final int? replyCount;
  final bool? isHotComment;

  Comment({
    required this.id,
    required this.content,
    this.user,
    this.likedCount,
    this.liked,
    required this.time,
    this.ipLocation,
    this.replyToComment,
    this.replyToUser,
    this.replies,
    this.replyCount,
    this.isHotComment,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    User? user;
    if (json['user'] != null) {
      user = User.fromJson(json['user']);
    }

    Comment? replyToComment;
    User? replyToUser;
    if (json['beReplied'] != null && json['beReplied'].isNotEmpty) {
      replyToComment = Comment(
        id: json['beReplied'][0]['id']?.toString() ?? '',
        content: json['beReplied'][0]['content'] ?? '',
        time: json['beReplied'][0]['time'] ?? 0,
      );
      if (json['beReplied'][0]['user'] != null) {
        replyToUser = User.fromJson(json['beReplied'][0]['user']);
      }
    }

    return Comment(
      id: json['commentId']?.toString() ?? json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      user: user,
      likedCount: json['likedCount'] ?? json['liked'] ?? 0,
      liked: json['liked'] == true,
      time: json['time'] ?? 0,
      ipLocation: json['ipLocation'],
      replyToComment: replyToComment,
      replyToUser: replyToUser,
      replyCount: json['replyCount'] ?? 0,
      isHotComment: json['isHotComment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': id,
      'content': content,
      'user': user?.toJson(),
      'likedCount': likedCount,
      'liked': liked,
      'time': time,
      'ipLocation': ipLocation,
      'replyCount': replyCount,
      'isHotComment': isHotComment,
    };
  }

  Comment copyWith({
    String? id,
    String? content,
    User? user,
    int? likedCount,
    bool? liked,
    int? time,
    String? ipLocation,
    Comment? replyToComment,
    User? replyToUser,
    int? replyCount,
    bool? isHotComment,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      user: user ?? this.user,
      likedCount: likedCount ?? this.likedCount,
      liked: liked ?? this.liked,
      time: time ?? this.time,
      ipLocation: ipLocation ?? this.ipLocation,
      replyToComment: replyToComment ?? this.replyToComment,
      replyToUser: replyToUser ?? this.replyToUser,
      replyCount: replyCount ?? this.replyCount,
      isHotComment: isHotComment ?? this.isHotComment,
    );
  }
}

/// Comment List Model
class CommentList {
  final bool? hotComments;
  final bool? more;
  final int? moreHot;
  final List<Comment> comments;
  final List<Comment>? hotCommentsList;
  final int? total;
  final int? code;

  CommentList({
    this.hotComments,
    this.more,
    this.moreHot,
    required this.comments,
    this.hotCommentsList,
    this.total,
    this.code,
  });

  factory CommentList.fromJson(Map<String, dynamic> json) {
    List<Comment> comments = [];
    if (json['comments'] != null) {
      comments = (json['comments'] as List)
          .map((e) => Comment.fromJson(e))
          .toList();
    }

    List<Comment>? hotCommentsList;
    if (json['hotComments'] != null) {
      hotCommentsList = (json['hotComments'] as List)
          .map((e) => Comment.fromJson(e))
          .toList();
    }

    return CommentList(
      hotComments: json['hotComments'] != null,
      more: json['more'],
      moreHot: json['moreHot'],
      comments: comments,
      hotCommentsList: hotCommentsList,
      total: json['total'] ?? comments.length,
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hotComments': hotComments,
      'more': more,
      'moreHot': moreHot,
      'comments': comments.map((e) => e.toJson()).toList(),
      'hotCommentsList': hotCommentsList?.map((e) => e.toJson()).toList(),
      'total': total,
      'code': code,
    };
  }

  // Get all comments including hot comments
  List<Comment> get allComments {
    if (hotCommentsList != null && hotCommentsList!.isNotEmpty) {
      return [...hotCommentsList!, ...comments];
    }
    return comments;
  }
}

/// Comment Like Response
class CommentLikeResponse {
  final bool success;
  final int? code;
  final String? message;

  CommentLikeResponse({
    required this.success,
    this.code,
    this.message,
  });

  factory CommentLikeResponse.fromJson(Map<String, dynamic> json) {
    return CommentLikeResponse(
      success: json['code'] == 200,
      code: json['code'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
    };
  }
}
