import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulso/features/posts/providers/post_providers.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _captionCtrl = TextEditingController();
  Uint8List? _imageBytes;
  bool _busy = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  Future<void> _submit() async {
    final bytes = _imageBytes;
    if (bytes == null || bytes.isEmpty) {
      _toast('Pick a photo first.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(postRepositoryProvider).createPost(
            imageBytes: bytes.toList(),
            caption: _captionCtrl.text.trim().isEmpty
                ? null
                : _captionCtrl.text.trim(),
          );
      ref.invalidate(postFeedProvider);
      await ref.read(postFeedProvider.future);
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Material(
              color: Colors.black12,
              child: InkWell(
                onTap: _busy ? null : _pickImage,
                child: _imageBytes == null
                    ? const Center(child: Text('Tap to choose a photo'))
                    : Image.memory(_imageBytes!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionCtrl,
            decoration: const InputDecoration(
              labelText: 'Caption',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
