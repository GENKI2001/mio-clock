import 'package:flutter/material.dart';

/// One of Mio's letters, shown as the sheet she wrote it on: painted paper
/// with her handwriting laid over it.
class LetterPanel extends StatelessWidget {
  const LetterPanel({
    super.key,
    required this.id,
    required this.text,
    required this.onClose,
  });

  static const letterIds = {'memo1', 'memo2', 'memo3', 'memo4'};

  final String id;
  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // The last letter is from eighteen-year-old Mio, in a steadier pen hand;
    // the third was written in citrus juice and browned by the fire.
    final grownUp = id == 'memo4';
    final ink = switch (id) {
      'memo3' => const Color(0xFF7A4115),
      'memo4' => const Color(0xFF1F2438),
      _ => const Color(0xFF2B3050),
    };
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: onClose,
        child: Transform.rotate(
          angle: id == 'memo2' ? 0.012 : -0.015,
          child: Container(
            width: 470,
            height: 700,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 36,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/letter_$id.jpg',
                  fit: BoxFit.fill,
                  errorBuilder: (_, error, stack) =>
                      const ColoredBox(color: Color(0xFFF1E4C6)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 64, 44, 56),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 374,
                      child: Text(
                        text,
                        style: TextStyle(
                          fontFamily: grownUp ? 'MioPen' : 'MioHand',
                          color: ink.withValues(alpha: 0.92),
                          fontSize: grownUp ? 19 : 21,
                          height: 1.62,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
