import 'package:flutter/widgets.dart';

abstract class ViewModelWidget<T extends ChangeNotifier> extends StatefulWidget {
  final T viewModel;

  const ViewModelWidget({required this.viewModel, super.key});

  Widget build(BuildContext context, T viewModel);

  void disposeWidget() {}

  @override
  State<ViewModelWidget<T>> createState() => _ViewModelWidgetState<T>();
}

class _ViewModelWidgetState<T extends ChangeNotifier> extends State<ViewModelWidget<T>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didUpdateWidget(covariant ViewModelWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
    }
  }

  void _onViewModelChanged() => setState(() {});

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    widget.disposeWidget();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.build(context, widget.viewModel);
}
