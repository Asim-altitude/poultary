
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class QuickAction {
  final String id;
  final String icon;
  final String label;
  final Color color;

  QuickAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });
}

class RecentActivityItem {
  final String id;
  final String icon;
  final String action;
  final String time;
  final Color color;
  final String batch;

  RecentActivityItem({
    required this.id,
    required this.icon,
    required this.action,
    required this.time,
    required this.color,
    required this.batch,
  });
}

class Feature {
  final String id;
  final String icon;
  final String label;
  final String? badge;
  final bool urgent;

  Feature({
    required this.id,
    required this.icon,
    required this.label,
    this.badge,
    this.urgent = false,
  });
}

class Section {
  final String id;
  final String icon;
  final String title;
  final Color color;
  final String tier;
  final String? badge;
  final bool urgent;
  final List<Feature> features;

  Section({
    required this.id,
    required this.icon,
    required this.title,
    required this.color,
    required this.tier,
    this.badge,
    this.urgent = false,
    required this.features,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════

final List<QuickAction> quickActions = [
  QuickAction(id: "qa1", icon: "🥚", label: "quick_action_collect_eggs".tr(), color: const Color(0xFFF59E0B)),
  QuickAction(id: "qa2", icon: "💵", label: "quick_action_sell_eggs".tr(), color: const Color(0xFF10B981)),
  QuickAction(id: "qa3", icon: "📥", label: "quick_action_add_income".tr(), color: const Color(0xFF3B82F6)),
  QuickAction(id: "qa4", icon: "📤", label: "quick_action_add_expense".tr(), color: const Color(0xFFEF4444)),
  QuickAction(id: "qa5", icon: "💀", label: "quick_action_mortality".tr(), color: const Color(0xFF6B7280)),
  QuickAction(id: "qa6", icon: "🔪", label: "quick_action_culling".tr(), color: const Color(0xFF9333EA)),
  QuickAction(id: "qa7", icon: "🍗", label: "quick_action_feed_usage".tr(), color: const Color(0xFF16A34A)),
  QuickAction(id: "qa8", icon: "📝", label: "quick_action_quick_note".tr(), color: const Color(0xFF0EA5E9)),
];

final List<RecentActivityItem> recentActivity = [
  RecentActivityItem(
    id: "r1",
    icon: "🥚",
    action: "recent_activity_collected_eggs".tr(),
    time: "recent_activity_time_10min".tr(),
    color: const Color(0xFFF59E0B),
    batch: "recent_activity_batch_a".tr(),
  ),
  RecentActivityItem(
    id: "r2",
    icon: "🍗",
    action: "recent_activity_feed_logged".tr(),
    time: "recent_activity_time_1hr".tr(),
    color: const Color(0xFF16A34A),
    batch: "recent_activity_flock_1".tr(),
  ),
  RecentActivityItem(
    id: "r3",
    icon: "💵",
    action: "recent_activity_sold_eggs".tr(),
    time: "recent_activity_time_2hrs".tr(),
    color: const Color(0xFF10B981),
    batch: "recent_activity_retail".tr(),
  ),
  RecentActivityItem(
    id: "r4",
    icon: "💀",
    action: "recent_activity_mortality".tr(),
    time: "recent_activity_time_yesterday".tr(),
    color: const Color(0xFF6B7280),
    batch: "recent_activity_flock_2".tr(),
  ),
  RecentActivityItem(
    id: "r5",
    icon: "📥",
    action: "recent_activity_income_added".tr(),
    time: "recent_activity_time_yesterday".tr(),
    color: const Color(0xFF3B82F6),
    batch: "recent_activity_sales".tr(),
  ),
];

final List<Section> sections = [
  // STOCKS
  Section(
    id: "feedstock",
    icon: "🍗",
    title: "section_feed_stock".tr(),
    color: const Color(0xFF16A34A),
    tier: "stock",
    badge: "section_feed_stock_badge".tr(),
    urgent: true,
    features: [
      Feature(id: "fs1", icon: "📊", label: "feature_current_stock_level".tr(), badge: "feature_current_stock_level_badge".tr(), urgent: true),
      Feature(id: "fs2", icon: "📈", label: "feature_usage_history".tr()),
      Feature(id: "fs3", icon: "🛒", label: "feature_reorder_purchase".tr(), badge: "feature_reorder_purchase_badge".tr(), urgent: true),
      Feature(id: "fs4", icon: "📦", label: "feature_supplier_records".tr()),
    ],
  ),
  Section(
    id: "medstock",
    icon: "💊",
    title: "section_medicine_stock".tr(),
    color: const Color(0xFFEF4444),
    tier: "stock",
    badge: "section_medicine_stock_badge".tr(),
    urgent: true,
    features: [
      Feature(id: "ms1", icon: "💊", label: "feature_current_medicines".tr(), badge: "feature_current_medicines_badge".tr(), urgent: true),
      Feature(id: "ms2", icon: "📋", label: "feature_usage_log".tr()),
      Feature(id: "ms3", icon: "🛒", label: "feature_reorder_purchase".tr()),
      Feature(id: "ms4", icon: "📅", label: "feature_expiry_tracker".tr(), badge: "feature_expiry_tracker_badge".tr(), urgent: true),
    ],
  ),
  Section(
    id: "vaccstock",
    icon: "💉",
    title: "section_vaccine_stock".tr(),
    color: const Color(0xFF8B5CF6),
    tier: "stock",
    badge: "section_vaccine_stock_badge".tr(),
    urgent: true,
    features: [
      Feature(id: "vs1", icon: "💉", label: "feature_available_vaccines".tr(), badge: "feature_available_vaccines_badge".tr()),
      Feature(id: "vs2", icon: "📅", label: "feature_upcoming_schedules".tr(), badge: "feature_upcoming_schedules_badge".tr(), urgent: true),
      Feature(id: "vs3", icon: "📊", label: "feature_vaccination_history".tr()),
      Feature(id: "vs4", icon: "🛒", label: "feature_reorder_purchase".tr()),
    ],
  ),
  Section(
    id: "eggstock",
    icon: "🥚",
    title: "section_egg_stock".tr(),
    color: const Color(0xFFF59E0B),
    tier: "stock",
    badge: "section_egg_stock_badge".tr(),
    features: [
      Feature(id: "es1", icon: "📦", label: "feature_current_egg_inventory".tr(), badge: "feature_current_egg_inventory_badge".tr()),
      Feature(id: "es2", icon: "📈", label: "feature_daily_collection_log".tr()),
      Feature(id: "es3", icon: "💵", label: "feature_sales_history".tr()),
      Feature(id: "es4", icon: "🏷️", label: "feature_grading_sorting".tr()),
    ],
  ),
  Section(
    id: "tools",
    icon: "🔧",
    title: "section_farm_tools_assets".tr(),
    color: const Color(0xFF78716C),
    tier: "stock",
    badge: "section_farm_tools_assets_badge".tr(),
    urgent: true,
    features: [
      Feature(id: "ft1", icon: "📋", label: "feature_asset_registry".tr(), badge: "feature_asset_registry_badge".tr()),
      Feature(id: "ft2", icon: "🔧", label: "feature_maintenance_tracker".tr(), badge: "feature_maintenance_tracker_badge".tr(), urgent: true),
      Feature(id: "ft3", icon: "📅", label: "feature_service_schedule".tr()),
      Feature(id: "ft4", icon: "📊", label: "feature_depreciation_log".tr()),
    ],
  ),
  Section(
    id: "genstock",
    icon: "📦",
    title: "section_general_stock".tr(),
    color: const Color(0xFF0EA5E9),
    tier: "stock",
    features: [
      Feature(id: "gs1", icon: "📦", label: "feature_all_supplies".tr(), badge: "feature_all_supplies_badge".tr()),
      Feature(id: "gs2", icon: "⚠️", label: "feature_low_stock_alerts".tr(), badge: "feature_low_stock_alerts_badge".tr(), urgent: true),
      Feature(id: "gs3", icon: "🛒", label: "feature_purchase_orders".tr()),
      Feature(id: "gs4", icon: "📊", label: "feature_usage_analytics".tr()),
    ],
  ),
  // CORE FEATURES
  Section(
    id: "flock",
    icon: "🐔",
    title: "section_flock_management".tr(),
    color: const Color(0xFFD97706),
    tier: "core",
    features: [
      Feature(id: "fl1", icon: "📊", label: "feature_flock_overview".tr(), badge: "feature_flock_overview_badge".tr()),
      Feature(id: "fl2", icon: "🏷️", label: "feature_batch_tracking".tr(), badge: "feature_batch_tracking_badge".tr()),
      Feature(id: "fl3", icon: "📈", label: "feature_growth_analytics".tr()),
      Feature(id: "fl4", icon: "👶", label: "feature_chick_management".tr(), badge: "feature_chick_management_badge".tr()),
    ],
  ),
  Section(
    id: "health",
    icon: "🏥",
    title: "section_health_care".tr(),
    color: const Color(0xFFEF4444),
    tier: "core",
    badge: "section_health_care_badge".tr(),
    urgent: true,
    features: [
      Feature(id: "hl1", icon: "🏥", label: "feature_health_records".tr(), badge: "feature_health_records_badge".tr(), urgent: true),
      Feature(id: "hl2", icon: "🔬", label: "feature_disease_monitor".tr()),
      Feature(id: "hl3", icon: "📑", label: "feature_vet_reports".tr()),
      Feature(id: "hl4", icon: "📊", label: "feature_mortality_analytics".tr()),
    ],
  ),
  Section(
    id: "finance",
    icon: "💰",
    title: "section_finance".tr(),
    color: const Color(0xFF10B981),
    tier: "core",
    features: [
      Feature(id: "fn1", icon: "📊", label: "feature_income_expenses".tr()),
      Feature(id: "fn2", icon: "💵", label: "feature_sales_records".tr()),
      Feature(id: "fn3", icon: "📈", label: "feature_profit_loss".tr()),
      Feature(id: "fn4", icon: "📆", label: "feature_monthly_summary".tr()),
    ],
  ),
  Section(
    id: "env",
    icon: "🏠",
    title: "section_environment".tr(),
    color: const Color(0xFF06B6D4),
    tier: "core",
    features: [
      Feature(id: "ev1", icon: "🌡️", label: "feature_temperature".tr()),
      Feature(id: "ev2", icon: "💨", label: "feature_ventilation".tr()),
      Feature(id: "ev3", icon: "💡", label: "feature_lighting_schedule".tr()),
      Feature(id: "ev4", icon: "🌧️", label: "feature_weather_alerts".tr()),
    ],
  ),
  Section(
    id: "feeding",
    icon: "🍗",
    title: "section_feeding_nutrition".tr(),
    color: const Color(0xFF16A34A),
    tier: "core",
    badge: "section_feeding_nutrition_badge".tr(),
    urgent: true,
    features: [
      Feature(id: "fd1", icon: "📅", label: "feature_feed_schedule".tr(), badge: "feature_feed_schedule_badge".tr(), urgent: true),
      Feature(id: "fd2", icon: "📊", label: "feature_nutrition_tracker".tr()),
      Feature(id: "fd3", icon: "💧", label: "feature_water_management".tr()),
      Feature(id: "fd4", icon: "📈", label: "feature_feed_cost_analysis".tr()),
    ],
  ),
  Section(
    id: "reports",
    icon: "📊",
    title: "section_reports_analytics".tr(),
    color: const Color(0xFF8B5CF6),
    tier: "core",
    features: [
      Feature(id: "rp1", icon: "📈", label: "feature_daily_summary".tr()),
      Feature(id: "rp2", icon: "📉", label: "feature_weekly_report".tr()),
      Feature(id: "rp3", icon: "📆", label: "feature_monthly_analytics".tr()),
      Feature(id: "rp4", icon: "📤", label: "feature_export_data".tr()),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class PoultryCommandCenter extends StatefulWidget {
  const PoultryCommandCenter({Key? key}) : super(key: key);

  @override
  State<PoultryCommandCenter> createState() => _PoultryCommandCenterState();
}

class _PoultryCommandCenterState extends State<PoultryCommandCenter> {
  int _selectedIndex = 0;
  bool _sheetOpen = false;
  Section? _expandedSection;
  String _searchQuery = "";
  final List<String> _pinnedIds = ["feedstock", "medstock", "vaccstock"];
  String? _toastMessage;

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _togglePin(String id) {
    setState(() {
      if (_pinnedIds.contains(id)) {
        _pinnedIds.remove(id);
      } else {
        _pinnedIds.insert(0, id);
      }
    });
  }

  List<Map<String, dynamic>> _getSearchResults() {
    if (_searchQuery.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    for (var section in sections) {
      for (var feature in section.features) {
        if (feature.label.toLowerCase().contains(_searchQuery.toLowerCase())) {
          results.add({'section': section, 'feature': feature});
        }
      }
    }
    return results;
  }

  List<Section> _getSortedSections() {
    final pinned = sections.where((s) => _pinnedIds.contains(s.id)).toList();
    final unpinned = sections.where((s) => !_pinnedIds.contains(s.id)).toList();
    final stockUnpinned = unpinned.where((s) => s.tier == "stock").toList();
    final coreUnpinned = unpinned.where((s) => s.tier == "core").toList();
    return [...pinned, ...stockUnpinned, ...coreUnpinned];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Stack(
        children: [
          // Dashboard Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 26, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                 Text(
                  "label_good_morning".tr(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                 Text(
                  "label_farm_dashboard".tr(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats
                Row(
                  children: [
                    _buildStatCard("🥚", "148", "label_eggs_today".tr()),
                    const SizedBox(width: 9),
                    _buildStatCard("🐔", "820", "label_flock_size".tr()),
                    const SizedBox(width: 9),
                    _buildStatCard("⚠️", "4", "label_alerts".tr()),
                  ],
                ),
                const SizedBox(height: 16),

                // CTA Card
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text("⚡", style: TextStyle(fontSize: 23)),
                        ),
                      ),
                      const SizedBox(width: 13),
                       Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "label_command_center".tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "label_command_center_subtitle".tr(),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Sheet Overlay
          if (_sheetOpen)
            GestureDetector(
              onTap: () => setState(() {
                _sheetOpen = false;
                _expandedSection = null;
                _searchQuery = "";
              }),
              child: Container(
                color: const Color(0x61000000),
              ),
            ),

          // Bottom Sheet
          AnimatedPositioned(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOut,
            bottom: 0,
            left: 0,
            right: 0,
            height: _sheetOpen ? MediaQuery.of(context).size.height * 0.82 : 0,
            child: _buildBottomSheet(),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),

          // Toast
          if (_toastMessage != null)
            Positioned(
              bottom: 94,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _toastMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEF2F7), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECF0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 14,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem("🏠", "nav_home".tr(), 0),
              _buildNavItem("📊", "nav_reports".tr(), 1),
              const SizedBox(width: 56), // Space for center button
              _buildNavItem("🔔", "nav_alerts".tr(), 3),
              _buildNavItem("👤", "nav_profile".tr(), 4),
            ],
          ),
          Positioned(
            top: -22,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: GestureDetector(
              onTap: () => setState(() => _sheetOpen = !_sheetOpen),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.42),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text("⚡", style: TextStyle(fontSize: 23)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Opacity(
        opacity: isSelected ? 1.0 : 0.38,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 9),
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 40,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 9),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _expandedSection?.title ?? "label_command_center".tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _expandedSection != null
                          ? "${_expandedSection!.features.length} features"
                          : "label_log_track_manage".tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _sheetOpen = false;
                    _expandedSection = null;
                    _searchQuery = "";
                  }),
                  child: Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "✕",
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _expandedSection != null
                ? _buildExpandedView()
                : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final searchResults = _getSearchResults();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          _buildSearchBar(),
          const SizedBox(height: 10),

          if (_searchQuery.isNotEmpty)
            _buildSearchResults(searchResults)
          else ...[
            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFEEF2F7)),
            ),
            const SizedBox(height: 12),

            // Recent Activity
            _buildRecentActivity(),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFEEF2F7)),
            ),
            const SizedBox(height: 4),

            // Sections
            _buildSections(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? const Color(0xFF16A34A)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Row(
          children: [
            const Opacity(
              opacity: 0.4,
              child: Text("🔍", style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration:  InputDecoration(
                  hintText: "search_placeholder".tr(),
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _searchQuery = ""),
                child: const Opacity(
                  opacity: 0.35,
                  child: Text("✕", style: TextStyle(fontSize: 14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            "label_quick_actions".tr(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          // First row (4 actions)
          Row(
            children: quickActions.sublist(0, 4).map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildQuickActionButton(action),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Second row (4 actions)
          Row(
            children: quickActions.sublist(4, 8).map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildQuickActionButton(action),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(QuickAction action) {
    return GestureDetector(
      onTap: () => _showToast("toast_action_opened".tr(args: [action.label])),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8ECF0), width: 1.5),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.16),
                border: Border.all(color: action.color.withOpacity(0.28), width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(action.icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            "label_recent_activity".tr(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          ...recentActivity.map((item) => _buildRecentActivityItem(item)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem(RecentActivityItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        borderRadius: BorderRadius.circular(11),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.14),
              border: Border.all(color: item.color.withOpacity(0.22), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.action,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  "${item.batch} · ${item.time}",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showToast("toast_repeating".tr(args: [item.action.split('—')[0].trim()])),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text("↻", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSections() {
    final sortedSections = _getSortedSections();
    final pinned = sortedSections.where((s) => _pinnedIds.contains(s.id)).toList();
    final stockUnpinned = sortedSections
        .where((s) => !_pinnedIds.contains(s.id) && s.tier == "stock")
        .toList();
    final coreUnpinned = sortedSections
        .where((s) => !_pinnedIds.contains(s.id) && s.tier == "core")
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pinned.isNotEmpty) ...[
          _buildTierLabel("label_pinned".tr(), pinned.length),
          ...pinned.map((s) => _buildSectionCard(s)),
        ],
        if (stockUnpinned.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildTierLabel("label_stocks".tr(), stockUnpinned.length),
          ...stockUnpinned.map((s) => _buildSectionCard(s)),
        ],
        if (coreUnpinned.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildTierLabel("label_features".tr(), coreUnpinned.length),
          ...coreUnpinned.map((s) => _buildSectionCard(s)),
        ],
      ],
    );
  }

  Widget _buildTierLabel(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
          Text(
            "$count sections",
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Section section) {
    final isPinned = _pinnedIds.contains(section.id);
    return GestureDetector(
      onTap: () => setState(() => _expandedSection = section),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isPinned
                ? section.color.withOpacity(0.3)
                : const Color(0xFFE8ECF0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: section.color.withOpacity(0.14),
                border: Border.all(color: section.color.withOpacity(0.28), width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(section.icon, style: const TextStyle(fontSize: 19)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (isPinned) ...[
                        const SizedBox(width: 5),
                        const Text("📌", style: TextStyle(fontSize: 9)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    "${section.features.length} features",
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            if (section.badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: section.urgent
                      ? const Color(0xFFFEF2F2)
                      : section.color.withOpacity(0.14),
                  border: Border.all(
                    color: section.urgent
                        ? const Color(0xFFFECACA)
                        : section.color.withOpacity(0.22),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  section.badge!,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: section.urgent ? const Color(0xFFDC2626) : section.color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            GestureDetector(
              onTap: () => _togglePin(section.id),
              child: Opacity(
                opacity: isPinned ? 0.85 : 0.2,
                child: const Text("📌", style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return  Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Text("🔍", style: TextStyle(fontSize: 36)),
              SizedBox(height: 10),
              Text(
                "search_no_results".tr(),
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "search_results_count".tr(args: [results.length.toString()]) + (results.length != 1 ? "S" : ""),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...results.map((r) => _buildSearchResultItem(r)),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    final section = result['section'] as Section;
    final feature = result['feature'] as Feature;

    return GestureDetector(
      onTap: () => setState(() {
        _expandedSection = section;
        _searchQuery = "";
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEF2F7), width: 1.5),
          borderRadius: BorderRadius.circular(11),
        ),
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: section.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(feature.icon, style: const TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "label_in".tr() + " ${section.title}",
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            if (feature.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: feature.urgent
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  feature.badge!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: feature.urgent
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF3B82F6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    final section = _expandedSection!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => setState(() => _expandedSection = null),
            child:  Row(
              children: [
                Text("←", style: TextStyle(fontSize: 14)),
                SizedBox(width: 5),
                Text(
                  "label_back".tr(),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Section header
          Container(
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.06),
              border: Border.all(color: section.color.withOpacity(0.18), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: section.color.withOpacity(0.18),
                    border: Border.all(color: section.color.withOpacity(0.35), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(section.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (section.badge != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: section.urgent
                                ? const Color(0xFFFEF2F2)
                                : section.color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            section.badge!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: section.urgent
                                  ? const Color(0xFFDC2626)
                                  : section.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Features
          ...section.features.asMap().entries.map((entry) {
            final i = entry.key;
            final feature = entry.value;
            return AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 220 + (i * 60)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: feature.urgent
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFEEF2F7),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: section.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(feature.icon, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (feature.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: feature.urgent
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          feature.badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: feature.urgent
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
