import 'package:flutter/material.dart';

const washiInk = Color(0xFF3B2A1C);
const washiAccent = Color(0xFF8A5A36);
const washiRed = Color(0xFFA0473A);

/// The warm washi card in a light wooden frame that the game's panels sit
/// on. The painted frame has rounded corners, so the card is clipped to the
/// same curve and its shadow follows it.
class WashiCard extends StatelessWidget {
  const WashiCard({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.width = 780,
    this.height = 560,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const corner = BorderRadius.all(Radius.circular(13));
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        borderRadius: corner,
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 36,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: corner,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/ui_frame_choice.jpg'),
              fit: BoxFit.fill,
            ),
          ),
          // Wider on the left, clear of the pressed petal in that corner.
          padding: const EdgeInsets.fromLTRB(78, 34, 52, 36),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: washiAccent,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '閉じる',
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close,
                        color: washiAccent,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(top: 6, bottom: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        washiAccent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft, tappable row on the washi card.
class WashiRow extends StatelessWidget {
  const WashiRow({
    super.key,
    required this.child,
    this.onTap,
    this.tint = const Color(0x73FFFFFF),
    this.border = const Color(0x668A5A36),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color tint;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: washiAccent.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: child,
        ),
      ),
    );
  }
}
