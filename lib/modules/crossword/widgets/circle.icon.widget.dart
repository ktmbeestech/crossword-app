
import 'package:flutter/material.dart';

Widget circleIcon(BuildContext context, {required AssetImage icon,required VoidCallback onTap}) {
  return InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: onTap,
    child: Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Image.asset(
        icon.assetName,
        width: 58,
        height: 58,
      ),
    ),
  );
}

