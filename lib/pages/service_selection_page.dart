import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// =============================================================================
// THEME — change primaryMaroon once here to re-theme the whole screen.
// =============================================================================

class AppColors {
  AppColors._();

  static const Color primaryMaroon = Color(0xFF800020);
  static const Color background = Color(0xFFFFF8DC); // matches existing app bg
  static const Color cardBackground = Colors.white;
  static const Color selectedBackground = Color(0xFFF4E6EA); // subtle maroon tint
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF757575);
}

// =============================================================================
// MODEL
// =============================================================================

/// Represents a single bookable salon service (e.g. "Wolf Cut", "Balayage").
///
/// Immutable — selection state changes go through [copyWith], so widgets
/// rebuild predictably when the provider updates the list.
class SalonService {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String imageUrl;
  final bool isSelected;

  /// Optional grouping, e.g. "Haircut", "Hair Color". Handy later if you
  /// want to restrict one selection per category, similar to how
  /// CheckoutManager.hasCategoryService worked in the legacy checkout.
  final String category;

  const SalonService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.imageUrl,
    this.isSelected = false,
    this.category = '',
  });

  SalonService copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    double? price,
    String? imageUrl,
    bool? isSelected,
    String? category,
  }) {
    return SalonService(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isSelected: isSelected ?? this.isSelected,
      category: category ?? this.category,
    );
  }

  /// "50 MINS" or "1 HR 30 MINS" for durations over an hour.
  String get formattedDuration {
    if (durationMinutes < 60) return '$durationMinutes MINS';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    final hourLabel = '$hours HR${hours > 1 ? 'S' : ''}';
    return mins == 0 ? hourLabel : '$hourLabel $mins MINS';
  }

  /// "₱1,000" — no decimals, thousands separator (standard PH salon pricing display).
  String get formattedPrice => formatPeso(price);

  /// Shared formatter so the price display is identical everywhere
  /// (card, details sheet, summary bar) without duplicating logic.
  static String formatPeso(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SalonService && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// PROVIDER — single source of truth for the service list + selection state
// =============================================================================

/// Holds the master service list plus current selection state for one
/// booking session. Wrap the Service Selection screen (and anything after
/// it, up to checkout/schedule) with a single instance via
/// ChangeNotifierProvider so selection survives navigating to the details
/// sheet and back.
class ServiceSelectionProvider extends ChangeNotifier {
  ServiceSelectionProvider(List<SalonService> initialServices)
      : _allServices = List<SalonService>.from(initialServices);

  final List<SalonService> _allServices;

  /// id -> service. Map gives O(1) toggle/lookup and keeps insertion order.
  final Map<String, SalonService> _selectedById = {};

  List<SalonService> get allServices => List.unmodifiable(_allServices);

  List<SalonService> get selectedServices =>
      List.unmodifiable(_selectedById.values);

  int get selectedCount => _selectedById.length;

  bool get hasSelection => _selectedById.isNotEmpty;

  bool isSelected(String serviceId) => _selectedById.containsKey(serviceId);

  int get totalDurationMinutes => _selectedById.values
      .fold(0, (sum, service) => sum + service.durationMinutes);

  double get totalPrice =>
      _selectedById.values.fold(0.0, (sum, service) => sum + service.price);

  /// Toggles selection for a service. Used by the "Add Service" /
  /// "Remove Service" button inside the details bottom sheet — the grid
  /// itself never mutates selection directly, only opens the sheet.
  void toggleService(SalonService service) {
    if (_selectedById.containsKey(service.id)) {
      _selectedById.remove(service.id);
    } else {
      _selectedById[service.id] = service;
    }
    _syncSelectionFlags();
    notifyListeners();
  }

  void removeService(String serviceId) {
    if (_selectedById.remove(serviceId) != null) {
      _syncSelectionFlags();
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedById.clear();
    _syncSelectionFlags();
    notifyListeners();
  }

  /// Keeps SalonService.isSelected in sync across the master list so
  /// SalonServiceCard can read isSelected directly instead of re-querying a map
  /// on every build.
  void _syncSelectionFlags() {
    for (var i = 0; i < _allServices.length; i++) {
      final service = _allServices[i];
      final shouldBeSelected = _selectedById.containsKey(service.id);
      if (service.isSelected != shouldBeSelected) {
        _allServices[i] = service.copyWith(isSelected: shouldBeSelected);
      }
    }
  }
}

// =============================================================================
// WIDGET — grid card
// =============================================================================

/// Grid tile for a single service. Tapping always opens the details
/// bottom sheet — selection never happens directly on the grid. This
/// keeps the grid scannable and prevents accidental taps from adding a
/// service the user only meant to preview.
class SalonServiceCard extends StatelessWidget {
  final SalonService service;
  final VoidCallback onTap;

  const SalonServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = service.isSelected;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBackground : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryMaroon : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // Column + Expanded/Flexible everywhere below is what prevents
        // RenderFlex overflow on smaller screens or long service names.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      service.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE8D5C4), Color(0xFFF5E6D3)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.spa_outlined, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryMaroon,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title capped at 2 lines with ellipsis, never overflows.
                    Flexible(
                      child: Text(
                        service.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.formattedDuration,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.formattedPrice,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryMaroon,
                      ),
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

// =============================================================================
// WIDGET — details bottom sheet
// =============================================================================

/// Opens the service details bottom sheet. Call this instead of
/// showModalBottomSheet directly so every caller gets the same shape,
/// scroll behavior, and transparent backdrop config.
///
/// IMPORTANT: showModalBottomSheet builds its content inside the
/// Navigator's Overlay, which sits OUTSIDE the widget subtree that
/// ServiceSelectionProvider wraps. So `provider` must be passed in and
/// re-provided here with `.value` — otherwise ServiceDetailsSheet's
/// `context.watch<ServiceSelectionProvider>()` throws "Could not find
/// the correct Provider".
Future<void> showServiceDetailsSheet(
  BuildContext context,
  SalonService service,
  ServiceSelectionProvider provider,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: ServiceDetailsSheet(service: service),
    ),
  );
}

class ServiceDetailsSheet extends StatelessWidget {
  final SalonService service;

  const ServiceDetailsSheet({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    // watch() (not read()) so the CTA flips instantly if selection changes
    // from elsewhere while this sheet happens to be open.
    final provider = context.watch<ServiceSelectionProvider>();
    final isSelected = provider.isSelected(service.id);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean top-right ✕ close affordance — not a "Cancel" button.
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              splashRadius: 20,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                service.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8D5C4), Color(0xFFF5E6D3)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.spa_outlined, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            service.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(child: _InfoChip(icon: Icons.access_time, label: service.formattedDuration)),
              const SizedBox(width: 10),
              Flexible(child: _InfoChip(icon: Icons.payments_outlined, label: service.formattedPrice)),
            ],
          ),
          const SizedBox(height: 26),

          // Primary CTA — label + color flip based on current selection.
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                provider.toggleService(service);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.grey[200] : AppColors.primaryMaroon,
                foregroundColor: isSelected ? AppColors.textPrimary : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isSelected ? 'Remove Service' : '+ Add Service',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Secondary CTA — "Keep Browsing" instead of e-commerce "Continue Shopping".
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Keep Browsing',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryMaroon),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryMaroon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGET — sticky bottom summary bar
// =============================================================================

/// Sticky/floating summary bar shown once at least one service is
/// selected. Purely presentational — the parent screen owns the
/// show/hide animation and passes in the already-computed numbers.
class SelectionSummaryBar extends StatelessWidget {
  final int serviceCount;
  final int totalDurationMinutes;
  final String totalPriceFormatted;
  final VoidCallback onContinue;

  const SelectionSummaryBar({
    super.key,
    required this.serviceCount,
    required this.totalDurationMinutes,
    required this.totalPriceFormatted,
    required this.onContinue,
  });

  String get _durationLabel {
    if (totalDurationMinutes < 60) return '$totalDurationMinutes mins';
    final hours = totalDurationMinutes ~/ 60;
    final mins = totalDurationMinutes % 60;
    return mins == 0 ? '$hours hr' : '$hours hr $mins mins';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.primaryMaroon,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryMaroon.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: live summary. Expanded + ellipsis so long counts or
            // durations never push the CTA off-screen on narrow devices.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$serviceCount Service${serviceCount > 1 ? 's' : ''} • $_durationLabel',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalPriceFormatted,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Primary action — takes user to schedule selection, never
            // called "checkout" here since scheduling comes first.
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryMaroon,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PAGE — entry point for a single service category screen
// =============================================================================

/// Entry point for a single service category screen (e.g. "Haircut",
/// "Hair Color"). Wraps the grid with its own ChangeNotifierProvider —
/// if you need selection to persist across multiple category tabs in one
/// booking session, hoist ServiceSelectionProvider higher up the tree
/// instead and pass `.value` here.
class ServiceSelectionPage extends StatelessWidget {
  final String categoryTitle;
  final List<SalonService> services;

  /// Called when the person taps "Select Schedule" with at least one
  /// service picked. Receives the selected services plus their combined
  /// duration/price so the CALLER decides what happens next — e.g. push
  /// your existing StaffSchedulingPage / PaymentPage. Keeping this as a
  /// callback (instead of importing those pages here) avoids a circular
  /// import back to main.dart.
  final void Function(
    BuildContext context,
    List<SalonService> selectedServices,
    int totalDurationMinutes,
    double totalPrice,
  )? onContinue;

  const ServiceSelectionPage({
    super.key,
    required this.categoryTitle,
    required this.services,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceSelectionProvider(services),
      child: _ServiceSelectionView(categoryTitle: categoryTitle, onContinue: onContinue),
    );
  }
}

class _ServiceSelectionView extends StatelessWidget {
  final String categoryTitle;
  final void Function(
    BuildContext context,
    List<SalonService> selectedServices,
    int totalDurationMinutes,
    double totalPrice,
  )? onContinue;

  const _ServiceSelectionView({required this.categoryTitle, this.onContinue});

  void _openDetails(BuildContext context, SalonService service) {
    final provider = context.read<ServiceSelectionProvider>();
    showServiceDetailsSheet(context, service, provider);
  }

  void _goToSchedule(BuildContext context, ServiceSelectionProvider provider) {
    if (onContinue != null) {
      onContinue!(
        context,
        provider.selectedServices,
        provider.totalDurationMinutes,
        provider.totalPrice,
      );
      return;
    }
    // Fallback debug view — only shows if you forgot to pass onContinue.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Select Schedule')),
          body: Center(
            child: Text(
              '${provider.selectedCount} service(s) • '
              '${provider.totalDurationMinutes} mins • '
              '${SalonService.formatPeso(provider.totalPrice)}',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          categoryTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      // Consumer scopes rebuilds to just this Stack — the AppBar above
      // doesn't need to rebuild every time selection changes.
      body: Consumer<ServiceSelectionProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              Padding(
                // Bottom padding reserves space so the sticky bar never
                // covers the last grid row — grid itself stays unaware
                // of the bar's existence.
                padding: EdgeInsets.fromLTRB(
                  14,
                  10,
                  14,
                  provider.hasSelection ? 100 : 14,
                ),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: provider.allServices.length,
                  itemBuilder: (context, index) {
                    final service = provider.allServices[index];
                    return SalonServiceCard(
                      service: service,
                      onTap: () => _openDetails(context, service),
                    );
                  },
                ),
              ),

              // Slides in/out instead of an abrupt show/hide — matches the
              // "floating/sticky" requirement without feeling jarring.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: provider.hasSelection ? 0 : -140,
                child: SelectionSummaryBar(
                  serviceCount: provider.selectedCount,
                  totalDurationMinutes: provider.totalDurationMinutes,
                  totalPriceFormatted: SalonService.formatPeso(provider.totalPrice),
                  onContinue: () => _goToSchedule(context, provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}