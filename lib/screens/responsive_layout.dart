import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
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
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;
    final tabIndex = ref.watch(navigationIndexProvider);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left Navigation Dock (Desktop)
            NavigationRail(
              selectedIndex: tabIndex,
              onDestinationSelected: (idx) {
                ref.read(navigationIndexProvider.notifier).setIndex(idx);
              },
              labelType: NavigationRailLabelType.all,
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
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
            
            // Main Content Area
            Expanded(
              child: _buildDesktopContent(tabIndex, ref, context),
            ),
          ],
        ),
      );
    } else {
      // Mobile Layout (Bottom Dock)
      return Scaffold(
        body: _buildMobileContent(tabIndex, context),
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
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDesktopContent(int tabIndex, WidgetRef ref, BuildContext context) {
    switch (tabIndex) {
      case 0: // Chats (2-pane split layout)
        final selectedThreadId = ref.watch(selectedThreadIdProvider);
        return Row(
          children: [
            const SizedBox(
              width: 350,
              child: HomeScreen(isDesktop: true),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
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
      case 1:
        return const CallLogScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const Center(child: Text('Unknown Tab'));
    }
  }

  Widget _buildMobileContent(int tabIndex, BuildContext context) {
    switch (tabIndex) {
      case 0:
        return const HomeScreen(isDesktop: false);
      case 1:
        return const CallLogScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const Center(child: Text('Unknown Tab'));
    }
  }
}

