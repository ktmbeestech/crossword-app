import 'package:flutter/material.dart';

customText(
    {required String text,
      Color? color,
      FontWeight? fontWeight,
      TextAlign? textAlign,
      double? fontSize,
      int? maxLines,
      TextDecoration? textDecoration,
      TextDecorationStyle? textDecorationStyle,
      FontStyle? fontStyle,
      TextOverflow? overflow}) =>

    Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          decoration: textDecoration,
          decorationStyle: textDecorationStyle,
          fontStyle: fontStyle,
          color: color,
          decorationColor: color),
    );
