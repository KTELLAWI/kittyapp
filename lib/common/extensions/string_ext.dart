import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../enums/replaced_params.dart';

extension StringExtension on String {
  String get paramSymbol {
    if (contains('?')) {
      return '&';
    }
    return '?';
  }
}

extension NullStringExtension on String? {
  String getReplacedParams(BuildContext context) {
    if (this == null) return '';

    var newText = '$this';

    for (var element in ReplacedParams.values) {
      switch (element) {
        case ReplacedParams.userName:
          final userName =
              context.select((UserModel? _) => _?.user?.name) ?? '';
          newText = newText.replaceAll(element.param, userName);
          break;
        default:
      }
    }

    return newText;
  }
}
