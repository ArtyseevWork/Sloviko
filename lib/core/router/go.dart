import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navigation helper. Project convention: never call Navigator.of(context)
/// or context.go(...) directly from widgets — go through `Go.to(...)`.
class Go {
  Go._();

  static void to(BuildContext context, String path, {Object? extra}) {
    GoRouter.of(context).go(path, extra: extra);
  }

  static void push(BuildContext context, String path, {Object? extra}) {
    GoRouter.of(context).push(path, extra: extra);
  }

  static void back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
  }
}
