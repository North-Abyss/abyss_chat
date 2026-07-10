import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final gifProvider = NotifierProvider<GifNotifier, GifState>(() {
  return GifNotifier();
});

class GifState {
  final List<String> recentGifs;
  final List<String> favoriteGifs;
  
  GifState({this.recentGifs = const [], this.favoriteGifs = const []});
  
  GifState copyWith({List<String>? recentGifs, List<String>? favoriteGifs}) {
    return GifState(
      recentGifs: recentGifs ?? this.recentGifs,
      favoriteGifs: favoriteGifs ?? this.favoriteGifs,
    );
  }
}

class GifNotifier extends Notifier<GifState> {
  @override
  GifState build() {
    _loadData();
    return GifState();
  }

  static const String _recentKey = 'recent_gifs';
  static const String _favoriteKey = 'favorite_gifs';

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final recents = prefs.getStringList(_recentKey) ?? [];
    final favorites = prefs.getStringList(_favoriteKey) ?? [];
    state = GifState(recentGifs: recents, favoriteGifs: favorites);
  }

  Future<void> addRecent(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return;
    
    final prefs = await SharedPreferences.getInstance();
    final recents = List<String>.from(state.recentGifs);
    
    recents.remove(url);
    recents.insert(0, url);
    if (recents.length > 20) {
      recents.removeLast(); // Keep top 20
    }
    
    await prefs.setStringList(_recentKey, recents);
    state = state.copyWith(recentGifs: recents);
  }

  Future<void> toggleFavorite(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = List<String>.from(state.favoriteGifs);
    
    if (favorites.contains(url)) {
      favorites.remove(url);
    } else {
      favorites.insert(0, url);
    }
    
    await prefs.setStringList(_favoriteKey, favorites);
    state = state.copyWith(favoriteGifs: favorites);
  }
}
