import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../profile/providers/profile_providers.dart';
import '../../domain/chat_message.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: profile == null
          ? const SizedBox()
          : StreamBuilder<List<ChatThread>>(
              stream: ref.watch(chatRepositoryProvider).watchThreadsFor(profile.uid),
              builder: (context, snapshot) {
                final threads = snapshot.data ?? [];
                if (threads.isEmpty) {
                  return const Center(child: Text('Noch keine Chats.'));
                }
                return ListView.separated(
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final thread = threads[i];
                    final otherId = thread.participantIds.firstWhere(
                      (id) => id != profile.uid,
                      orElse: () => '',
                    );
                    final otherProfile = ref.watch(profileByIdProvider(otherId)).valueOrNull;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: otherProfile?.photoUrl != null
                            ? NetworkImage(otherProfile!.photoUrl!)
                            : null,
                        child: otherProfile?.photoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(otherProfile?.displayName ?? 'Nutzer*in'),
                      subtitle: Text(
                        thread.lastMessage ?? 'Noch keine Nachrichten',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: thread.lastMessageAt != null
                          ? Text(
                              timeago.format(thread.lastMessageAt!, locale: 'de'),
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                      onTap: () => context.push(AppRoutes.chatThreadPath(thread.id)),
                    );
                  },
                );
              },
            ),
    );
  }
}
