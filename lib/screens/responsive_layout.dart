import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/providers/layout_provider.dart';
import 'package:abyss_chat/providers/call_provider.dart';
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

class LeftDockVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void toggle() {
    state = !state;
  }
}

final isLeftDockVisibleProvider = NotifierProvider<LeftDockVisibilityNotifier, bool>(() => LeftDockVisibilityNotifier());

class FloatingDockToggle extends ConsumerStatefulWidget {
  final bool isVisible;
  const FloatingDockToggle({super.key, required this.isVisible});

  @override
  ConsumerState<FloatingDockToggle> createState() => _FloatingDockToggleState();
}

class _FloatingDockToggleState extends ConsumerState<FloatingDockToggle> {
  Alignment _alignment = Alignment.centerLeft;
  double _dragY = 0.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: _alignment,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          _dragY += details.delta.dy;
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          setState(() {
            if (_dragY < -50 || velocity < -300) {
              _alignment = Alignment.topLeft;
            } else if (_dragY > 50 || velocity > 300) {
              _alignment = Alignment.bottomLeft;
            } else {
              _alignment = Alignment.centerLeft;
            }
            _dragY = 0.0;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: FloatingActionButton.small(
            elevation: 4,
            onPressed: () => ref.read(isLeftDockVisibleProvider.notifier).toggle(),
            child: Icon(widget.isVisible ? Icons.chevron_left : Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}

class ResponsiveLayout extends ConsumerWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize call provider to listen for incoming calls globally
    ref.watch(callProvider);
    
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

            final isLeftDockVisible = ref.watch(isLeftDockVisibleProvider);

            return Scaffold(
              body: Stack(
                children: [
                  // Main Content
                  Positioned.fill(
                    left: isLeft && isExpanded && isLeftDockVisible ? 80 : 0, // Padding for left dock
                    bottom: !isLeft ? 80 : 0, // Padding for bottom dock
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildContent(tabIndex, ref, context, isTwoPane),
                    ),
                  ),
                  
                  // Dock
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: isLeft ? (isLeftDockVisible ? 12 : -100) : 0,
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
                  
                  // Dock Toggle Button (Floating)
                  if (isLeft)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: isLeftDockVisible ? 85 : 8,
                      top: 0,
                      bottom: 0,
                      child: FloatingDockToggle(isVisible: isLeftDockVisible),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const HomeScreen(isDesktop: true),
                ),
              ),
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
                          child: SingleChildScrollView(
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
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
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
