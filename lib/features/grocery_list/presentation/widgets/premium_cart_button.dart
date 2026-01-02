import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/premium_cart_service.dart';

/// Premium button for automated cart creation
/// Shows different states: idle, loading, success, error
/// Handles premium feature gating
class PremiumCartButton extends StatefulWidget {
  final List<GroceryItem> items;
  final bool isPremium;
  final String retailer; // 'walmart', 'instacart', etc.
  final VoidCallback? onUpgradeRequired;

  const PremiumCartButton({
    super.key,
    required this.items,
    required this.isPremium,
    this.retailer = 'walmart',
    this.onUpgradeRequired,
  });

  @override
  State<PremiumCartButton> createState() => _PremiumCartButtonState();
}

class _PremiumCartButtonState extends State<PremiumCartButton> {
  late PremiumCartService _cartService;
  CartJob? _currentJob;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  void _initService() {
    // Initialize with your backend URL
    // TODO: Replace with actual backend URL from config
    _cartService = PremiumCartService(
      baseUrl: 'http://localhost:3000', // Change to production URL
      getAuthToken: () {
        // TODO: Get actual auth token from user session
        return 'user-token-here';
      },
    );
  }

  Future<void> _createCart() async {
    // Check if premium
    if (!widget.isPremium) {
      _showUpgradeDialog();
      return;
    }

    if (widget.items.isEmpty) {
      _showError('No items in grocery list');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentJob = null;
    });

    try {
      // Create cart job
      final job = await _cartService.createWalmartCart(widget.items);

      setState(() {
        _currentJob = job;
      });

      // Watch for completion
      await for (final updatedJob in _cartService.watchCartJob(job.jobId)) {
        setState(() {
          _currentJob = updatedJob;
        });

        if (updatedJob.isComplete) {
          _handleJobCompletion(updatedJob);
          break;
        }
      }
    } on PremiumRequiredException catch (e) {
      _showUpgradeDialog();
    } on CartServiceException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleJobCompletion(CartJob job) {
    if (job.isSuccess && job.shareUrl != null) {
      _openCartUrl(job.shareUrl!);
      _showSuccess(job);
    } else if (job.status == CartJobStatus.failed) {
      _showError(job.errorMessage ?? 'Cart creation failed');
    } else if (job.status == CartJobStatus.cancelled) {
      _showError('Cart creation was cancelled');
    }
  }

  Future<void> _openCartUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open cart URL');
    }
  }

  void _showSuccess(CartJob job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cart created! Opening Walmart with ${widget.items.length} items...',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 12),
            Text('Premium Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Automated cart creation is a premium feature.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'With Premium, you can:',
            ),
            const SizedBox(height: 8),
            _buildFeatureBullet('Automatically fill shopping carts'),
            _buildFeatureBullet('Save 5-10 minutes per grocery trip'),
            _buildFeatureBullet('Works with Walmart, Instacart, and more'),
            _buildFeatureBullet('Unlimited cart creations'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '\$9.99/month',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onUpgradeRequired?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (_isLoading && _currentJob != null) {
      return _buildProcessingButton();
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _createCart,
      icon: widget.isPremium
          ? const Icon(Icons.auto_awesome)
          : const Icon(Icons.lock),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.isPremium ? 'Auto-Fill Cart' : 'Shop on Walmart'),
          if (widget.isPremium) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AUTO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ],
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.isPremium ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildProcessingButton() {
    final job = _currentJob!;
    final progress = _calculateProgress(job);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(job.status),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (job.logs.isNotEmpty)
                      Text(
                        job.logs.last.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% complete',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(CartJobStatus status) {
    switch (status) {
      case CartJobStatus.pending:
        return 'Queued for processing...';
      case CartJobStatus.processing:
        return 'Creating your cart...';
      case CartJobStatus.completed:
        return 'Cart created!';
      case CartJobStatus.failed:
        return 'Failed';
      case CartJobStatus.cancelled:
        return 'Cancelled';
    }
  }

  double _calculateProgress(CartJob job) {
    if (job.status == CartJobStatus.completed) return 1.0;
    if (job.status == CartJobStatus.failed) return 0.0;
    if (job.status == CartJobStatus.cancelled) return 0.0;

    // Estimate progress based on logs
    final totalItems = job.itemCount;
    final processedItems = job.logs
        .where((log) => log.message.contains('Successfully added'))
        .length;

    if (totalItems == 0) return 0.5; // Default to 50% if unknown

    return (processedItems / totalItems).clamp(0.0, 0.95);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildButton(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
