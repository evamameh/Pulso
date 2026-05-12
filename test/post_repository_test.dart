import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulso/features/posts/application/post_repository.dart';
import 'package:pulso/features/posts/data/post_gateway.dart';
import 'package:pulso/features/posts/domain/post.dart';
import 'package:uuid/uuid.dart';

class MockPostGateway extends Mock implements PostGateway {}

void main() {
  late MockPostGateway gateway;
  late PostRepository repository;

  setUp(() {
    gateway = MockPostGateway();
    repository = PostRepository(
      gateway: gateway,
      currentUserId: () => 'user-1',
      uuid: const Uuid(),
    );
    registerFallbackValue(<int>[]);
  });

  test('createPost uploads then inserts when signed in', () async {
    when(
      () => gateway.uploadPostImage(
        userId: any(named: 'userId'),
        bytes: any(named: 'bytes'),
        objectPath: any(named: 'objectPath'),
      ),
    ).thenAnswer((_) async => 'https://example.com/file.jpg');
    when(
      () => gateway.insertPost(
        userId: any(named: 'userId'),
        imageUrl: any(named: 'imageUrl'),
        caption: any(named: 'caption'),
      ),
    ).thenAnswer((_) async {});

    await repository.createPost(
      imageBytes: const [1, 2, 3],
      caption: 'hello',
      newObjectPath: () => 'user-1/test.jpg',
    );

    verify(
      () => gateway.uploadPostImage(
        userId: 'user-1',
        bytes: const [1, 2, 3],
        objectPath: 'user-1/test.jpg',
      ),
    ).called(1);
    verify(
      () => gateway.insertPost(
        userId: 'user-1',
        imageUrl: 'https://example.com/file.jpg',
        caption: 'hello',
      ),
    ).called(1);
  });

  test('createPost throws when no signed-in user', () async {
    final repo = PostRepository(
      gateway: gateway,
      currentUserId: () => null,
    );

    expect(
      () => repo.createPost(
        imageBytes: const [1],
        newObjectPath: () => 'x/y.jpg',
      ),
      throwsStateError,
    );

    verifyNever(
      () => gateway.uploadPostImage(
        userId: any(named: 'userId'),
        bytes: any(named: 'bytes'),
        objectPath: any(named: 'objectPath'),
      ),
    );
  });

  test('fetchFeed delegates to gateway', () async {
    when(
      () => gateway.fetchPosts(limit: 12, currentUserId: 'user-1'),
    ).thenAnswer(
      (_) async => [
        Post(
          id: 'p1',
          userId: 'user-1',
          imageUrl: 'https://example.com/a.jpg',
          caption: null,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );

    final posts = await repository.fetchFeed(limit: 12);

    expect(posts, hasLength(1));
    expect(posts.first.id, 'p1');
    verify(() => gateway.fetchPosts(limit: 12, currentUserId: 'user-1'))
        .called(1);
  });

  test('deletePost delegates to gateway', () async {
    when(() => gateway.deletePost(any())).thenAnswer((_) async {});

    await repository.deletePost('post-9');

    verify(() => gateway.deletePost('post-9')).called(1);
  });

  test('likePost delegates to gateway', () async {
    when(
      () => gateway.likePost(
        postId: any(named: 'postId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});

    await repository.likePost('post-1');

    verify(
      () => gateway.likePost(postId: 'post-1', userId: 'user-1'),
    ).called(1);
  });

  test('unlikePost delegates to gateway', () async {
    when(
      () => gateway.unlikePost(
        postId: any(named: 'postId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});

    await repository.unlikePost('post-1');

    verify(
      () => gateway.unlikePost(postId: 'post-1', userId: 'user-1'),
    ).called(1);
  });

  test('likePost throws when not signed in', () async {
    final repo = PostRepository(
      gateway: gateway,
      currentUserId: () => null,
    );

    expect(() => repo.likePost('p'), throwsStateError);
    verifyNever(
      () => gateway.likePost(
        postId: any(named: 'postId'),
        userId: any(named: 'userId'),
      ),
    );
  });
}
