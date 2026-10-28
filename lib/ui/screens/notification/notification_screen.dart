
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_cubit.dart';
import 'notification_item.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inMinutes < 1) return 'Just now';
    if (now.difference(date).inHours < 1) {
      return '${now.difference(date).inMinutes} min ago';
    }
    if (now.difference(date).inDays < 1) {
      return '${now.difference(date).inHours} hr ago';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationCubit, List<NotificationItem>>(
            builder: (context, notifications) {
              final hasUnread =
              notifications.any((item) => !item.isRead);

              return TextButton(
                onPressed: hasUnread
                    ? () => context
                    .read<NotificationCubit>()
                    .markAllAsRead()
                    : null,
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, List<NotificationItem>>(
        builder: (context, notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your income and expense updates will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = notifications[index];

              return Card(
                margin: EdgeInsets.zero,
                color: item.isRead
                    ? colors.surface
                    : colors.primaryContainer.withValues(alpha: 0.45),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      item.title.contains('Income')
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight:
                      item.isRead ? FontWeight.w500 : FontWeight.w800,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.message),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(item.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'read') {
                        context
                            .read<NotificationCubit>()
                            .markAsRead(item.id);
                      } else if (value == 'delete') {
                        context
                            .read<NotificationCubit>()
                            .deleteNotification(item.id);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!item.isRead)
                        const PopupMenuItem(
                          value: 'read',
                          child: Text('Mark as read'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                  onTap: () {
                    context
                        .read<NotificationCubit>()
                        .markAsRead(item.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
