import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
import '../../../services/catalog_service.dart';

class CatalogFilterSheet extends StatefulWidget {
  final void Function(String? contentType, String? section) onApply;

  const CatalogFilterSheet({super.key, required this.onApply});

  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  final _catalogService = CatalogService();
  CatalogFilters? _filters;
  String? _selectedContentType;
  String? _selectedSection;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filters = await _catalogService.getFilters();
      if (!mounted) return;
      setState(() {
        _filters = filters;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load filters.';
        _isLoading = false;
      });
    }
  }

  Widget _buildChips(List<String> options, String? selectedValue, ValueChanged<String> onSelected) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = option == selectedValue;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.textMuted.withOpacity(0.5),
          ),
          onSelected: (_) => onSelected(option),
        );
      }).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: _isLoading
          ? SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Format'),
                    const SizedBox(height: 12),
                    _buildChips(
                      ['All', ...?_filters?.contentTypes],
                      _selectedContentType ?? 'All',
                      (value) => setState(() {
                        _selectedContentType = value == 'All' ? null : value;
                      }),
                    ),
                    const SizedBox(height: 20),
                    const Text('Section'),
                    const SizedBox(height: 12),
                    _buildChips(
                      ['All', ...?_filters?.sections],
                      _selectedSection ?? 'All',
                      (value) => setState(() {
                        _selectedSection = value == 'All' ? null : value;
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(_selectedContentType, _selectedSection);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }
}
