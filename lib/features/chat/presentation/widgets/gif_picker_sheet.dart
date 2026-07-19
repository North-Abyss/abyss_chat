import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/app/gif_provider.dart';
import 'package:url_launcher/url_launcher.dart';
class GifPickerSheet extends ConsumerStatefulWidget {
  final Function(String) onGifSelected;
  const GifPickerSheet({super.key, required this.onGifSelected});

  @override
  ConsumerState<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends ConsumerState<GifPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _tabController.animateTo(0);
    });
    
    try {
      // Using public Giphy Beta API Key for demo purposes
      final response = await http.get(Uri.parse('https://api.giphy.com/v1/gifs/search?api_key=dc6zaTOxFJmzC&q=${Uri.encodeComponent(query)}&limit=24'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'];
        setState(() {
          _searchResults = items.map((item) => item['images']['fixed_height']['url'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('Error searching GIFs: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _submitUrl(String url) {
    if (url.trim().isEmpty || !url.startsWith('http')) {
      _searchGifs(url);
      return;
    }
    ref.read(gifProvider.notifier).addRecent(url.trim());
    widget.onGifSelected(url.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gifState = ref.watch(gifProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Giphy or paste URL...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _submitUrl,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                  onPressed: _isSearching ? null : () => _submitUrl(_searchController.text),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Search', icon: Icon(Icons.search)),
              Tab(text: 'Recents', icon: Icon(Icons.history)),
              Tab(text: 'Favorites', icon: Icon(Icons.favorite)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGifGrid(_searchResults, gifState.favoriteGifs, isSearchTab: true),
                _buildGifGrid(gifState.recentGifs, gifState.favoriteGifs),
                _buildGifGrid(gifState.favoriteGifs, gifState.favoriteGifs, isFavoritesTab: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifGrid(List<String> urls, List<String> favorites, {bool isFavoritesTab = false, bool isSearchTab = false}) {
    if (urls.isEmpty) {
      if (isSearchTab) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'API Search is disabled due to rate limits.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Copy a GIF link from the web and paste it above!',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open Giphy'),
                    onPressed: () => launchUrl(Uri.parse('https://giphy.com')),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open Tenor'),
                    onPressed: () => launchUrl(Uri.parse('https://tenor.com')),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      return Center(
        child: Text(
          isFavoritesTab ? 'No favorites yet.' : 'No recent GIFs.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return GridView.builder(
      
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
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
