import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';

// Legacy text styles, kept by name for the older screens but mapped onto the
// app palette (see core/app_theme.dart). New code should use the theme
// directly instead of these numbered styles.

/// Empty on purpose: fields pick up `inputDecorationTheme` from the app theme.
const textInputDecoration = InputDecoration();

/// Large heading.
const textStyle1 = TextStyle(
    fontSize: 28, color: AppColors.charcoal, fontWeight: FontWeight.w700);

/// White label, for text on dark/coloured buttons.
const textStyle2 =
    TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600);

/// Field label / emphasised body.
const textStyle3 =
    TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w600);

/// Large body.
const textStyle4 = TextStyle(fontSize: 18, color: AppColors.ink);

/// Body.
const textStyle5 = TextStyle(fontSize: 15, color: AppColors.ink);

/// Helper / caption.
const textStyle6 = TextStyle(fontSize: 13, color: AppColors.muted);

/// Link.
const textStyle7 = TextStyle(
    fontSize: 14, color: AppColors.goldDeep, fontWeight: FontWeight.w600);

/// Accent body.
const textStyle8 = TextStyle(fontSize: 15, color: AppColors.goldDeep);

const textStyle9 = TextStyle(
    fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w700);

/// Section heading.
const textStyle10 = TextStyle(
    fontSize: 20, color: AppColors.charcoal, fontWeight: FontWeight.w700);

const textStyle11 = TextStyle(fontSize: 11, color: AppColors.ink);

const textStyle12 = TextStyle(fontSize: 14, color: AppColors.ink);

const textStyle13 = TextStyle(fontSize: 12, color: AppColors.ink);

const textStyle14 = TextStyle(fontSize: 11, color: AppColors.muted);

/// Warning / error message.
const textStyle15 = TextStyle(
    fontSize: 17, color: AppColors.bad, fontWeight: FontWeight.w700);

const textStyle16 = TextStyle(
    fontSize: 26, color: AppColors.charcoal, fontWeight: FontWeight.w700);

const textStyle17 = TextStyle(
    fontSize: 28, color: AppColors.gold, fontWeight: FontWeight.w700);

const textStyle18 = TextStyle(
    fontSize: 22, color: AppColors.goldDeep, fontWeight: FontWeight.w700);

/// Big alert number.
const textStyle19 = TextStyle(
    fontSize: 34, color: AppColors.bad, fontWeight: FontWeight.w800);

const timerTextStyle = TextStyle(
    color: AppColors.charcoal, fontSize: 36, fontWeight: FontWeight.w700);

const timer2TextStyle = TextStyle(
    color: AppColors.charcoal, fontSize: 24, fontWeight: FontWeight.w700);

const buttonStyle =
    TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white);
