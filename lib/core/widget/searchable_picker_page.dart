import 'package:flutter/material.dart';

import '../../data/model/fipe_option.dart';
import '../util/text_normalizer.dart';

class SearchablePickerPage extends StatefulWidget {
  final String title;
  final List<FipeOption> options;

  const SearchablePickerPage({required this.title, required this.options, super.key});

  @override
  State<SearchablePickerPage> createState() => _SearchablePickerPageState();
}

class _SearchablePickerPageState extends State<SearchablePickerPage> {
  final _controller = TextEditingController();
  List<FipeOption> _filtered = const [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    final query = normalizeText(_controller.text);
    setState(() {
      _filtered = query.isEmpty
          ? widget.options
          : widget.options.where((option) => normalizeText(option.name).contains(query)).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Pesquisar...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum resultado encontrado',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = _filtered[index];
                      return ListTile(
                        title: Text(option.name),
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
