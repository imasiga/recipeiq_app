import 'package:flutter/material.dart';
import '../models/chef_catalog.dart';

class ChefPickerScreen extends StatefulWidget {
  /// If user already has a chef saved, pass it here to preselect.
  final String? initialChefId;

  const ChefPickerScreen({super.key, this.initialChefId});

  @override
  State<ChefPickerScreen> createState() => _ChefPickerScreenState();
}

class _ChefPickerScreenState extends State<ChefPickerScreen> {
  String? _selectedChefId;

  @override
  void initState() {
    super.initState();
    _selectedChefId = widget.initialChefId;
  }

  @override
  Widget build(BuildContext context) {
    final selected = ChefCatalog.byId(_selectedChefId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your Chef'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              selected == null
                  ? 'Pick a chef to personalize your recipes.'
                  : 'Selected: ${selected.name} • ${selected.cuisine}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: ChefCatalog.all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final chef = ChefCatalog.all[index];
                final isSelected = chef.id == _selectedChefId;

                return InkWell(
                  onTap: () => setState(() => _selectedChefId = chef.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor.withOpacity(0.35),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          child: Icon(chef.icon),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chef.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${chef.cuisine} • ${chef.description}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_selectedChefId == null)
                          ? null
                          : () => Navigator.pop(context, _selectedChefId),
                      child: const Text('Use this Chef'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}