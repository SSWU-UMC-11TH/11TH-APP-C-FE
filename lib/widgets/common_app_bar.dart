import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 화면마다 달라지는 제목·뒤로가기·오른쪽 버튼만 밖에서 받는 공용 AppBar.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: titleStyle ??
            AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
      ),
      centerTitle: centerTitle,
      // onBack이 없으면 뒤로가기 버튼을 그리지 않습니다.
      automaticallyImplyLeading: false,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              tooltip: '뒤로가기',
            ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
