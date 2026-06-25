import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/map_marker_model.dart';
import '../../../core/theme/app_colors.dart';

class KakaoPlaceDetailSheet {
  const KakaoPlaceDetailSheet._();

  static void show(BuildContext context, MapMarkerModel place) {
    if (!context.mounted) return;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, __, ___) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: _PlaceSheet(place: place),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  final MapMarkerModel place;

  const _PlaceSheet({required this.place});

  String get _address => (place.roadAddress?.isNotEmpty == true)
      ? place.roadAddress!
      : (place.venue ?? '');

  Future<void> _navigate() async {
    final url = place.placeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.45),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          shrinkWrap: true,
          children: [
            SizedBox(
              height: 36,
              child: Marquee(
                text: place.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                scrollAxis: Axis.horizontal,
                blankSpace: 40.0,
                velocity: 40.0,
                startAfter: const Duration(seconds: 1),
                pauseAfterRound: const Duration(seconds: 1),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Z:GUM에 등록된 이벤트가 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFAAAAAA),
                height: 1.75,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_address.isNotEmpty)
                        Text(
                          _address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      if (place.phone?.isNotEmpty == true)
                        Text(
                          place.phone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                    ],
                  ),
                ),
                if (place.placeUrl?.isNotEmpty == true)
                  GestureDetector(
                    onTap: _navigate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.actionGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '길찾기',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
