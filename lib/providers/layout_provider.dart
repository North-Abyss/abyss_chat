import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/services/shared_prefs_helper.dart';

enum DockPosition { bottom, left }

class LayoutState {
  final DockPosition dockPosition;

  LayoutState({required this.dockPosition});
}

class LayoutPreferencesNotifier extends AsyncNotifier<LayoutState> {
  @override
  Future<LayoutState> build() async {
    final prefs = await SharedPrefsHelper.instance;
    final dockStr = prefs.getString('dockPosition');

    // For desktop default to left, for mobile default to bottom
    DockPosition defaultPosition = DockPosition.bottom;
    
    // We can't use MediaQuery here directly since it's a provider, 
    // but we can rely on defaults and override based on user preference
    if (dockStr == 'left') {
      defaultPosition = DockPosition.left;
    } else if (dockStr == 'bottom') {
      defaultPosition = DockPosition.bottom;
    }
    
    return LayoutState(dockPosition: defaultPosition);
  }

  Future<void> setDockPosition(DockPosition position) async {
    final prefs = await SharedPrefsHelper.instance;
    await prefs.setString('dockPosition', position.name);
    state = AsyncData(LayoutState(dockPosition: position));
  }
}

final layoutProvider = AsyncNotifierProvider<LayoutPreferencesNotifier, LayoutState>(() {
  return LayoutPreferencesNotifier();
});
