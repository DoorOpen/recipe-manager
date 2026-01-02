import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/models.dart' as models;
import '../providers/pantry_provider.dart';

/// Screen for adding or editing a pantry item
class AddEditPantryItemScreen extends StatefulWidget {
  final models.PantryItem? item;

  const AddEditPantryItemScreen({super.key, this.item});

  @override
  State<AddEditPantryItemScreen> createState() => _AddEditPantryItemScreenState();
}

class _AddEditPantryItemScreenState extends State<AddEditPantryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;

  models.PantryLocation _selectedLocation = models.PantryLocation.pantry;
  DateTime? _expirationDate;
  DateTime? _purchaseDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.item?.quantity?.toString() ?? '',
    );
    _unitController = TextEditingController(text: widget.item?.unit ?? '');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');

    if (widget.item != null) {
      _selectedLocation = widget.item!.location;
      _expirationDate = widget.item!.expirationDate;
      _purchaseDate = widget.item!.purchaseDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isExpiration) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isExpiration) {
          _expirationDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final item = models.PantryItem(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        quantity: _quantityController.text.isNotEmpty
            ? double.tryParse(_quantityController.text)
            : null,
        unit: _unitController.text.trim().isNotEmpty
            ? _unitController.text.trim()
            : null,
        location: _selectedLocation,
        expirationDate: _expirationDate,
        purchaseDate: _purchaseDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.item?.createdAt ?? now,
        updatedAt: now,
      );

      final provider = context.read<PantryProvider>();
      if (widget.item == null) {
        await provider.addItem(item);
      } else {
        await provider.updateItem(item);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g., Milk, Eggs, Flour',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Quantity and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: '2',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'e.g., cups, lbs, oz',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Location
            DropdownButtonFormField<models.PantryLocation>(
              value: _selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Storage Location',
                prefixIcon: Icon(Icons.location_on),
              ),
              items: models.PantryLocation.values.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLocation = value;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            // Purchase Date
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Purchase Date'),
              subtitle: Text(
                _purchaseDate != null
                    ? '${_purchaseDate!.month}/${_purchaseDate!.day}/${_purchaseDate!.year}'
                    : 'Not set',
              ),
              trailing: _purchaseDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _purchaseDate = null;
                        });
                      },
                    )
                  : null,
              onTap: () => _selectDate(context, false),
            ),

            const Divider(),

            // Expiration Date
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Expiration Date'),
              subtitle: Text(
                _expirationDate != null
                    ? '${_expirationDate!.month}/${_expirationDate!.day}/${_expirationDate!.year}'
                    : 'Not set',
              ),
              trailing: _expirationDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _expirationDate = null;
                        });
                      },
                    )
                  : null,
              onTap: () => _selectDate(context, true),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any additional information',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
