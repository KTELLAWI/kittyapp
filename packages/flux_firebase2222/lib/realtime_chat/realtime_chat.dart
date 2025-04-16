import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fstore/common/config.dart';
import 'package:fstore/common/constants.dart';
import 'package:fstore/common/events.dart';
import 'package:fstore/generated/l10n.dart';
import 'package:provider/provider.dart';

import 'constants/enums.dart';
import 'models/chat_view_model.dart';
import 'repos/firestore_chat_repository.dart';
import 'ui/pages/chat_dashboard/widgets/chat_list.dart';
import 'ui/pages/chat_dashboard/widgets/message_list.dart';

export 'constants/enums.dart';
export 'ui/pages/chat_rooms/chat_auth.dart';

class RealtimeChat extends StatefulWidget {
  final RealtimeChatType type;
  final String? vendorName;
  final String? vendorEmail;
  final String userEmail;
  final String? initMessage;

  /// If the [type] is [RealtimeChatType.customerToVendor],
  /// the [vendorName] and [vendorEmail] must be provided.
  /// For other [type], the [vendorName] and [vendorEmail] will be ignored.
  const RealtimeChat({
    super.key,
    required this.type,
    required this.userEmail,
    this.vendorName,
    this.vendorEmail,
    this.initMessage,
  }) : assert(
          type != RealtimeChatType.customerToVendor ||
              (type == RealtimeChatType.customerToVendor &&
                  vendorName != null &&
                  vendorEmail != null),
        );

  @override
  State<RealtimeChat> createState() => _RealtimeChatState();
}

class _RealtimeChatState extends State<RealtimeChat> {
  late final ChatViewModel _viewModel;

  StreamSubscription? _subscription;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      _init();
      _subscription = eventBus.on<EventExpiredCookie>().listen((event) {
        _isInitialized = false;
        if (mounted) {
          setState(() {});
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (_isInitialized) {
      return;
    }

    if (widget.type == RealtimeChatType.customerToVendor) {
      _viewModel = ChatViewModel(
        widget.type,
        widget.vendorName!,
        widget.vendorEmail!,
      );
    } else {
      _viewModel = ChatViewModel(
        widget.type,
        kConfigChat.realtimeChatConfig.adminName,
        kConfigChat.realtimeChatConfig.adminEmail,
      );
    }

    final repo = FirestoreChatRepository(
      widget.userEmail,
    );
    await _viewModel.init(repo);

    _isInitialized = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kConfigChat.realtimeChatConfig.enable) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  kNoChat,
                  height: 60,
                ),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  S.of(context).featureNotAvailable,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_isInitialized) {
      return Center(
        child: kLoadingWidget(context),
      );
    }

    final media = MediaQuery.of(context);

    return LayoutBuilder(builder: (_, constraints) {
      final heightBottomBar = (constraints.maxHeight != double.infinity)
          ? MediaQuery.sizeOf(context).height - constraints.maxHeight
          : (ScreenUtil.bottomBarHeight ?? 0.0);

      return MediaQuery(
        data: media.copyWith(
          viewInsets: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom - heightBottomBar,
          ),
        ),
        child: Scaffold(
          body: ChangeNotifierProvider<ChatViewModel>(
            create: (BuildContext context) => _viewModel,
            builder: (BuildContext context, Widget? child) {
              switch (widget.type) {
                case RealtimeChatType.adminToCustomers:
                case RealtimeChatType.vendorToCustomers:
                case RealtimeChatType.userToUsers:
                  return const ChatList();
                case RealtimeChatType.customerToAdmin:
                case RealtimeChatType.customerToVendor:
                default:
                  return MessageList(
                    isFromChatList: false,
                    initMessage: widget.initMessage,
                  );
              }
            },
          ),
        ),
      );
    });
  }
}
