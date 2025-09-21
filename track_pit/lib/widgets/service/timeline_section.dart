import 'package:flutter/material.dart';
import 'package:track_pit/core/constants/colors.dart';

/// ---------------------------------------------------------------------------
/// 🛠️ TimelineSection usage guide
///
/// This widget shows a fixed 4-step service timeline:
///   1. In Inspection
///   2. Parts Awaiting
///   3. In Repair
///   4. Ready for Collection
///
/// You can control the state of each step by passing a list of
/// `TimelineStep(dateTime: ...)`.
///
/// ───────────────────────────────
/// Variants
/// ───────────────────────────────
///
/// ✅ 1. No parameter passed → all steps are upcoming
/// ```dart
/// const TimelineSection()
/// ```
///
/// ✅ 2. All steps null → first step is current, others upcoming
/// ```dart
/// TimelineSection(
///   steps: const [
///     TimelineStep(dateTime: null),
///     TimelineStep(dateTime: null),
///     TimelineStep(dateTime: null),
///     TimelineStep(dateTime: null),
///   ],
/// )
/// ```
///
/// ✅ 3. Mixed steps →
/// - Non-null DateTime → Done (with date+time shown)
/// - First null → Current
/// - Remaining null → Upcoming
/// ```dart
/// TimelineSection(
///   steps: const [
///     TimelineStep(dateTime: DateTime(2025, 8, 19, 14, 0)), // Done
///     TimelineStep(dateTime: DateTime(2025, 8, 19, 15, 0)), // Done
///     TimelineStep(dateTime: null), // Current
///     TimelineStep(dateTime: null), // Upcoming
///   ],
/// )
/// ```
///
/// ✅ 4. All steps done (no nulls) → last step is current
/// ```dart
/// TimelineSection(
///   steps: const [
///     TimelineStep(dateTime: DateTime(2025, 8, 19, 14, 0)),
///     TimelineStep(dateTime: DateTime(2025, 8, 19, 15, 0)),
///     TimelineStep(dateTime: DateTime(2025, 8, 19, 16, 0)),
///     TimelineStep(dateTime: DateTime(2025, 8, 19, 17, 0)),
///   ],
/// )
/// ```
///
/// ---------------------------------------------------------------------------

class TimelineStep {
  final DateTime? dateTime;
  const TimelineStep({required this.dateTime});

  @override
  String toString() {
    if (dateTime == null) return "TimelineStep(dateTime: null)";
    return "TimelineStep(dateTime: ${dateTime!.toIso8601String()})";
  }
}

enum TimelineState { done, current, upcoming }

class TimelineSection extends StatelessWidget {
  const TimelineSection({super.key, this.steps});

  final List<TimelineStep>? steps;

  static const fixedTexts = [
    "In Inspection",
    "Parts Awaiting",
    "In Repair",
    "Ready for Collection",
  ];

  static const double dotSizeCurrent = 34;
  static const double dotSizeDefault = 26;
  static const double dotBorderWidthCurrent = 4;
  static const double dotBorderWidthDefault = 2;
  static const double iconSizeCurrent = 24;
  static const double iconSizeDefault = 16;

  static const double lineWidth = 6;
  static const double lineHeight = 90;

  static const double timeWidth = 120;
  static const double textWidth = 180;

  static const double timeFontSize = 15;
  static const double textFontSize = 16;

  static const FontWeight timeFontWeight = FontWeight.w600;
  static const Color timeFontColor = Colors.black87;

  static const FontWeight textFontWeightCurrent = FontWeight.w800;
  static const FontWeight textFontWeightDefault = FontWeight.w600;
  static const Color textFontColorDefault = Colors.black87;
  static const Color textFontColorUpcoming = Colors.black54;

  String? _formatDateTime(DateTime? dt) {
    if (dt == null) return null;

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    final dateStr =
        "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}";
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "${hour.toString().padLeft(2, '0')}:$minute $period";

    return "$dateStr\n$timeStr";
  }

  Color _dotBorderColor(TimelineState s) {
    switch (s) {
      case TimelineState.done:
        return AppColors.secondaryGreen;
      case TimelineState.current:
        return AppColors.primaryGreen;
      case TimelineState.upcoming:
        return AppColors.primaryAccent;
    }
  }

  Widget _dot(TimelineState s) {
    final border = _dotBorderColor(s);
    final isDone = s == TimelineState.done;
    final isCurrent = s == TimelineState.current;

    final double size = isCurrent ? dotSizeCurrent : dotSizeDefault;
    final double borderWidth =
        isCurrent ? dotBorderWidthCurrent : dotBorderWidthDefault;
    final Color bgColor = (isDone || isCurrent) ? border : Colors.white;

    IconData? icon;
    Color iconColor = Colors.white;
    if (isDone) {
      icon = Icons.check;
    } else if (isCurrent) {
      icon = Icons.timelapse;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: border, width: borderWidth),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child:
          icon != null
              ? Icon(
                icon,
                size: isCurrent ? iconSizeCurrent : iconSizeDefault,
                color: iconColor,
              )
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSteps =
        steps ??
        List.generate(
          fixedTexts.length,
          (_) => const TimelineStep(dateTime: null),
        );

    final stepsNotPassed = steps == null;

    int currentIdx = effectiveSteps.indexWhere((s) => s.dateTime == null);

    if (stepsNotPassed) {
      currentIdx = -1;
    } else if (currentIdx == -1) {
      currentIdx = effectiveSteps.length - 1;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(effectiveSteps.length, (i) {
        final step = effectiveSteps[i];
        final isLast = i == effectiveSteps.length - 1;

        TimelineState state;
        if (step.dateTime != null) {
          state = TimelineState.done;
        } else if (i == currentIdx && currentIdx != -1) {
          state = TimelineState.current;
        } else {
          state = TimelineState.upcoming;
        }

        final bool fillBelow = i < currentIdx;
        final Color segmentColor =
            fillBelow
                ? AppColors.primaryGreen
                : AppColors.primaryGreen.withValues(alpha: 0.5);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: timeWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, right: 14),
                child: Text(
                  _formatDateTime(step.dateTime) ?? "",
                  style: const TextStyle(
                    fontSize: timeFontSize,
                    color: timeFontColor,
                    fontWeight: timeFontWeight,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),

            Column(
              children: [
                _dot(state),
                if (!isLast)
                  Container(
                    width: lineWidth,
                    height: lineHeight,
                    color: segmentColor,
                  ),
              ],
            ),

            SizedBox(
              width: textWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, left: 14),
                child: Text(
                  fixedTexts[i],
                  softWrap: true,
                  style: TextStyle(
                    fontSize: textFontSize,
                    color:
                        state == TimelineState.upcoming
                            ? textFontColorUpcoming
                            : textFontColorDefault,
                    fontWeight:
                        state == TimelineState.current
                            ? textFontWeightCurrent
                            : textFontWeightDefault,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
