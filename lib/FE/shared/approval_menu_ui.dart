import 'package:flutter/material.dart';
import 'package:v2rp3/utils/hex_color.dart';

class ApprovalMenuTheme {
  static final Color primary = HexColor('#F4A62A');
  static final Color primaryDark = HexColor('#D4891A');
  static const Color background = Color(0xFFF5F5F7);
}

class ApprovalMenuItemData {
  final String title;
  final String imageAsset;
  final int count;
  final VoidCallback onTap;

  const ApprovalMenuItemData({
    required this.title,
    required this.imageAsset,
    required this.count,
    required this.onTap,
  });
}

class ApprovalMenuSectionData {
  final String title;
  final IconData icon;
  final List<ApprovalMenuItemData> items;

  const ApprovalMenuSectionData({
    required this.title,
    required this.icon,
    required this.items,
  });

  int get totalPending =>
      items.fold(0, (sum, item) => sum + (item.count > 0 ? item.count : 0));
}

class ApprovalMenuFilter {
  final String id;
  final String label;
  final IconData icon;
  final int badgeCount;

  const ApprovalMenuFilter({
    required this.id,
    required this.label,
    required this.icon,
    this.badgeCount = 0,
  });
}

class ApprovalMenuFilterBar extends StatelessWidget {
  final List<ApprovalMenuFilter> filters;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const ApprovalMenuFilterBar({
    super.key,
    required this.filters,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < filters.length; i++) ...[
              _CategoryChip(
                filter: filters[i],
                selected: selectedId == filters[i].id,
                onTap: () => onSelected(filters[i].id),
              ),
              if (i < filters.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ApprovalMenuFilter filter;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = filter.badgeCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withOpacity(0.45),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filter.icon,
                size: 17,
                color: selected
                    ? ApprovalMenuTheme.primaryDark
                    : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                filter.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? ApprovalMenuTheme.primaryDark
                      : Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? Colors.red : Colors.red.shade700,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white70,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filter.badgeCount > 99 ? '99+' : '${filter.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ApprovalMenuSummaryCard extends StatelessWidget {
  final int totalPending;
  final int sectionCount;

  const ApprovalMenuSummaryCard({
    super.key,
    required this.totalPending,
    required this.sectionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ApprovalMenuTheme.primary,
            ApprovalMenuTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ApprovalMenuTheme.primary.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending Approvals',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalPending documents',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$sectionCount categories',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalMenuSectionCard extends StatelessWidget {
  final ApprovalMenuSectionData section;

  const ApprovalMenuSectionCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ApprovalMenuTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(section.icon,
                      size: 20, color: ApprovalMenuTheme.primaryDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                if (section.totalPending > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      '${section.totalPending}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const columns = 3;
                const spacing = 8.0;
                final tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final item in section.items)
                      SizedBox(
                        width: tileWidth,
                        child: ApprovalMenuTile(
                          title: item.title,
                          imageAsset: item.imageAsset,
                          count: item.count,
                          onTap: item.onTap,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalMenuShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const ApprovalMenuShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.baseColor = const Color(0xFFE8E8ED),
    this.highlightColor = const Color(0xFFF8F8FA),
  });

  @override
  State<ApprovalMenuShimmerBox> createState() => _ApprovalMenuShimmerBoxState();
}

class _ApprovalMenuShimmerBoxState extends State<ApprovalMenuShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(-0.5 + 2 * _controller.value, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ApprovalMenuSummarySkeleton extends StatelessWidget {
  const ApprovalMenuSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          ApprovalMenuShimmerBox(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.circular(12),
            baseColor: Colors.white.withOpacity(0.22),
            highlightColor: Colors.white.withOpacity(0.38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApprovalMenuShimmerBox(
                  width: 120,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                  baseColor: Colors.white.withOpacity(0.22),
                  highlightColor: Colors.white.withOpacity(0.38),
                ),
                const SizedBox(height: 8),
                ApprovalMenuShimmerBox(
                  width: 160,
                  height: 20,
                  borderRadius: BorderRadius.circular(6),
                  baseColor: Colors.white.withOpacity(0.28),
                  highlightColor: Colors.white.withOpacity(0.45),
                ),
              ],
            ),
          ),
          ApprovalMenuShimmerBox(
            width: 72,
            height: 26,
            borderRadius: BorderRadius.circular(20),
            baseColor: Colors.white.withOpacity(0.22),
            highlightColor: Colors.white.withOpacity(0.38),
          ),
        ],
      ),
    );
  }
}

class ApprovalMenuSectionSkeleton extends StatelessWidget {
  final int tileCount;

  const ApprovalMenuSectionSkeleton({
    super.key,
    this.tileCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                ApprovalMenuShimmerBox(
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ApprovalMenuShimmerBox(
                    height: 16,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                ApprovalMenuShimmerBox(
                  width: 28,
                  height: 22,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const columns = 3;
                const spacing = 8.0;
                final tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final rows = (tileCount / columns).ceil();
                return Column(
                  children: [
                    for (var row = 0; row < rows; row++)
                      Padding(
                        padding: EdgeInsets.only(top: row == 0 ? 0 : spacing),
                        child: Row(
                          children: [
                            for (var col = 0; col < columns; col++)
                              if (row * columns + col < tileCount) ...[
                                if (col > 0) SizedBox(width: spacing),
                                SizedBox(
                                  width: tileWidth,
                                  child: _TileSkeleton(),
                                ),
                              ],
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      decoration: BoxDecoration(
        color: ApprovalMenuTheme.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ApprovalMenuShimmerBox(
            width: 52,
            height: 52,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(height: 8),
          ApprovalMenuShimmerBox(
            height: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          ApprovalMenuShimmerBox(
            width: 48,
            height: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class ApprovalMenuLoadingSkeleton extends StatelessWidget {
  const ApprovalMenuLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        ApprovalMenuSectionSkeleton(tileCount: 4),
        ApprovalMenuSectionSkeleton(tileCount: 6),
        ApprovalMenuSectionSkeleton(tileCount: 6),
        Padding(
          padding: EdgeInsets.only(top: 4, bottom: 8),
          child: Center(
            child: _LoadingStatusChip(),
          ),
        ),
      ],
    );
  }
}

class _LoadingStatusChip extends StatelessWidget {
  const _LoadingStatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ApprovalMenuTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Memuat data approval...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalMenuTile extends StatelessWidget {
  final String title;
  final String imageAsset;
  final int count;
  final VoidCallback onTap;

  const ApprovalMenuTile({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ApprovalMenuTheme.background,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
