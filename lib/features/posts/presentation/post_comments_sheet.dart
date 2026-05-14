import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
import 'package:pulso/features/posts/domain/comment.dart';
import 'package:pulso/features/posts/providers/post_providers.dart';

Future<void> showPostCommentsSheet({
  required BuildContext context,
  required String postId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => PostCommentsSheet(postId: postId),
  );
}

class PostCommentsSheet extends ConsumerStatefulWidget {
  const PostCommentsSheet({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<PostCommentsSheet> {
  final _newComment = TextEditingController();
  bool _sending = false;
  String? _actionError;
  /// When non-null, the next Post is a reply to this comment.
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _newComment.addListener(_clearErrorOnType);
  }

  void _clearErrorOnType() {
    if (_actionError != null) {
      setState(() => _actionError = null);
    }
  }

  @override
  void dispose() {
    _newComment.removeListener(_clearErrorOnType);
    _newComment.dispose();
    super.dispose();
  }

  String _friendlyCommentError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('foreign key') ||
        raw.contains('violates foreign key') ||
        raw.contains('profiles')) {
      return 'Your account needs a profile before commenting. '
          'Open Profile, set your username, and tap Save profile — then try again.';
    }
    if (raw.contains('row-level security') ||
        raw.contains('rls') ||
        raw.contains('42501') ||
        raw.contains('permission denied')) {
      return 'Comments are blocked by database rules. '
          'In Supabase, confirm the `comments` table exists and the `comments_insert` policy allows authenticated users to insert their own rows.';
    }
    if (raw.contains('parent_id') || raw.contains('column')) {
      return 'Run `supabase/schema_day9_comment_replies.sql` in the Supabase SQL editor '
          'to add the `parent_id` column for replies.';
    }
    return e.toString();
  }

  Future<void> _submit() async {
    final text = _newComment.text.trim();
    if (text.isEmpty) {
      setState(() => _actionError = 'Write something first, then tap Post.');
      return;
    }
    setState(() {
      _sending = true;
      _actionError = null;
    });
    FocusScope.of(context).unfocus();
    try {
      await ref.read(postRepositoryProvider).addComment(
            widget.postId,
            text,
            parentCommentId: _replyingTo?.id,
          );
      _newComment.clear();
      ref.invalidate(commentsForPostProvider(widget.postId));
      await ref.read(commentsForPostProvider(widget.postId).future);
      ref.invalidate(postFeedProvider);
      if (mounted) setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = _friendlyCommentError(e));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editComment(Comment c) async {
    final ctrl = TextEditingController(text: c.body);
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Edit comment'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 5,
            minLines: 1,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      ctrl.dispose();
    }
    if (result == null || result.isEmpty) return;
    setState(() => _actionError = null);
    try {
      await ref.read(postRepositoryProvider).updateComment(c.id, result);
      ref.invalidate(commentsForPostProvider(widget.postId));
      await ref.read(commentsForPostProvider(widget.postId).future);
      ref.invalidate(postFeedProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = _friendlyCommentError(e));
      }
    }
  }

  Future<void> _deleteComment(Comment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _actionError = null);
    try {
      await ref.read(postRepositoryProvider).deleteComment(c.id);
      ref.invalidate(commentsForPostProvider(widget.postId));
      await ref.read(commentsForPostProvider(widget.postId).future);
      ref.invalidate(postFeedProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = _friendlyCommentError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final commentsAsync = ref.watch(commentsForPostProvider(widget.postId));
    final me = ref.watch(currentUserIdProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Comments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: commentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${e.toString()}\n\n'
                        'If this mentions RLS or permission, run `schema_day1.sql` '
                        '(or at least the `comments` table + policies) in Supabase.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet.\nBe the first to say something.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    final byId = {for (final x in list) x.id: x};
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final c = list[i];
                        final mine = me != null && me == c.userId;
                        final replyToUser = c.parentId != null
                            ? byId[c.parentId]?.username
                            : null;
                        return Padding(
                          padding: EdgeInsets.only(
                            left: c.isReply ? 16 : 0,
                            right: 4,
                            top: 8,
                            bottom: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.username,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _replyingTo = c;
                                        _actionError = null;
                                      });
                                    },
                                    child: const Text('Reply'),
                                  ),
                                  if (mine)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz, size: 20),
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          _editComment(c);
                                        } else if (v == 'delete') {
                                          _deleteComment(c);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              if (replyToUser != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Replying to @$replyToUser',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                c.body.trim().isEmpty ? '—' : c.body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: c.body.trim().isEmpty
                                      ? scheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                ),
              if (_replyingTo != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Material(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to ${_replyingTo!.username}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cancel reply',
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _replyingTo = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_actionError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Material(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        _actionError!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newComment,
                          decoration: InputDecoration(
                            hintText: _replyingTo != null
                                ? 'Write a reply to ${_replyingTo!.username}…'
                                : 'Add a comment…',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _sending ? null : _submit,
                        child: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Post'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
