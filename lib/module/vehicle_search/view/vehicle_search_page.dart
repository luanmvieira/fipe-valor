import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mvvm/view_model_widget.dart';
import '../../../core/widget/searchable_picker_page.dart';
import '../../../data/model/fipe_option.dart';
import '../../../data/model/vehicle_type.dart';
import '../viewmodel/vehicle_search_view_model.dart';

class VehicleSearchPage extends ViewModelWidget<VehicleSearchViewModel> {
  const VehicleSearchPage({required super.viewModel, super.key});

  static const _typeIcons = {
    VehicleType.carros: Icons.directions_car_rounded,
    VehicleType.motos: Icons.two_wheeler_rounded,
    VehicleType.caminhoes: Icons.local_shipping_rounded,
  };

  @override
  Widget build(BuildContext context, VehicleSearchViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) => viewModel.loadBrands());

    if (viewModel.result != null) {
      final data = viewModel.result!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.clearResult();
        context.push('/resultado', extra: data);
      });
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _typeIcons[viewModel.vehicleType],
                  key: ValueKey(viewModel.vehicleType),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Fipe Valor',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Descubra o valor de mercado e a foto do veiculo com base na tabela FIPE. Selecione o tipo de veículo, marca, modelo e ano para realizar a consulta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<VehicleType>(
                      segments: VehicleType.values
                          .map((type) => ButtonSegment(
                                value: type,
                                label: Text(type.label),
                                icon: Icon(_typeIcons[type], size: 18),
                              ))
                          .toList(),
                      selected: {viewModel.vehicleType},
                      onSelectionChanged: (selection) {
                        HapticFeedback.selectionClick();
                        viewModel.changeVehicleType(selection.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    _OptionField(
                      label: 'Marca',
                      icon: Icons.sell_outlined,
                      value: viewModel.selectedBrand,
                      options: viewModel.brands,
                      isLoading: viewModel.loadingBrands,
                      onChanged: viewModel.selectBrand,
                    ),
                    const SizedBox(height: 14),
                    _OptionField(
                      label: 'Modelo',
                      icon: Icons.category_outlined,
                      value: viewModel.selectedModel,
                      options: viewModel.models,
                      isLoading: viewModel.loadingModels,
                      onChanged: viewModel.selectModel,
                    ),
                    const SizedBox(height: 14),
                    _OptionField(
                      label: 'Ano',
                      icon: Icons.event_outlined,
                      value: viewModel.selectedYear,
                      options: viewModel.years,
                      isLoading: viewModel.loadingYears,
                      onChanged: viewModel.selectYear,
                    ),
                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(viewModel.errorMessage!, style: TextStyle(color: colorScheme.error)),
                          ),
                        ],
                      ),
                      if (viewModel.canRetry) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: viewModel.retry,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Tentar novamente'),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: viewModel.canSearch && !viewModel.isLoading
                          ? () {
                              HapticFeedback.mediumImpact();
                              viewModel.search();
                            }
                          : null,
                      icon: viewModel.isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.search_rounded),
                      label: viewModel.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Buscar valor FIPE'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionField extends StatelessWidget {
  final String label;
  final IconData icon;
  final FipeOption? value;
  final List<FipeOption> options;
  final bool isLoading;
  final ValueChanged<FipeOption> onChanged;

  const _OptionField({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = options.isNotEmpty && !isLoading;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled
          ? () async {
              final selected = await Navigator.of(context).push<FipeOption>(
                MaterialPageRoute(builder: (_) => SearchablePickerPage(title: label, options: options)),
              );
              if (selected != null) {
                HapticFeedback.selectionClick();
                onChanged(selected);
              }
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          value?.name ?? '',
          style: Theme.of(context).textTheme.bodyLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
