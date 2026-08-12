import 'package:flutter/material.dart';

class EForumLogo extends StatelessWidget {
  final double size;
  final bool hasGlow;

  const EForumLogo({
    super.key,
    this.size = 86,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF00E676),
        borderRadius: BorderRadius.circular(size * 0.25), // Arrondi proportionnel
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: const Color(0x3300E676),
                  blurRadius: size * 0.6,
                  spreadRadius: size * 0.1,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // La lettre E
          Text(
            'E',
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF07090F),
              height: 1.0, // Pour centrer verticalement correctement
            ),
          ),
          // Le petit rond en haut à droite
          Positioned(
            top: size * 0.22,
            right: size * 0.22,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF07090F),
                  width: size * 0.04,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
