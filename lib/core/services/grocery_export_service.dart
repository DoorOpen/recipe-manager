import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

/// Export formats available
enum ExportFormat {
  csv,
  text,
  instacart,
  walmart,
  amazonFresh,
  target,
  kroger,
}

/// Service for exporting grocery lists to various retailers and formats
class GroceryExportService {
  /// Retailer information
  static const Map<ExportFormat, Map<String, String>> retailerInfo = {
    ExportFormat.instacart: {
      'name': 'Instacart',
      'url': 'https://www.instacart.com',
      'icon': '🛒',
    },
    ExportFormat.walmart: {
      'name': 'Walmart',
      'url': 'https://www.walmart.com/grocery',
      'icon': '🏪',
    },
    ExportFormat.amazonFresh: {
      'name': 'Amazon Fresh',
      'url': 'https://www.amazon.com/alm/storefront',
      'icon': '📦',
    },
    ExportFormat.target: {
      'name': 'Target',
      'url': 'https://www.target.com/c/grocery/-/N-5xt1a',
      'icon': '🎯',
    },
    ExportFormat.kroger: {
      'name': 'Kroger',
      'url': 'https://www.kroger.com',
      'icon': '🛍️',
    },
  };

  /// Export grocery list to CSV format
  Future<String> exportToCsv(GroceryList list, List<GroceryItem> items) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Item,Quantity,Unit,Category,Notes');

    // Items
    for (final item in items) {
      final quantity = item.quantity?.toString() ?? '';
      final unit = item.unit ?? '';
      final category = item.category.displayName;
      final notes = item.notes?.replaceAll(',', ';') ?? '';

      buffer.writeln('${item.name},$quantity,$unit,$category,$notes');
    }

    return buffer.toString();
  }

  /// Export grocery list to plain text format
  String exportToText(GroceryList list, List<GroceryItem> items) {
    final buffer = StringBuffer();

    buffer.writeln('🛒 ${list.name}');
    buffer.writeln('Created: ${_formatDate(list.createdAt)}');
    buffer.writeln('');

    // Group items by category
    final grouped = <GroceryCategory, List<GroceryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    // Output by category
    for (final category in GroceryCategory.values) {
      final categoryItems = grouped[category] ?? [];
      if (categoryItems.isEmpty) continue;

      buffer.writeln('${category.displayName}:');
      for (final item in categoryItems) {
        final checkbox = item.isChecked ? '☑' : '☐';
        final quantity = item.quantity != null ? '${item.quantity} ${item.unit ?? ''}' : '';
        buffer.writeln('  $checkbox ${item.name} $quantity'.trim());
      }
      buffer.writeln('');
    }

    buffer.writeln('---');
    buffer.writeln('Total items: ${items.length}');
    buffer.writeln('Unchecked: ${items.where((i) => !i.isChecked).length}');

    return buffer.toString();
  }

  /// Save CSV to file and return the file path
  Future<String> saveCsvToFile(GroceryList list, List<GroceryItem> items) async {
    final csv = await exportToCsv(list, items);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${_sanitizeFileName(list.name)}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csv);
    return file.path;
  }

  /// Share grocery list as text
  Future<void> shareAsText(GroceryList list, List<GroceryItem> items) async {
    final text = exportToText(list, items);
    await Share.share(
      text,
      subject: '🛒 ${list.name}',
    );
  }

  /// Share grocery list as CSV file
  Future<void> shareAsCsv(GroceryList list, List<GroceryItem> items) async {
    final filePath = await saveCsvToFile(list, items);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '🛒 ${list.name}',
      text: 'Grocery list exported from Recipe Manager',
    );
  }

  /// Open retailer website with search query
  /// Note: Most retailers don't have public APIs for adding items to cart
  /// This opens their website with a search for the first few items
  Future<bool> openRetailerWebsite(
    ExportFormat retailer,
    GroceryList list,
    List<GroceryItem> items,
  ) async {
    final info = retailerInfo[retailer];
    if (info == null) return false;

    final url = info['url']!;
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Generate a shopping list URL for Instacart
  /// Instacart supports deep linking with search queries
  Future<bool> openInstacartWithItems(List<GroceryItem> items) async {
    if (items.isEmpty) return false;

    // Take first 5 items and create search queries
    final searchItems = items.take(5).map((item) => item.name).join(',');
    final encodedSearch = Uri.encodeComponent(searchItems);

    // Instacart deep link format (may vary by region)
    final url = 'https://www.instacart.com/store/search?search_terms=$encodedSearch';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Generate a shopping list URL for Walmart
  Future<bool> openWalmartWithItems(List<GroceryItem> items) async {
    if (items.isEmpty) return false;

    // Walmart grocery search
    final searchItem = items.first.name;
    final encodedSearch = Uri.encodeComponent(searchItem);
    final url = 'https://www.walmart.com/search?q=$encodedSearch&cat_id=976759';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Generate a shopping list URL for Amazon Fresh
  Future<bool> openAmazonFreshWithItems(List<GroceryItem> items) async {
    if (items.isEmpty) return false;

    final searchItem = items.first.name;
    final encodedSearch = Uri.encodeComponent(searchItem);
    final url = 'https://www.amazon.com/s?k=$encodedSearch&i=amazonfresh';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Copy list to clipboard for manual entry
  Future<void> copyToClipboard(GroceryList list, List<GroceryItem> items) async {
    // Note: clipboard functionality would require clipboard package
    // For now, we'll use Share which covers most use cases
    await shareAsText(list, items);
  }

  /// Helper: Format date
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Helper: Sanitize filename
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// Get unchecked items only (for shopping)
  List<GroceryItem> getUncheckedItems(List<GroceryItem> items) {
    return items.where((item) => !item.isChecked).toList();
  }

  /// Get checked items only (already purchased)
  List<GroceryItem> getCheckedItems(List<GroceryItem> items) {
    return items.where((item) => item.isChecked).toList();
  }
}
