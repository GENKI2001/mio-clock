import 'package:flutter/material.dart';

/// The title screen's painting and name, without its buttons. It is also
/// rendered into the iOS launch image, so opening the app goes straight from
/// this picture to the title screen.
class TitleArt extends StatelessWidget {
  const TitleArt({super.key, this.footer});

  /// Sits under the name (the title screen's buttons).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/room_2126.png',
          fit: BoxFit.fill,
          errorBuilder: (_, error, stack) =>
              Container(color: const Color(0xFF10222C)),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xF0091625), Color(0xB0061728), Color(0x55030A11)],
              stops: [0, 0.53, 1],
            ),
          ),
        ),
        Positioned(
          left: 100,
          top: 90,
          width: 790,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ミオと\n百年時計',
                style: TextStyle(
                  fontFamily: 'MioPen',
                  color: Color(0xFFF3E6C8),
                  fontSize: 82,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black, blurRadius: 24)],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '― ときわけ書斎の約束 ―',
                style: TextStyle(
                  fontFamily: 'MioPen',
                  color: Color(0xFFD7C4A5),
                  fontSize: 27,
                  letterSpacing: 5,
                ),
              ),
              if (footer != null) ...[const SizedBox(height: 46), footer!],
            ],
          ),
        ),
      ],
    );
  }
}
