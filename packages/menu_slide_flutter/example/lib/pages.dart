import 'package:flutter/material.dart';

/// Small, theme-aware placeholder pages for the demo — one per menu item id
/// (`dashboard`, `projects`, `search`, `profile`, `notifications`,
/// `billing`).
///
/// Every color here comes from `Theme.of(context)`, never a hardcoded
/// constant, so flipping [MenuSlideController.themeMode] visibly re-themes
/// this content too, not just the menu panel — see `main.dart`.

/// A single stat shown in a page's stat row (e.g. "Revenue" / "$12.4k").
class _Stat {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
}

/// A single row rendered inside a [_SectionCard].
class _TileData {
  const _TileData(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

/// Shared page chrome: an identity row (icon + title + subtitle), an
/// optional stat row, and a list of extra content widgets (typically
/// [_SectionCard]s). Keeping this in one place is what makes each page below
/// a few lines of data instead of repeated boilerplate.
class _DemoPage extends StatelessWidget {
  const _DemoPage({
    required this.pageKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.stats = const [],
    this.children = const [],
  });

  final Key pageKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_Stat> stats;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: pageKey,
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.headlineSmall),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    Expanded(child: _StatCard(stat: stats[i])),
                    if (i != stats.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat.value, style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              stat.label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.tiles});
  final String title;
  final List<_TileData> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          for (final tile in tiles)
            ListTile(
              leading: Icon(tile.icon, color: theme.colorScheme.primary),
              title: Text(tile.title),
              subtitle: Text(tile.subtitle),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoPage(
      pageKey: const Key('page-dashboard'),
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      subtitle: 'Your workspace at a glance',
      stats: const [
        _Stat('Revenue', '\$12.4k'),
        _Stat('Active users', '3,204'),
        _Stat('Uptime', '99.9%'),
      ],
      children: const [
        _SectionCard(
          title: 'Recent activity',
          tiles: [
            _TileData(Icons.check_circle_outline, 'Deploy succeeded',
                'main branch · 2 minutes ago'),
            _TileData(Icons.person_add_alt, 'New teammate invited', 'design@company.com'),
            _TileData(Icons.bug_report_outlined, 'Issue closed', '#482 login redirect loop'),
          ],
        ),
      ],
    );
  }
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoPage(
      pageKey: const Key('page-projects'),
      icon: Icons.folder_outlined,
      title: 'Projects',
      subtitle: '3 active, 1 planned',
      stats: const [
        _Stat('In progress', '3'),
        _Stat('Completed', '12'),
      ],
      children: const [
        _SectionCard(
          title: 'All projects',
          tiles: [
            _TileData(Icons.circle, 'menu_slide_flutter', 'In progress'),
            _TileData(Icons.circle_outlined, 'Docs site', 'Done'),
            _TileData(Icons.schedule, 'Mobile app', 'Planned'),
          ],
        ),
      ],
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DemoPage(
      pageKey: const Key('page-search'),
      icon: Icons.search,
      title: 'Search',
      subtitle: 'Find anything across your workspace',
      children: [
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Search projects, files, people…',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionCard(
          title: 'Recent results',
          tiles: [
            _TileData(Icons.description_outlined, 'Q3 roadmap.docx', 'Modified yesterday'),
            _TileData(Icons.folder_outlined, 'menu_slide_flutter', 'Project'),
            _TileData(Icons.person_outline, 'Alex Rivera', 'Teammate'),
          ],
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoPage(
      pageKey: const Key('page-profile'),
      icon: Icons.person_outline,
      title: 'Profile',
      subtitle: 'Alex Rivera · Product Engineer',
      children: const [
        _SectionCard(
          title: 'Account details',
          tiles: [
            _TileData(Icons.email_outlined, 'Email', 'alex.rivera@company.com'),
            _TileData(Icons.groups_outlined, 'Team', 'Platform'),
            _TileData(Icons.badge_outlined, 'Role', 'Product Engineer'),
          ],
        ),
      ],
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoPage(
      pageKey: const Key('page-notifications'),
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      subtitle: '3 unread',
      children: const [
        _SectionCard(
          title: 'Unread',
          tiles: [
            _TileData(Icons.comment_outlined, 'New comment on "Q3 roadmap"', '5 minutes ago'),
            _TileData(Icons.rocket_launch_outlined, 'Release v1.4.0 shipped', '1 hour ago'),
            _TileData(Icons.warning_amber_outlined, 'Billing card expiring soon', 'Yesterday'),
          ],
        ),
      ],
    );
  }
}

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoPage(
      pageKey: const Key('page-billing'),
      icon: Icons.credit_card_outlined,
      title: 'Billing',
      subtitle: 'Team plan · renews monthly',
      stats: const [
        _Stat('Plan', 'Team'),
        _Stat('Seats', '12'),
      ],
      children: const [
        _SectionCard(
          title: 'Billing history',
          tiles: [
            _TileData(Icons.receipt_long_outlined, 'Invoice #0021', '\$240.00 · Paid'),
            _TileData(Icons.receipt_long_outlined, 'Invoice #0020', '\$240.00 · Paid'),
          ],
        ),
      ],
    );
  }
}
