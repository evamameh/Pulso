import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/posts/domain/post.dart';

void main() {
  group('Post.fromMap', () {
    test('maps embedded profiles object to author fields', () {
      final post = Post.fromMap({
        'id': 'p1',
        'user_id': 'auth-uid-eva',
        'image_url': 'https://x/img.jpg',
        'caption': 'hello',
        'created_at': '2026-01-15T12:00:00.000Z',
        'profiles': {
          'username': 'eva',
          'avatar_url': 'https://cdn/eva.jpg',
        },
        'likes': [
          {'count': 2},
        ],
        'comments': [
          {'count': 1},
        ],
      });

      expect(post.authorUsername, 'eva');
      expect(post.authorAvatarUrl, 'https://cdn/eva.jpg');
      expect(post.displayUsername, 'eva');
      expect(post.likeCount, 2);
      expect(post.commentCount, 1);
    });

    test('accepts profiles as one-element list', () {
      final post = Post.fromMap({
        'id': 'p2',
        'user_id': 'u1',
        'image_url': 'https://x/a.jpg',
        'caption': null,
        'created_at': '2026-01-01T00:00:00.000Z',
        'profiles': [
          {'username': 'eva', 'avatar_url': ' https://a.png '},
        ],
        'likes': [],
        'comments': [],
      });

      expect(post.authorUsername, 'eva');
      expect(post.authorAvatarUrl, 'https://a.png');
      expect(post.displayUsername, 'eva');
    });

    test('displayUsername falls back when username missing', () {
      final post = Post.fromMap({
        'id': 'p3',
        'user_id': 'u2',
        'image_url': 'https://x/b.jpg',
        'caption': 'caption only',
        'created_at': '2026-01-01T00:00:00.000Z',
        'profiles': null,
        'likes': [],
        'comments': [],
      });

      expect(post.authorUsername, isNull);
      expect(post.displayUsername, 'user');
    });
  });
}
