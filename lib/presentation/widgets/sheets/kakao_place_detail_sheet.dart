import 'package:flutter/material.dart';
import '../../../core/models/map_marker_model.dart';

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

class _PlaceSheet extends StatefulWidget {
  final MapMarkerModel place;

  const _PlaceSheet({required this.place});

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  bool _interestSet = false;

  String _formatDistance(String raw) {
    final m = int.tryParse(raw) ?? 0;
    if (m < 1000) return '${m}m';
    return '${(m / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final address = (place.roadAddress?.isNotEmpty == true)
        ? place.roadAddress!
        : place.venue;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5,
        maxHeight: screenHeight * 0.72,
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        if (place.categoryName?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            place.categoryName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF16213E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (place.distance?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDistance(place.distance!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _interestSet ? null : () => setState(() => _interestSet = true),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Icon(
                        _interestSet ? Icons.bookmark : Icons.bookmark_border,
                        size: 22,
                        color: _interestSet
                            ? const Color(0xFF16213E)
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 20),

              if (address?.isNotEmpty == true)
                _InfoRow(icon: Icons.location_on_outlined, text: address!),

              if (place.phone?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.phone_outlined, text: place.phone!),
              ],

              const SizedBox(height: 28),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 20),

              const Text(
                'Z:GUM에 등록된 이벤트가 없습니다',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFAAAAAA),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFAAAAAA)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
