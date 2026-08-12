import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

// =============================================================================
// HOW TO WIRE THIS UP (read this first)
// =============================================================================
//
// This version assumes ONE ServiceSelectionProvider is shared across your
// WHOLE booking flow — not created per category page. That's what makes
// "pick 1 Haircut + 1 Hair Color in the same booking" possible.
//
// In main.dart:
//   1. Build one combined catalog of ALL services (Haircut + Hair Treatment +
//      Hair Color), each with its correct `category` set.
//   2. Wrap MaterialApp with:
//        ChangeNotifierProvider(
//          create: (_) => ServiceSelectionProvider(allSalonServices),
//          child: MaterialApp(...),
//        )
//      so every pushed route (including modal sheets) can reach it.
//   3. HaircutServicesPage / HairServicesPage / HairColorPage just become:
//        ServiceSelectionPage(categoryTitle: 'Haircut', onContinue: ...)
//      — no more passing a `services` list per page; the page pulls its
//      own category's services out of the shared provider.
//

// =============================================================================
// THEME — change primaryMaroon once here to re-theme the whole screen.
// =============================================================================

// =============================================================================
// MODEL
// =============================================================================

/// Represents a single bookable salon service (e.g. "Wolf Cut", "Balayage").
///
/// Immutable — selection state changes go through [copyWith], so widgets
/// rebuild predictably when the provider updates the list.
///
/// IMPORTANT: [category] MUST be set correctly (e.g. 'Haircut', 'Hair
/// Treatment', 'Hair Color') — the provider uses it to enforce "one
/// service per category" and to filter which services show on each
/// category's grid.
class SalonService {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String imageUrl;
  final bool isSelected;
  final String category;

  const SalonService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isSelected = false,
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
// PROVIDER — single source of truth, shared across the ENTIRE booking flow.
// Enforces one selected service per category.
// =============================================================================

/// Holds the FULL service catalog (every category combined) plus the
/// current selection state for one booking session.
///
/// Create exactly ONE instance for the whole booking flow (wrap it around
/// MaterialApp in main.dart) — not one per category page. That's what lets
/// a person pick 1 Haircut + 1 Hair Color into the same appointment.
class ServiceSelectionProvider extends ChangeNotifier {
  ServiceSelectionProvider(List<SalonService> initialServices)
      : _allServices = List<SalonService>.from(initialServices);

  final List<SalonService> _allServices;

  /// id -> service, for the currently selected services (max one per category).
  final Map<String, SalonService> _selectedById = {};

  List<SalonService> get allServices => List.unmodifiable(_allServices);

  /// Services belonging to a single category — what a category page's
  /// grid should render.
  List<SalonService> servicesInCategory(String category) =>
      _allServices.where((s) => s.category == category).toList();

  List<SalonService> get selectedServices =>
      List.unmodifiable(_selectedById.values);

  int get selectedCount => _selectedById.length;

  bool get hasSelection => _selectedById.isNotEmpty;

  bool isSelected(String serviceId) => _selectedById.containsKey(serviceId);

  /// Is there already a selected service in this category?
  bool hasCategorySelection(String category) =>
      _selectedById.values.any((s) => s.category == category);

  /// The currently selected service in a category, if any.
  SalonService? getSelectedInCategory(String category) {
    for (final s in _selectedById.values) {
      if (s.category == category) return s;
    }
    return null;
  }

  int get totalDurationMinutes => _selectedById.values
      .fold(0, (sum, service) => sum + service.durationMinutes);

  double get totalPrice =>
      _selectedById.values.fold(0.0, (sum, service) => sum + service.price);

  /// Selects a service, REPLACING any existing selection in the same
  /// category (one service per category, max). The UI layer (see
  /// ServiceDetailsSheet) is responsible for confirming the replacement
  /// with the person first — this method just does it.
  void selectService(SalonService service) {
    _selectedById.removeWhere((_, s) => s.category == service.category);
    _selectedById[service.id] = service;
    _syncSelectionFlags();
    notifyListeners();
  }

  /// Deselects a single service by id.
  void deselectService(String serviceId) {
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
  /// SalonServiceCard can read isSelected directly instead of re-querying
  /// a map on every build.
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
/// bottom sheet — selection never happens directly on the grid.
class SalonServiceCard extends StatelessWidget {
  final SalonService service;
  final VoidCallback onTap;

  const SalonServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  bool get _isPopular => const {
        'haircut_layered_cut',
        'haircut_wolf_cut',
        'treat_keratin',
        'color_balayage',
      }.contains(service.id);

  @override
  Widget build(BuildContext context) {
    final isSelected = service.isSelected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isSelected ? 0.13 : 0.045),
                blurRadius: isSelected ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        service.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE8D5C4), Color(0xFFF8EFEA)],
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 36),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Wrap(
                          spacing: 6,
                          children: [
                            _ImageBadge(label: service.category, icon: Icons.sell_outlined),
                            if (_isPopular)
                              const _ImageBadge(label: 'Popular', icon: Icons.local_fire_department_outlined),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check_rounded : Icons.add_rounded,
                            color: isSelected ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  service.formattedDuration,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            service.formattedPrice,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                            size: 13,
                            color: isSelected ? AppColors.success : AppColors.primaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSelected ? 'Selected' : 'Tap to view & add',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? AppColors.success : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ImageBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
        ],
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
/// `provider` must be passed in and re-provided with `.value` inside —
/// showModalBottomSheet builds its content in the Navigator's Overlay,
/// which sits outside whatever subtree originally provided it, so ambient
/// lookup alone isn't reliable across all app setups.
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

  void _handlePrimaryAction(BuildContext context, ServiceSelectionProvider provider) {
    final isSelected = provider.isSelected(service.id);

    if (isSelected) {
      // Already selected -> button means "Remove Service".
      provider.deselectService(service.id);
      Navigator.pop(context);
      return;
    }

    // Not selected yet -> check if this category already has a pick.
    final conflicting = provider.getSelectedInCategory(service.category);
    if (conflicting != null && conflicting.id != service.id) {
      _confirmReplace(context, provider, conflicting);
    } else {
      provider.selectService(service);
      Navigator.pop(context);
    }
  }

  /// Matches the "Replace Service?" confirmation UX from the old
  /// CheckoutManager flow — one service per category, so picking a new
  /// one needs explicit confirmation before it swaps out the old pick.
  void _confirmReplace(
    BuildContext context,
    ServiceSelectionProvider provider,
    SalonService existing,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Replace Service?',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You already picked "${existing.name}" for ${existing.category}.\n\n'
          'Replace it with "${service.name}"?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              provider.selectService(service);
              Navigator.pop(dialogContext); // close confirm dialog
              Navigator.pop(context); // close details sheet
            },
            child: const Text('Replace', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceSelectionProvider>();
    final isSelected = provider.isSelected(service.id);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.access_time, label: service.formattedDuration),
              _InfoChip(icon: Icons.payments_outlined, label: service.formattedPrice),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _handlePrimaryAction(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.grey[200] : AppColors.primary,
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
        ),
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
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
/// selected ANYWHERE in the booking (any category). Purely
/// presentational — the parent screen passes in the already-computed
/// numbers from the shared provider.
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.fromLTRB(16, compact ? 14 : 18, 12, compact ? 14 : 18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: compact
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$serviceCount Service${serviceCount > 1 ? 's' : ''} • $_durationLabel',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalPriceFormatted,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(52, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, size: 20),
                      ),
                    ],
                  )
                : Row(
                    children: [
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
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                        icon: const Icon(Icons.calendar_month_rounded, size: 18),
                        label: const Text('Select Schedule'),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// PAGE — one category's grid screen
// =============================================================================

/// One category's grid screen (e.g. "Haircut"). Does NOT create its own
/// ServiceSelectionProvider — it reads the one shared provider from an
/// ancestor (wrap it around MaterialApp in main.dart) so selections from
/// other categories stay intact while browsing this one.
class ServiceSelectionPage extends StatelessWidget {
  final String categoryTitle;

  /// Called when the person taps "Select Schedule" with at least one
  /// service picked (from ANY category, not just this one). Receives all
  /// selected services plus their combined duration/price.
  final void Function(
    BuildContext context,
    List<SalonService> selectedServices,
    int totalDurationMinutes,
    double totalPrice,
  )? onContinue;

  const ServiceSelectionPage({
    super.key,
    required this.categoryTitle,
    this.onContinue,
  });

  void _openDetails(BuildContext context, SalonService service, ServiceSelectionProvider provider) {
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
      body: Consumer<ServiceSelectionProvider>(
        builder: (context, provider, _) {
          final categoryServices = provider.servicesInCategory(categoryTitle);

          return Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width < 420
                      ? 2
                      : width < 700
                          ? 2
                          : width < 1050
                              ? 3
                              : 4;
                  final gap = width < 600 ? 10.0 : 14.0;
                  final bottomPadding = provider.hasSelection ? 116.0 : 18.0;

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(14, 10, 14, bottomPadding),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                      childAspectRatio: width < 600 ? 0.78 : 0.86,
                    ),
                    itemCount: categoryServices.length,
                    itemBuilder: (context, index) {
                      final service = categoryServices[index];
                      return SalonServiceCard(
                        key: ValueKey(service.id),
                        service: service,
                        onTap: () => _openDetails(context, service, provider),
                      );
                    },
                  );
                },
              ),
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
