import 'package:flutter/material.dart';

class ChatAppBarArea extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showNewChatButton;
  final bool showHistoryButton;
  final Function? onNewChatPressed;
  final Function? onHistoryPressed;

  const ChatAppBarArea({
    Key? key,
    this.title,
    this.showNewChatButton = true,
    this.showHistoryButton = true,
    this.onNewChatPressed,
    this.onHistoryPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      actions: [
        if (showNewChatButton)
          IconButton(
            onPressed: () {
              if (onNewChatPressed != null) {
                onNewChatPressed!();
              }
            },
            icon: const Icon(Icons.add),
          ),
        if (showHistoryButton)
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  if (onHistoryPressed != null) {
                    onHistoryPressed!(context);
                  }
                },
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
