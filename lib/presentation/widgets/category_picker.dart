import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';

// ─── Category Picker ──────────────────────────────────────────────────────────

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.type,
    required this.onChanged,
  });

  final CategoryEntity? selected;
  final TransactionType type;
  final ValueChanged<CategoryEntity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCategorySheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected != null
                ? selected!.color.withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected!.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(selected!.icon, color: selected!.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected!.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      selected!.type.label,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Icon(Icons.category_rounded,
                  color: Colors.white38, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Select or create a category',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ],
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategorySheet(
        currentType: type,
        onSelect: onChanged,
      ),
    );
  }
}

// ─── Category Sheet ───────────────────────────────────────────────────────────

class CategorySheet extends ConsumerStatefulWidget {
  const CategorySheet({
    super.key,
    required this.currentType,
    required this.onSelect,
  });

  final TransactionType currentType;
  final ValueChanged<CategoryEntity?> onSelect;

  @override
  ConsumerState<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<CategorySheet> {
  CategoryEntity? _selectedParent;

  bool _showNewForm = false;
  CategoryEntity? _editingCategory;
  int? _newCategoryParentId;
  final _nameController = TextEditingController();
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  late TransactionType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 12),
              child: Row(
                children: [
                  if (_selectedParent != null && !_showNewForm)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white70),
                      onPressed: () =>
                          setState(() => _selectedParent = null),
                    )
                  else
                    const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      _showNewForm
                          ? (_editingCategory != null
                              ? 'Edit Category'
                              : 'New Category')
                          : (_selectedParent != null
                              ? _selectedParent!.name
                              : 'Category'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _toggleNewForm,
                    icon: Icon(_showNewForm ? Icons.close : Icons.add,
                        size: 16),
                    label: Text(_showNewForm ? 'Cancel' : 'New'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),

            // New / edit form
            if (_showNewForm)
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, st) => const SizedBox.shrink(),
                data: (cats) => _NewCategoryForm(
                  nameController: _nameController,
                  selectedColorIndex: _selectedColorIndex,
                  selectedIconIndex: _selectedIconIndex,
                  selectedType: _selectedType,
                  isEditing: _editingCategory != null,
                  onColorChanged: (i) =>
                      setState(() => _selectedColorIndex = i),
                  onIconChanged: (i) =>
                      setState(() => _selectedIconIndex = i),
                  onTypeChanged: (t) => setState(() => _selectedType = t),
                  onSave: _saveCategory,
                  parentOptions:
                      cats.where((c) => c.parentId == null).toList(),
                  selectedParentId: _newCategoryParentId,
                  onParentChanged: (id) =>
                      setState(() => _newCategoryParentId = id),
                ),
              ),

            // Category list / grid
            if (!_showNewForm)
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  ),
                  error: (e, _) => Center(
                    child: Text(e.toString(),
                        style: const TextStyle(color: AppTheme.burnColor)),
                  ),
                  data: (cats) => _selectedParent == null
                      ? _ParentGrid(
                          cats: cats,
                          currentType: widget.currentType,
                          controller: controller,
                          onParentTapped: (parent) {
                            final hasSubs =
                                cats.any((c) => c.parentId == parent.id);
                            if (hasSubs) {
                              setState(() => _selectedParent = parent);
                            } else {
                              widget.onSelect(parent);
                              Navigator.of(context).pop();
                            }
                          },
                          onEdit: (cat) => _startEdit(cat, cats),
                          onDelete: _confirmDelete,
                        )
                      : _SubcategoryList(
                          parent: _selectedParent!,
                          subs: cats
                              .where(
                                  (c) => c.parentId == _selectedParent!.id)
                              .toList(),
                          controller: controller,
                          onSelect: (sub) {
                            widget.onSelect(sub);
                            Navigator.of(context).pop();
                          },
                          onEdit: (cat) => _startEdit(cat, cats),
                          onDelete: _confirmDelete,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleNewForm() {
    setState(() {
      _showNewForm = !_showNewForm;
      if (!_showNewForm) {
        _editingCategory = null;
        _newCategoryParentId = null;
        _nameController.clear();
        _selectedColorIndex = 0;
        _selectedIconIndex = 0;
        _selectedType = widget.currentType;
      }
    });
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final color = AppConstants.categoryColors[_selectedColorIndex];
    final icon = AppConstants.categoryIconOptions[_selectedIconIndex];
    final isEdit = _editingCategory != null;

    final entity = CategoryEntity(
      id: isEdit ? _editingCategory!.id : 0,
      name: name,
      colorValue: color.toARGB32(),
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily ?? 'MaterialIcons',
      type: _selectedType,
      parentId: isEdit ? _editingCategory!.parentId : _newCategoryParentId,
    );

    final savedId = await ref.read(categoryRepositoryProvider).save(entity);

    if (isEdit) {
      if (mounted) {
        setState(() {
          _showNewForm = false;
          _editingCategory = null;
          _newCategoryParentId = null;
          _nameController.clear();
          _selectedColorIndex = 0;
          _selectedIconIndex = 0;
          _selectedType = widget.currentType;
        });
      }
    } else {
      final saved =
          await ref.read(categoryRepositoryProvider).getById(savedId);
      if (saved != null && mounted) {
        widget.onSelect(saved);
        Navigator.of(context).pop();
      }
    }
  }

  void _startEdit(CategoryEntity cat, List<CategoryEntity> allCats) {
    final colorIdx = AppConstants.categoryColors
        .indexWhere((c) => c.toARGB32() == cat.colorValue);
    final iconIdx = AppConstants.categoryIconOptions
        .indexWhere((ic) => ic.codePoint == cat.iconCodePoint);
    _nameController.text = cat.name;
    setState(() {
      _editingCategory = cat;
      _newCategoryParentId = cat.parentId;
      _selectedColorIndex = colorIdx < 0 ? 0 : colorIdx;
      _selectedIconIndex = iconIdx < 0 ? 0 : iconIdx;
      _selectedType = cat.type;
      _showNewForm = true;
    });
  }

  Future<void> _confirmDelete(CategoryEntity cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Category',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${cat.name}"? Existing transactions won\'t be affected.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.burnColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).delete(cat.id);
    }
  }
}

// ─── Parent Category Grid ─────────────────────────────────────────────────────

class _ParentGrid extends StatelessWidget {
  const _ParentGrid({
    required this.cats,
    required this.currentType,
    required this.controller,
    required this.onParentTapped,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CategoryEntity> cats;
  final TransactionType currentType;
  final ScrollController controller;
  final ValueChanged<CategoryEntity> onParentTapped;
  final ValueChanged<CategoryEntity> onEdit;
  final ValueChanged<CategoryEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final parents = cats
        .where((c) => c.parentId == null && c.type == currentType)
        .toList();

    if (parents.isEmpty) {
      return const Center(
        child: Text(
          'No categories yet.\nTap "New" to create one.',
          style: TextStyle(color: Colors.white38),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: parents.length,
      itemBuilder: (_, i) {
        final parent = parents[i];
        final hasSubs = cats.any((c) => c.parentId == parent.id);
        return GestureDetector(
          onLongPress: () => _showActions(context, parent),
          onTap: () => onParentTapped(parent),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: parent.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(parent.icon, color: parent.color, size: 22),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    parent.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSubs)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.chevron_right_rounded,
                        color: Colors.white24, size: 14),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActions(BuildContext context, CategoryEntity cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.edit_rounded, color: Colors.white70),
              title: const Text('Edit',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                onEdit(cat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.burnColor),
              title: const Text('Delete',
                  style: TextStyle(color: AppTheme.burnColor)),
              onTap: () {
                Navigator.pop(context);
                onDelete(cat);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subcategory List ─────────────────────────────────────────────────────────

class _SubcategoryList extends StatelessWidget {
  const _SubcategoryList({
    required this.parent,
    required this.subs,
    required this.controller,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryEntity parent;
  final List<CategoryEntity> subs;
  final ScrollController controller;
  final ValueChanged<CategoryEntity> onSelect;
  final ValueChanged<CategoryEntity> onEdit;
  final ValueChanged<CategoryEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    if (subs.isEmpty) {
      return const Center(
        child: Text('No subcategories.',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: subs.length,
      itemBuilder: (_, i) {
        final sub = subs[i];
        return ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          leading: CircleAvatar(
            backgroundColor: sub.color.withValues(alpha: 0.2),
            child: Icon(sub.icon, color: sub.color, size: 20),
          ),
          title: Text(sub.name,
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(parent.name,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: Colors.white38),
                onPressed: () => onEdit(sub),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppTheme.burnColor),
                onPressed: () => onDelete(sub),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          onTap: () => onSelect(sub),
        );
      },
    );
  }
}

// ─── New Category Form ────────────────────────────────────────────────────────

class _NewCategoryForm extends StatelessWidget {
  const _NewCategoryForm({
    required this.nameController,
    required this.selectedColorIndex,
    required this.selectedIconIndex,
    required this.onColorChanged,
    required this.onIconChanged,
    required this.onSave,
    required this.isEditing,
    required this.selectedType,
    required this.onTypeChanged,
    required this.parentOptions,
    required this.selectedParentId,
    required this.onParentChanged,
  });

  final TextEditingController nameController;
  final int selectedColorIndex;
  final int selectedIconIndex;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<int> onIconChanged;
  final VoidCallback onSave;
  final bool isEditing;
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;
  final List<CategoryEntity> parentOptions;
  final int? selectedParentId;
  final ValueChanged<int?> onParentChanged;

  @override
  Widget build(BuildContext context) {
    final filteredParents =
        parentOptions.where((c) => c.type == selectedType).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type toggle
          Row(
            children: TransactionType.values.map((t) {
              final isSelected = selectedType == t;
              final color = t == TransactionType.burn
                  ? AppTheme.burnColor
                  : AppTheme.storeColor;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTypeChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 38,
                    margin: EdgeInsets.only(
                        right: t == TransactionType.burn ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.2)
                          : AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.6)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t == TransactionType.burn
                              ? Icons.local_fire_department_rounded
                              : Icons.savings_rounded,
                          size: 14,
                          color: isSelected ? color : Colors.white38,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          t.label,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Name field
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Category name',
              prefixIcon: Icon(Icons.label_rounded),
            ),
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          // Parent selector (only for new categories)
          if (!isEditing && filteredParents.isNotEmpty) ...[
            const Text('Parent (optional)',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButton<int?>(
              value: filteredParents.any((c) => c.id == selectedParentId)
                  ? selectedParentId
                  : null,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceColor,
              hint: const Text('None (top-level)',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              style:
                  const TextStyle(color: Colors.white, fontSize: 13),
              underline: Container(height: 1, color: Colors.white12),
              onChanged: onParentChanged,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None (top-level)',
                      style: TextStyle(color: Colors.white54)),
                ),
                ...filteredParents.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.icon, color: c.color, size: 16),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Color row
          const Text('Color',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.categoryColors.length,
              itemBuilder: (_, i) {
                final selected = i == selectedColorIndex;
                return GestureDetector(
                  onTap: () => onColorChanged(i),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.categoryColors[i],
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Icon row
          const Text('Icon',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.categoryIconOptions.length,
              itemBuilder: (_, i) {
                final selected = i == selectedIconIndex;
                final color =
                    AppConstants.categoryColors[selectedColorIndex];
                return GestureDetector(
                  onTap: () => onIconChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.3)
                          : AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: color)
                          : Border.all(color: Colors.white10),
                    ),
                    child: Icon(
                      AppConstants.categoryIconOptions[i],
                      color: selected ? color : Colors.white38,
                      size: 18,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child:
                  Text(isEditing ? 'Update Category' : 'Create Category'),
            ),
          ),
        ],
      ),
    );
  }
}
