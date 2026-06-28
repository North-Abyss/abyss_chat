import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/providers/layout_provider.dart';
import 'package:abyss_chat/screens/home_screen.dart';
import 'package:abyss_chat/screens/chat_screen.dart';
import 'package:abyss_chat/screens/settings_screen.dart';
import 'package:abyss_chat/screens/call_log_screen.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int idx) {
    state = idx;
  }
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(() => NavigationIndexNotifier());

class ResponsiveLayout extends ConsumerWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutStateAsync = ref.watch(layoutProvider);
    final tabIndex = ref.watch(navigationIndexProvider);

    return layoutStateAsync.when(
      data: (layoutState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMedium = width >= 600 && width < 840;
            final isExpanded = width >= 840;
            final isTwoPane = isExpanded || (isMedium && width > 700);

            if (layoutState.dockPosition == DockPosition.left) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      extended: isExpanded,
                      selectedIndex: tabIndex,
                      onDestinationSelected: (idx) {
                        ref.read(navigationIndexProvider.notifier).setIndex(idx);
                      },
                      labelType: isExpanded ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.chat_bubble_outline),
                          selectedIcon: Icon(Icons.chat_bubble),
                          label: Text('Chats'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.call_outlined),
                          selectedIcon: Icon(Icons.call),
                          label: Text('Calls'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.show_chart_outlined),
                          selectedIcon: Icon(Icons.show_chart),
                          label: Text('Activity'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).dividerColor),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildContent(tabIndex, ref, context, isTwoPane),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Bottom Dock
              return Scaffold(
                body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildContent(tabIndex, ref, context, isTwoPane),
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: tabIndex,
                  onDestinationSelected: (idx) {
                    ref.read(navigationIndexProvider.notifier).setIndex(idx);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      selectedIcon: Icon(Icons.chat_bubble),
                      label: 'Chats',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.call_outlined),
                      selectedIcon: Icon(Icons.call),
                      label: 'Calls',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.show_chart_outlined),
                      selectedIcon: Icon(Icons.show_chart),
                      label: 'Activity',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildContent(int tabIndex, WidgetRef ref, BuildContext context, bool isTwoPane) {
    // We add Key to AnimatedSwitcher children so it knows they changed
    switch (tabIndex) {
      case 0:
        if (isTwoPane) {
          final selectedThreadId = ref.watch(selectedThreadIdProvider);
          return Row(
            key: const ValueKey('chats_2pane'),
            children: [
              const SizedBox(
                width: 350,
                child: HomeScreen(isDesktop: true),
              ),
              VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).dividerColor),
              Expanded(
                child: selectedThreadId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Abyss Web',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Send and receive P2P messages securely.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ChatScreen(threadId: selectedThreadId, isDesktop: true),
              ),
            ],
          );
        } else {
          return const HomeScreen(key: ValueKey('chats_1pane'), isDesktop: false);
        }
      case 1:
        return const CallLogScreen(key: ValueKey('calls'));
      case 2:
        return Center(key: const ValueKey('activity'), child: Text('Activity (Coming Soon)'));
      case 3:
        return const SettingsScreen(key: ValueKey('settings'));
      default:
        return const Center(child: Text('Unknown Tab'));
    }
  }
}
