import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_state.dart';
import '../models/case_record.dart';
import 'tracker_theme.dart';

class TrackerApp extends StatelessWidget {
  const TrackerApp({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immigro',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTrackerTheme(Brightness.light),
      darkTheme: buildTrackerTheme(Brightness.dark),
      home: TrackerHomePage(
        currentThemeMode: themeMode,
        onThemeModeChanged: onThemeModeChanged,
      ),
    );
  }
}

class TrackerHomePage extends StatefulWidget {
  const TrackerHomePage({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<TrackerHomePage> createState() => _TrackerHomePageState();
}

class _TrackerHomePageState extends State<TrackerHomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<FFAppState>(
      builder: (context, appState, _) {
        if (!appState.trackerInitialized) {
          return const _LoadingScaffold();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1080;
            final page = _pageForIndex(
              context: context,
              appState: appState,
              isWide: isWide,
            );

            return Scaffold(
              appBar: _buildAppBar(context, appState),
              body: isWide
                  ? Row(
                      children: [
                        _PremiumNavigationRail(
                          selectedIndex: _tabIndex,
                          onSelected: (index) =>
                              setState(() => _tabIndex = index),
                        ),
                        VerticalDivider(
                          width: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: .5),
                        ),
                        Expanded(child: page),
                        if (_tabIndex == 0)
                          SizedBox(
                            width: constraints.maxWidth >= 1320 ? 480 : 420,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border(
                                  left: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: .5),
                                  ),
                                ),
                              ),
                              child:
                                  _CaseDetailPanel(item: appState.selectedCase),
                            ),
                          ),
                      ],
                    )
                  : page,
              bottomNavigationBar: isWide
                  ? null
                  : NavigationBar(
                      selectedIndex: _tabIndex,
                      onDestinationSelected: (index) =>
                          setState(() => _tabIndex = index),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: 'Cases',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.timeline_outlined),
                          selectedIcon: Icon(Icons.timeline),
                          label: 'Activity',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.checklist_outlined),
                          selectedIcon: Icon(Icons.checklist),
                          label: 'Tasks',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: 'Settings',
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _pageForIndex({
    required BuildContext context,
    required FFAppState appState,
    required bool isWide,
  }) {
    switch (_tabIndex) {
      case 1:
        return const _TimelineView();
      case 2:
        return const _TasksView();
      case 3:
        return _SettingsView(
          currentThemeMode: widget.currentThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        );
      case 0:
      default:
        return _DashboardView(
          isWide: isWide,
          onOpenCase: (item) {
            appState.selectCase(item.id);
            if (!isWide) {
              _showCaseDetails(context, item);
            }
          },
        );
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, FFAppState appState) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: 64,
      titleSpacing: compact ? 12 : 20,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: .22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Immigro',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!compact)
                  Text(
                    'Private USCIS case command center',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh all cases',
          onPressed: appState.cases.isEmpty ? null : () => _refreshAll(context),
          icon: const Icon(Icons.sync),
        ),
        Padding(
          padding: EdgeInsets.only(right: compact ? 8 : 20),
          child: compact
              ? IconButton.filled(
                  tooltip: 'Add case',
                  onPressed: () => _showAddCaseDialog(context),
                  icon: const Icon(Icons.add),
                )
              : FilledButton.icon(
                  onPressed: () => _showAddCaseDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add case'),
                ),
        ),
      ],
    );
  }

  Future<void> _refreshAll(BuildContext context) async {
    final appState = context.read<FFAppState>();
    await appState.refreshAll();
    if (!context.mounted) {
      return;
    }
    final message = appState.lastError ?? 'Refresh complete.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading saved cases',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 180,
              child: LinearProgressIndicator(minHeight: 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumNavigationRail extends StatelessWidget {
  const _PremiumNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      minWidth: 96,
      groupAlignment: -0.86,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Cases'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.timeline_outlined),
          selectedIcon: Icon(Icons.timeline),
          label: Text('Activity'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: Text('Tasks'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.isWide,
    required this.onOpenCase,
  });

  final bool isWide;
  final ValueChanged<ImmigrationCase> onOpenCase;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding:
              EdgeInsets.fromLTRB(isWide ? 28 : 20, 22, isWide ? 28 : 20, 0),
          sliver: SliverToBoxAdapter(
            child: _BriefingPanel(appState: appState),
          ),
        ),
        SliverPadding(
          padding:
              EdgeInsets.fromLTRB(isWide ? 28 : 20, 16, isWide ? 28 : 20, 0),
          sliver: SliverToBoxAdapter(
            child: _MetricGrid(appState: appState),
          ),
        ),
        if (appState.lastError != null)
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(isWide ? 28 : 20, 16, isWide ? 28 : 20, 0),
            sliver: SliverToBoxAdapter(
              child: _InlineBanner(
                icon: Icons.error_outline,
                title: 'Refresh needs attention',
                message: appState.lastError!,
                actionLabel: 'Open USCIS.gov',
                onAction: appState.selectedCase == null
                    ? null
                    : () =>
                        _openOfficialStatus(context, appState.selectedCase!),
              ),
            ),
          ),
        SliverPadding(
          padding:
              EdgeInsets.fromLTRB(isWide ? 28 : 20, 16, isWide ? 28 : 20, 0),
          sliver: SliverToBoxAdapter(
            child: _CaseToolbar(appState: appState),
          ),
        ),
        if (appState.visibleCases.isEmpty)
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(isWide ? 28 : 20, 18, isWide ? 28 : 20, 32),
            sliver: SliverToBoxAdapter(
              child: _EmptyCases(appState: appState),
            ),
          )
        else
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(isWide ? 28 : 20, 16, isWide ? 28 : 20, 32),
            sliver: SliverList.separated(
              itemCount: appState.visibleCases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = appState.visibleCases[index];
                return _CaseCard(
                  item: item,
                  selected: item.id == appState.selectedCase?.id,
                  onTap: () => onOpenCase(item),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BriefingPanel extends StatelessWidget {
  const _BriefingPanel({required this.appState});

  final FFAppState appState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextCase = appState.cases
        .where((item) => !item.isClosed)
        .sorted((a, b) => b.daysOpen.compareTo(a.daysOpen))
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TrustBadge(
                icon: Icons.verified_user_outlined,
                label: 'USCIS.gov is official',
                color: colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                nextCase == null
                    ? 'Your case command center is ready'
                    : '${nextCase.displayName} has been open ${nextCase.daysOpen} days',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                nextCase?.nextStep.isNotEmpty == true
                    ? nextCase!.nextStep
                    : 'Track locally. Verify important updates on USCIS.gov.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          colorScheme.onPrimaryContainer.withValues(alpha: .82),
                      height: 1.35,
                    ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _showAddCaseDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add case'),
              ),
              if (nextCase != null)
                OutlinedButton.icon(
                  onPressed: () => _openOfficialStatus(context, nextCase),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open USCIS.gov'),
                ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 24),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.appState});

  final FFAppState appState;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        icon: Icons.folder_open_outlined,
        label: 'Active cases',
        value: appState.activeCaseCount.toString(),
        color: Theme.of(context).colorScheme.primary,
      ),
      const _MetricData(
        icon: Icons.task_alt,
        label: 'Closed',
        value: '',
        color: trackerSuccess,
      ).copyWith(value: appState.closedCaseCount.toString()),
      const _MetricData(
        icon: Icons.notifications_active_outlined,
        label: '30-day changes',
        value: '',
        color: trackerEvidence,
      ).copyWith(value: appState.changedThisMonth.toString()),
      const _MetricData(
        icon: Icons.checklist_outlined,
        label: 'Tasks done',
        value: '',
        color: trackerWarning,
      ).copyWith(value: '${(appState.checklistProgress * 100).round()}%'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((item) =>
                  SizedBox(width: width, child: _MetricCard(data: item)))
              .toList(),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _MetricData copyWith({String? value}) {
    return _MetricData(
      icon: icon,
      label: label,
      value: value ?? this.value,
      color: color,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    data.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseToolbar extends StatelessWidget {
  const _CaseToolbar({required this.appState});

  final FFAppState appState;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final search = TextField(
          onChanged: appState.setSearchQuery,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search cases, forms, receipts',
          ),
        );
        final sort = DropdownButtonFormField<CaseSortMode>(
          initialValue: appState.sortMode,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.sort),
            labelText: 'Sort',
          ),
          items: CaseSortMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              appState.setSortMode(value);
            }
          },
        );
        final badges = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TrustBadge(
              icon: Icons.lock_outline,
              label: compact ? 'Saved locally' : 'Saved on this device',
              color: trackerPrimary,
            ),
            _TrustBadge(
              icon: Icons.public,
              label:
                  compact ? 'Verify on USCIS.gov' : 'Manual USCIS verification',
              color: trackerWarning,
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              search,
              const SizedBox(height: 10),
              sort,
              const SizedBox(height: 10),
              badges,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: search),
            const SizedBox(width: 12),
            SizedBox(width: 240, child: sort),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: badges),
          ],
        );
      },
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCases extends StatelessWidget {
  const _EmptyCases({required this.appState});

  final FFAppState appState;

  @override
  Widget build(BuildContext context) {
    final isSearchEmpty =
        appState.cases.isNotEmpty && appState.visibleCases.isEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isSearchEmpty
                    ? Icons.search_off
                    : Icons.folder_special_outlined,
                color: colorScheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSearchEmpty ? 'No matching cases' : 'No cases yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                isSearchEmpty
                    ? 'Try another receipt, form, status, or applicant name.'
                    : 'Start with a receipt like IOE1234567890. Keep your local record organized and verify official updates on USCIS.gov.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (!isSearchEmpty)
                  FilledButton.icon(
                    onPressed: () => _showAddCaseDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add first case'),
                  ),
                OutlinedButton.icon(
                  onPressed: appState.addDemoCase,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Load demo case'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ImmigrationCase item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    final stageColor = stageColorOf(context, item.stage);
    final isRefreshing = appState.isRefreshing(item.id);
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: stageColor.withValues(alpha: .14),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? stageColor
                : colorScheme.outline.withValues(alpha: .7),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 8 : 5,
                  color: stageColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StageBadge(stage: item.stage),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.formType} • ${item.shortReceipt}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.statusTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (item.nextStep.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.nextStep,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: .72),
                                ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _StageTracker(stage: item.stage, compact: true),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(
                              icon: Icons.calendar_today_outlined,
                              label: 'Filed ${item.filedDateLabel}',
                            ),
                            _InfoPill(
                              icon: Icons.timer_outlined,
                              label: '${item.daysOpen} days open',
                            ),
                            _InfoPill(
                              icon: Icons.source_outlined,
                              label: 'Source ${item.statusSource}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Last checked: ${item.lastCheckedLabel}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: isRefreshing
                                  ? null
                                  : () => _refreshCase(context, item),
                              icon: isRefreshing
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                              label: const Text('Check'),
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
      ),
    );
  }
}

class _CaseDetailPanel extends StatefulWidget {
  const _CaseDetailPanel({required this.item});

  final ImmigrationCase? item;

  @override
  State<_CaseDetailPanel> createState() => _CaseDetailPanelState();
}

class _CaseDetailPanelState extends State<_CaseDetailPanel> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item == null) {
      return const _SelectCaseEmptyState();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: ListView(
        key: ValueKey(item.id),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _DetailHeader(item: item),
          const SizedBox(height: 12),
          _StatusSection(item: item),
          const SizedBox(height: 12),
          _Section(
            title: 'Tracking stage',
            icon: Icons.route_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StageTracker(stage: item.stage),
                const SizedBox(height: 10),
                Text(
                  'Stages are labels for organization, not a USCIS time estimate.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Timeline',
            icon: Icons.timeline,
            child: _TimelineList(events: item.history),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Checklist',
            icon: Icons.checklist,
            trailing: Text('${item.completedTasks}/${item.checklist.length}'),
            child: Column(
              children: item.checklist
                  .map(
                    (task) => CheckboxListTile(
                      value: task.isDone,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(task.title),
                      subtitle: task.description.isEmpty
                          ? null
                          : Text(
                              task.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                      onChanged: (value) =>
                          context.read<FFAppState>().toggleTask(
                                item.id,
                                task.id,
                                isDone: value ?? false,
                              ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Notes',
            icon: Icons.notes_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.notes.trim().isNotEmpty)
                  Text(item.notes)
                else
                  Text('No notes saved.',
                      style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(hintText: 'Add a private note'),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await context
                          .read<FFAppState>()
                          .appendNote(item.id, _noteController.text);
                      _noteController.clear();
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save note'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FactsSection(item: item),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, item),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete case'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectCaseEmptyState extends StatelessWidget {
  const _SelectCaseEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'Select a case',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Open a case to see status, timeline, tasks, and notes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.item});

  final ImmigrationCase item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
              _StageBadge(stage: item.stage),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${item.formType} • ${item.shortReceipt}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: .75),
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(icon: Icons.person_outline, label: item.applicantName),
              _InfoPill(
                  icon: Icons.event_outlined,
                  label: 'Filed ${item.filedDateLabel}'),
              _InfoPill(
                  icon: Icons.flag_outlined,
                  label: 'Priority ${item.priorityDateLabel}'),
              if (item.serviceCenter.isNotEmpty)
                _InfoPill(
                    icon: Icons.business_outlined, label: item.serviceCenter),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.item});

  final ImmigrationCase item;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    final refreshing = appState.isRefreshing(item.id);

    return _Section(
      title: 'Current status',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.statusTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (item.statusDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.statusDescription,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.source_outlined,
                label: 'Source ${item.statusSource}',
              ),
              _InfoPill(
                icon: Icons.sync,
                label: item.lastCheckedLabel,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;
              final actions = [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        refreshing ? null : () => _refreshCase(context, item),
                    icon: refreshing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openOfficialStatus(context, item),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('USCIS.gov'),
                  ),
                ),
              ];
              if (narrow) {
                return Column(
                  children: [
                    actions[0],
                    const SizedBox(height: 10),
                    actions[2],
                  ],
                );
              }
              return Row(children: actions);
            },
          ),
        ],
      ),
    );
  }
}

class _FactsSection extends StatelessWidget {
  const _FactsSection({required this.item});

  final ImmigrationCase item;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Case facts',
      icon: Icons.dataset_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _InfoPill(
              icon: Icons.calendar_today_outlined, label: item.filedDateLabel),
          _InfoPill(icon: Icons.flag_outlined, label: item.priorityDateLabel),
          _InfoPill(
              icon: Icons.notifications_none,
              label: item.notifyOnStatusChange ? 'Alerts on' : 'Alerts off'),
          _InfoPill(icon: Icons.storage_outlined, label: 'Stored locally'),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});

  final CaseStage stage;

  @override
  Widget build(BuildContext context) {
    final color = stageColorOf(context, stage);
    return Semantics(
      label: 'Stage: ${stage.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stageIcon(stage), size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              stage.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.trim().isEmpty ? 'Not set' : label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageTracker extends StatelessWidget {
  const _StageTracker({required this.stage, this.compact = false});

  final CaseStage stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stages = CaseStage.values;
    final visibleStages = compact
        ? stages
            .where((item) =>
                item == stage ||
                item.index == stage.index - 1 ||
                item.index == stage.index + 1)
            .toList()
        : stages;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visibleStages.map((item) {
        final active = item == stage;
        final color = stageColorOf(context, item);
        return Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: .13) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: .45)
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: .55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(stageIcon(item), size: 14, color: active ? color : null),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: active ? color : null,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    final events = appState.cases
        .expand((item) => item.history.map((event) => MapEntry(item, event)))
        .sorted((a, b) => b.value.date.compareTo(a.value.date));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PageTitle(
          icon: Icons.timeline,
          title: 'Activity',
          subtitle: 'Every saved case update in one clean timeline.',
        ),
        const SizedBox(height: 14),
        if (events.isEmpty)
          const _EmptySimpleCard(
            icon: Icons.timeline,
            title: 'No activity yet',
            message: 'Add a case or refresh a case to start building history.',
          )
        else
          ...events.map(
            (entry) => Card(
              child: ListTile(
                minLeadingWidth: 44,
                leading: CircleAvatar(
                  backgroundColor: stageColorOf(context, entry.key.stage)
                      .withValues(alpha: .12),
                  child: Icon(
                    Icons.history,
                    color: stageColorOf(context, entry.key.stage),
                  ),
                ),
                title: Text(entry.value.title),
                subtitle:
                    Text('${entry.key.displayName} • ${entry.value.dateLabel}'),
                trailing: _SourceChip(label: entry.value.source),
              ),
            ),
          ),
      ],
    );
  }
}

class _TasksView extends StatelessWidget {
  const _TasksView();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    final cases = appState.visibleCases;
    final openTasks = cases
        .expand((item) => item.checklist
            .where((task) => !task.isDone)
            .map((task) => MapEntry(item, task)))
        .toList();
    final doneTasks = cases
        .expand((item) => item.checklist
            .where((task) => task.isDone)
            .map((task) => MapEntry(item, task)))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PageTitle(
          icon: Icons.checklist,
          title: 'Tasks',
          subtitle: 'Prep, notices, address hygiene, and evidence reminders.',
        ),
        const SizedBox(height: 14),
        if (cases.isEmpty)
          const _EmptySimpleCard(
            icon: Icons.checklist,
            title: 'No tasks yet',
            message: 'Add a case to create a practical checklist.',
          )
        else ...[
          _TaskGroup(title: 'Open tasks', entries: openTasks),
          const SizedBox(height: 12),
          _TaskGroup(title: 'Completed', entries: doneTasks),
        ],
      ],
    );
  }
}

class _TaskGroup extends StatelessWidget {
  const _TaskGroup({required this.title, required this.entries});

  final String title;
  final List<MapEntry<ImmigrationCase, CaseTask>> entries;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      icon:
          title == 'Completed' ? Icons.done_all : Icons.radio_button_unchecked,
      trailing: Text(entries.length.toString()),
      child: entries.isEmpty
          ? Text('Nothing here.', style: Theme.of(context).textTheme.bodySmall)
          : Column(
              children: entries
                  .map(
                    (entry) => CheckboxListTile(
                      value: entry.value.isDone,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(entry.value.title),
                      subtitle: Text(
                        entry.key.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onChanged: (value) =>
                          context.read<FFAppState>().toggleTask(
                                entry.key.id,
                                entry.value.id,
                                isDone: value ?? false,
                              ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    const proxyConfigured = bool.hasEnvironment('CASE_STATUS_API_BASE_URL') &&
        String.fromEnvironment('CASE_STATUS_API_BASE_URL') != '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PageTitle(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle:
              'Trust, privacy, refresh behavior, and local data controls.',
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Status refresh',
          icon: Icons.cloud_sync_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusRow(
                label: 'Private status proxy',
                value: proxyConfigured ? 'Configured' : 'Manual only',
                icon: proxyConfigured ? Icons.check_circle : Icons.info_outline,
                color: proxyConfigured ? trackerSuccess : trackerWarning,
              ),
              const SizedBox(height: 12),
              Text(
                proxyConfigured
                    ? 'Background refresh goes through your private proxy.'
                    : 'No live proxy is configured. Use Refresh for local checks and open USCIS.gov for official status.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              const _InlineBanner(
                icon: Icons.gavel_outlined,
                title: 'Source of truth',
                message:
                    'Immigro is not affiliated with USCIS and does not provide legal advice. Always verify important updates with USCIS.gov or your attorney.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: const Text('System'),
                selected: currentThemeMode == ThemeMode.system,
                onSelected: (_) => onThemeModeChanged(ThemeMode.system),
              ),
              ChoiceChip(
                label: const Text('Light'),
                selected: currentThemeMode == ThemeMode.light,
                onSelected: (_) => onThemeModeChanged(ThemeMode.light),
              ),
              ChoiceChip(
                label: const Text('Dark'),
                selected: currentThemeMode == ThemeMode.dark,
                onSelected: (_) => onThemeModeChanged(ThemeMode.dark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Local data',
          icon: Icons.storage_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${appState.cases.length} cases saved on this device.'),
              const SizedBox(height: 8),
              Text(
                'Local-first means the app keeps your case board in browser/app storage. It is not an encrypted vault yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showAddCaseDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add case'),
                  ),
                  OutlinedButton.icon(
                    onPressed: appState.addDemoCase,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Demo case'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.events});

  final List<CaseEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text('No timeline events saved yet.',
          style: Theme.of(context).textTheme.bodySmall);
    }

    return Column(
      children: events
          .mapIndexed(
            (index, event) => Padding(
              padding:
                  EdgeInsets.only(bottom: index == events.length - 1 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index != events.length - 1)
                        Container(
                          width: 1,
                          height: 46,
                          color: Theme.of(context).dividerTheme.color,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            _SourceChip(label: event.source),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(event.dateLabel,
                            style: Theme.of(context).textTheme.bodySmall),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(event.description,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySimpleCard extends StatelessWidget {
  const _EmptySimpleCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 34),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCaseForm extends StatefulWidget {
  const _AddCaseForm({required this.compact});

  final bool compact;

  @override
  State<_AddCaseForm> createState() => _AddCaseFormState();
}

class _AddCaseFormState extends State<_AddCaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _receiptController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _applicantController = TextEditingController();
  final _serviceCenterController = TextEditingController();
  DateTime _filedDate = DateTime.now();
  DateTime? _priorityDate;
  String _formType = 'I-485';
  bool _saving = false;

  @override
  void dispose() {
    _receiptController.dispose();
    _nicknameController.dispose();
    _applicantController.dispose();
    _serviceCenterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: !widget.compact,
        padding: EdgeInsets.fromLTRB(20, widget.compact ? 12 : 0, 20, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add case',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Start with the receipt number. Optional fields help you recognize the case later.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _receiptController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Receipt number',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
              hintText: 'IOE1234567890',
            ),
            onChanged: (value) {
              final normalized =
                  value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
              if (normalized != value) {
                _receiptController.value = TextEditingValue(
                  text: normalized,
                  selection: TextSelection.collapsed(offset: normalized.length),
                );
              }
            },
            validator: (value) {
              final appState = context.read<FFAppState>();
              final receipt = value ?? '';
              if (!appState.isValidReceipt(receipt)) {
                return 'Enter a USCIS receipt like IOE1234567890';
              }
              final normalized =
                  receipt.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
              if (appState.cases
                  .any((item) => item.receiptNumber == normalized)) {
                return 'This receipt is already tracked';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _formType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Form',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            items: const [
              'I-130',
              'I-485',
              'I-765',
              'I-131',
              'I-751',
              'N-400',
              'I-90',
              'I-129F',
            ]
                .map(
                  (form) => DropdownMenuItem(
                    value: form,
                    child: Text(form, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _formType = value ?? _formType),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: 'Nickname',
              prefixIcon: Icon(Icons.label_outline),
              hintText: 'Work permit, AOS, naturalization...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _applicantController,
            decoration: const InputDecoration(
              labelText: 'Applicant',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _serviceCenterController,
            decoration: const InputDecoration(
              labelText: 'Service center',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 440;
              final filed = _DateButton(
                label: 'Filed',
                value: _filedDate,
                onPick: () async {
                  final picked = await _pickDate(context, _filedDate);
                  if (picked != null) {
                    setState(() => _filedDate = picked);
                  }
                },
              );
              final priority = _DateButton(
                label: 'Priority',
                value: _priorityDate,
                onPick: () async {
                  final picked =
                      await _pickDate(context, _priorityDate ?? _filedDate);
                  if (picked != null) {
                    setState(() => _priorityDate = picked);
                  }
                },
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    filed,
                    const SizedBox(height: 10),
                    priority,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: filed),
                  const SizedBox(width: 10),
                  Expanded(child: priority),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _InlineBanner(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy note',
            message:
                'This saves a local tracking record. Verify official status changes at USCIS.gov.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save case'),
          ),
        ],
      ),
    );

    if (widget.compact) {
      return SafeArea(child: form);
    }

    return SizedBox(width: 560, child: form);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    await context.read<FFAppState>().addCase(
          CaseDraft(
            receiptNumber: _receiptController.text,
            formType: _formType,
            nickname: _nicknameController.text,
            applicantName: _applicantController.text,
            serviceCenter: _serviceCenterController.text,
            filedDate: _filedDate,
            priorityDate: _priorityDate,
          ),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const Icon(Icons.event_outlined),
      label: Text(
        value == null ? label : '$label ${DateFormat.MMMd().format(value!)}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

Future<void> _showAddCaseDialog(BuildContext context) {
  final compact = MediaQuery.sizeOf(context).width < 720;
  if (compact) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .9,
        minChildSize: .55,
        maxChildSize: .96,
        builder: (_, __) => const _AddCaseForm(compact: true),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: const _AddCaseForm(compact: false),
    ),
  );
}

Future<void> _showCaseDetails(BuildContext context, ImmigrationCase item) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .94,
      minChildSize: .5,
      maxChildSize: .98,
      builder: (_, __) => ChangeNotifierProvider<FFAppState>.value(
        value: context.read<FFAppState>(),
        child: _CaseDetailPanel(item: item),
      ),
    ),
  );
}

Future<void> _refreshCase(BuildContext context, ImmigrationCase item) async {
  final appState = context.read<FFAppState>();
  await appState.refreshCase(item.id);
  if (!context.mounted) {
    return;
  }
  final message = appState.lastError ?? 'Checked ${item.displayName}.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _openOfficialStatus(
  BuildContext context,
  ImmigrationCase item,
) async {
  final uri = context.read<FFAppState>().officialStatusUri(item.receiptNumber);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted || launched) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not open USCIS.gov.')),
  );
}

Future<void> _confirmDelete(BuildContext context, ImmigrationCase item) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete case?'),
      content: Text('Remove ${item.displayName} from this device.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<FFAppState>().deleteCase(item.id);
    if (context.mounted) {
      Navigator.of(context).maybePop();
    }
  }
}
