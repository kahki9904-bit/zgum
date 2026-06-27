import 'package:flutter/material.dart';

import '../../core/grid_room_layout.dart';

class ZGumOrbButton extends StatefulWidget {
  const ZGumOrbButton({
    super.key,
    required this.label,
    required this.onTap,
    this.attention = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool attention;

  @override
  State<ZGumOrbButton> createState() => _ZGumOrbButtonState();
}

class _ZGumOrbButtonState extends State<ZGumOrbButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _attentionCtrl;
  late final Animation<double> _attentionAnim;

  @override
  void initState() {
    super.initState();
    _attentionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );
    _attentionAnim = CurvedAnimation(
      parent: _attentionCtrl,
      curve: Curves.easeInOut,
    );
    if (widget.attention) {
      _attentionCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ZGumOrbButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attention == oldWidget.attention) return;
    if (widget.attention) {
      _attentionCtrl.repeat(reverse: true);
    } else {
      _attentionCtrl.stop();
      _attentionCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _attentionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = GridRoomLayoutSpec.current.orbSize;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _attentionAnim,
          builder: (context, child) {
            final pulse = widget.attention ? _attentionAnim.value : 0.0;
            return Transform.scale(
              scale: 1.0 + (pulse * 0.055),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x746D5633),
                shape: BoxShape.circle,
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x286D5633),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                  if (widget.attention)
                    const BoxShadow(
                      color: Color(0xDDECCB72),
                      blurRadius: 32,
                      spreadRadius: 6,
                    ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation<double>(0.22),
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x34E7C77B),
                          Color(0x507B5B2C),
                        ],
                      ),
                    ),
                  ),
                  if (widget.attention)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _attentionAnim,
                        builder: (context, _) {
                          final pulse = _attentionAnim.value;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.lerp(
                                const Color(0x00FFFFFF),
                                const Color(0x4DECCB72),
                                pulse,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE2C98C),
                                width: 2.2,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xA8B88A43),
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
