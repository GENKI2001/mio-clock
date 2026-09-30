import 'package:flutter/material.dart';

class PaperPanel extends StatelessWidget {
  const PaperPanel({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.width = 750,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(maxHeight: 630),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E6C8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFAA8252), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 44,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(29, 15, 15, 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF34291F),
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '閉じる',
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF34291F),
                    size: 29,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 2, color: const Color(0xFFBE9C6B)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(29, 22, 29, 29),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Color(0xFF34291F),
                  fontSize: 22,
                  height: 1.52,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ButtonStyle parchmentButton({bool primary = false}) => ButtonStyle(
  backgroundColor: WidgetStatePropertyAll(
    primary ? const Color(0xFF8B5230) : const Color(0xFFCEAF7D),
  ),
  foregroundColor: WidgetStatePropertyAll(
    primary ? const Color(0xFFFFF4DB) : const Color(0xFF34291F),
  ),
  side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFAA8252))),
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 22, vertical: 14),
  ),
  textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 20)),
);
