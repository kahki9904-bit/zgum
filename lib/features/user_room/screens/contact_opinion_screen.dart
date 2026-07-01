import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';

class ContactOpinionScreen extends StatefulWidget {
  const ContactOpinionScreen({super.key});

  @override
  State<ContactOpinionScreen> createState() => _ContactOpinionScreenState();
}

class _ContactOpinionScreenState extends State<ContactOpinionScreen> {
  static const _items = [
    '서비스 이용 문의',
    '이벤트 등록 문의',
    '이벤트 삭제 요청',
    '오류 제보',
  ];

  final _controller = TextEditingController();
  int _selectedIndex = 0;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await FirebaseFirestore.instance.collection('contact_opinions').add({
        'category': _items[_selectedIndex],
        'content': content,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() { _sending = false; _sent = true; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.actionGoldText),
        title: const Text(
          '문의 및 의견',
          style: TextStyle(
            color: AppColors.actionGoldText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '확인이 필요한 내용을 운영자에게 보낼 수 있습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 42,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (_, i) => _ChoiceChip(
                        label: _items[i],
                        selected: _selectedIndex == i,
                        onTap: () => setState(() => _selectedIndex = i),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      maxLength: 200,
                      maxLines: 7,
                      minLines: 7,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: '내용을 적어 주세요.',
                        hintStyle: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 13,
                        ),
                        counterStyle: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F7F8),
                        contentPadding:
                            const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '서비스 확인과 개선을 위해 관련 앱 기록을 함께 확인할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: ZGumButton(
                label: _sent ? '전송됨' : (_sending ? '전송 중...' : '보내기'),
                onTap: (_sending || _sent) ? () {} : _onSend,
                widthFactor: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.actionGoldSoft : const Color(0xFFF6F6F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.actionGoldBorder : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.actionGoldText : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}
