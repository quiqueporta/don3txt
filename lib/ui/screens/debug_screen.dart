import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  late final TextEditingController _controller;
  late final String _originalContent;

  @override
  void initState() {
    super.initState();

    final notifier = context.read<TodoListNotifier>();
    _originalContent = notifier.rawContent;
    _controller = TextEditingController(text: _originalContent);
  }

  Future<void> _save() async {
    final notifier = context.read<TodoListNotifier>();
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final saved = await notifier.saveRawContent(_controller.text,
        editedFrom: _originalContent);

    if (!saved) {
      messenger.showSnackBar(SnackBar(content: Text(loc.fileChangedElsewhere)));

      return;
    }

    navigator.pop();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).debug),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
