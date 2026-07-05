import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/gif_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GifPickerSheet extends ConsumerStatefulWidget {
  final Function(String) onGifSelected;
  const GifPickerSheet({super.key, required this.onGifSelected});

  @override
  ConsumerState<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends ConsumerState<GifPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submitUrl(String url) {
    if (url.trim().isEmpty || !url.startsWith('http')) return;
    ref.read(gifProvider.notifier).addRecent(url.trim());
    widget.onGifSelected(url.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gifState = ref.watch(gifProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Paste GIF/Meme URL here...',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _submitUrl,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: () => _submitUrl(_urlController.text),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Find GIFs online',
                  child: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      launchUrl(Uri.parse('https://giphy.com/'));
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Recents', icon: Icon(Icons.history)),
              Tab(text: 'Favorites', icon: Icon(Icons.favorite)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGifGrid(gifState.recentGifs, gifState.favoriteGifs),
                _buildGifGrid(gifState.favoriteGifs, gifState.favoriteGifs, isFavoritesTab: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifGrid(List<String> urls, List<String> favorites, {bool isFavoritesTab = false}) {
    if (urls.isEmpty) {
      return Center(
        child: Text(
          isFavoritesTab ? 'No favorites yet.' : 'No recent GIFs.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return GridView.builder(
      
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        final url = urls[index];
        final isFavorite = favorites.contains(url);

        return GestureDetector(
          onTap: () {
            ref.read(gifProvider.notifier).addRecent(url);
            widget.onGifSelected(url);
            Navigator.pop(context);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    ref.read(gifProvider.notifier).toggleFavorite(url);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
