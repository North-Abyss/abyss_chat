import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/core/utils/shared_prefs_helper.dart';
import 'package:abyss_chat/core/widgets/abyss_snackbar.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _todoController = TextEditingController();
  List<String> _todos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPrefsHelper.instance;
    setState(() {
      _notesController.text = prefs.getString('my_personal_notes') ?? '';
      _statusController.text = prefs.getString('my_current_status') ?? '';
      _todos = prefs.getStringList('my_todos') ?? [];
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPrefsHelper.instance;
    await prefs.setString('my_personal_notes', _notesController.text);
  }

  Future<void> _saveStatus() async {
    final prefs = await SharedPrefsHelper.instance;
    await prefs.setString('my_current_status', _statusController.text);
    // Ideally broadcast status to peers here
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPrefsHelper.instance;
    await prefs.setStringList('my_todos', _todos);
  }

  void _addTodo() {
    final text = _todoController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _todos.add(text);
        _todoController.clear();
      });
      _saveTodos();
    }
  }

  void _removeTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _statusController.dispose();
    _todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Productivity', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.sticky_note_2), text: 'Notes'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'To-Do'),
            Tab(icon: Icon(Icons.person_pin), text: 'Status'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Notes Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Personal Scratchpad', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary)),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Jot down ideas, links, or draft messages...',
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (_) => _saveNotes(),
                  ),
                ),
              ],
            ),
          ),
          
          // To-Do Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _todoController,
                        decoration: InputDecoration(
                          hintText: 'Add a new task...',
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (_) => _addTodo(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      onPressed: _addTodo,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _todos.isEmpty
                      ? Center(child: Text('All caught up!', style: TextStyle(color: cs.onSurfaceVariant)))
                      : ListView.builder(
                          itemCount: _todos.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 0,
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(Icons.circle_outlined, color: cs.primary),
                                title: Text(_todos[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _removeTodo(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Status Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Set Global Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary)),
                const SizedBox(height: 8),
                Text('Let your peers know what you are up to.', style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 24),
                TextField(
                  controller: _statusController,
                  decoration: InputDecoration(
                    labelText: 'Current Status',
                    hintText: 'e.g. In a meeting, Working deep, Available',
                    prefixIcon: const Icon(Icons.emoji_people),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    _saveStatus();
                    AbyssSnackBar.show(context, 'Status updated', type: SnackBarType.success);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Update Status'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
