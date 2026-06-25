import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../dialogs/zgum_dialog.dart';

/// 흔적 남길 때 한 줄 메시지 입력 팝업.
///
/// 호출 경로 두 가지:
///   1. 지금 버튼 탭 (event_detail_sheet.dart)
///   2. 푸시 알림 탭 후 앱 진입 (trace_checkin_dialog.dart → FCM 연동 후 교체 예정)
Future<String?> showTraceMessagePopup(BuildContext context) async {
  final ctrl = TextEditingController();
  String? result;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogCtx, __, ___) {
      final dialog = GestureDetector(
        onTap: () {
          Navigator.pop(dialogCtx);
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ZGumDialog(
              heightFactor: 0.28,
              actions: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      result = null;
                      Navigator.pop(dialogCtx);
                    },
                    style: TextButton.styleFrom(
                      fixedSize: const Size(96, 48),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 96,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        result =
                            ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
                        Navigator.pop(dialogCtx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.actionGold,
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '한 줄 메시지',
                    style: ZGumDialogTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    maxLength: 100,
                    autofocus: true,
                    style: ZGumDialogTextStyles.body,
                    decoration: InputDecoration(
                      hintText: '이 순간을 기록해보세요',
                      hintStyle: const TextStyle(
                          fontSize: 14, color: Color(0xFFCCCCCC)),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      counterStyle: const TextStyle(
                          fontSize: 12, color: Color(0xFFCCCCCC)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (!Platform.isIOS) return dialog;
      return MediaQuery(
        data: MediaQuery.of(dialogCtx).copyWith(viewInsets: EdgeInsets.zero),
        child: dialog,
      );
    },
  );

  ctrl.dispose();
  return result;
}
