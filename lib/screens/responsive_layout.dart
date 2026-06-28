import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/providers/layout_provider.dart';
import 'package:abyss_chat/screens/home_screen.dart';
import 'package:abyss_chat/screens/chat_screen.dart';
import 'package:abyss_chat/screens/settings_screen.dart';
import 'package:abyss_chat/screens/call_log_screen.dart';
import 'package:abyss_chat/widgets/floating_dock.dart';
import 'package:abyss_chat/services/notification_service.dart';

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

            final isLeft = layoutState.dockPosition == DockPosition.left;
            
            final dockItems = [
              FloatingDockItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'Chats',
                onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(0),
              ),
              FloatingDockItem(
                icon: Icons.call_outlined,
                selectedIcon: Icons.call,
                label: 'Calls',
                onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(1),
              ),
              FloatingDockItem(
                icon: Icons.show_chart_outlined,
                selectedIcon: Icons.show_chart,
                label: 'Activity',
                onTap: () {
                  NotificationService.showMessageNotification('Activity', 'Coming soon in a future update!');
                },
              ),
              FloatingDockItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Settings',
                onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(3),
              ),
            ];

            return Scaffold(
              body: Stack(
                children: [
                  // Main Content
                  Positioned.fill(
                    left: isLeft && isExpanded ? 80 : 0, // Padding for left dock
                    bottom: !isLeft ? 80 : 0, // Padding for bottom dock
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildContent(tabIndex, ref, context, isTwoPane),
                    ),
                  ),
                  
                  // Dock
                  Positioned(
                    left: isLeft ? 12 : 0,
                    right: isLeft ? null : 0,
                    top: isLeft ? 0 : null,
                    bottom: isLeft ? 0 : 12,
                    child: Center(
                      child: SafeArea(
                        child: FloatingDock(
                          items: dockItems,
                          selectedIndex: tabIndex,
                          isVertical: isLeft,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
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
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.forum_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Welcome to Abyss Web',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select a chat from the left panel or start a new one to begin sending secure P2P messages.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
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
        return const SizedBox.shrink(key: ValueKey('activity')); // Fallback, shouldn't be reached
      case 3:
        return const SettingsScreen(key: ValueKey('settings'));
      default:
        return const Center(child: Text('Unknown Tab'));
    }
  }
}
