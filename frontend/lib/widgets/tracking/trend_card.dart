import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class TrendCard extends StatelessWidget {
  final List<double> chartData;
  final List<String> labels;
  final String selectedRange;
  final String rangeDescription;
  final List<Map<String, String>> timeRanges;
  final ValueChanged<String> onRangeChanged;

  const TrendCard({
    super.key,
    required this.chartData,
    required this.labels,
    required this.selectedRange,
    required this.rangeDescription,
    required this.timeRanges,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasChartData = chartData.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          _RangeSelector(
            timeRanges: timeRanges,
            selectedRange: selectedRange,
            onRangeChanged: onRangeChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 180,
            child: hasChartData
                ? StressChart(
                    dataPoints: chartData.map((d) => d.round()).toList(),
                    labels: labels,
                    selectedRange: selectedRange,
                  )
                : const _ChartEmpty(),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              hasChartData ? rangeDescription : 'No trend data yet',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final List<Map<String, String>> timeRanges;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const _RangeSelector({
    required this.timeRanges,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: timeRanges.map((range) {
          final isSelected = selectedRange == range['value'];
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => onRangeChanged(range['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6B9BD1).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF6B9BD1).withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Text(
                  range['label']!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? const Color(0xFF6B9BD1)
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 40,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Trend data will appear once\nyour device syncs readings.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class StressChart extends StatelessWidget {
  final List<int> dataPoints;
  final List<String> labels;
  final String selectedRange;

  const StressChart({
    super.key,
    required this.dataPoints,
    required this.labels,
    required this.selectedRange,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: StressChartPainter(
          dataPoints: dataPoints,
          labels: labels,
          selectedRange: selectedRange,
        ),
      ),
    );
  }
}

class StressChartPainter extends CustomPainter {
  final List<int> dataPoints;
  final List<String> labels;
  final String selectedRange;

  StressChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.selectedRange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    const paddingLeft = 30.0,
        paddingRight = 10.0,
        paddingTop = 10.0,
        paddingBottom = 25.0;
    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    for (int i = 0; i < 5; i++) {
      final y = paddingTop + (i / 4) * chartHeight;
      _drawDashedLine(
        canvas,
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        Paint()
          ..color = const Color(0xFFE8E8E8)
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${100 - i * 25}',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(5, y - tp.height / 2));
    }

    final stepX = dataPoints.length > 1
        ? chartWidth / (dataPoints.length - 1)
        : chartWidth;
    final points = <Offset>[
      for (int i = 0; i < dataPoints.length; i++)
        Offset(
          paddingLeft + i * stepX,
          paddingTop + chartHeight - dataPoints[i] / 100 * chartHeight,
        ),
    ];

    if (points.length > 1) {
      final fill = Path()
        ..moveTo(points.first.dx, paddingTop + chartHeight)
        ..lineTo(points.first.dx, points.first.dy);
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final cp = (points[i].dx + points[i + 1].dx) / 2;
        fill.quadraticBezierTo(
          cp, points[i].dy, cp,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        fill.quadraticBezierTo(
          cp, points[i + 1].dy, points[i + 1].dx, points[i + 1].dy,
        );
        line.quadraticBezierTo(
          cp, points[i].dy, cp,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        line.quadraticBezierTo(
          cp, points[i + 1].dy, points[i + 1].dx, points[i + 1].dy,
        );
      }
      fill.lineTo(points.last.dx, paddingTop + chartHeight);
      fill.close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x4D6B9BD1), Color(0x0D6B9BD1)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = const Color(0xFF6B9BD1)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = const Color(0xFF6B9BD1)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    if (points.isNotEmpty && labels.isNotEmpty) {
      final step = points.length > 1
          ? (points.length - 1) / (labels.length - 1)
          : 0.0;
      for (int i = 0; i < labels.length; i++) {
        final idx = (i * step).round().clamp(0, points.length - 1);
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(points[idx].dx - tp.width / 2, size.height - 12),
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0, dashSpace = 4.0;
    final distance = (end - start).distance;
    double drawn = 0;
    while (drawn < distance) {
      final seg = min(dashWidth, distance - drawn);
      canvas.drawLine(
        Offset.lerp(start, end, drawn / distance)!,
        Offset.lerp(start, end, (drawn + seg) / distance)!,
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant StressChartPainter old) =>
      old.dataPoints != dataPoints || old.selectedRange != selectedRange;
}
