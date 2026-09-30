import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'app_theme.dart';

class WebsiteSectionTitle extends StatelessWidget {
  const WebsiteSectionTitle(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppTheme.textMuted,
      ),
    ),
  );
}

class WebsiteStatusPanel extends StatelessWidget {
  const WebsiteStatusPanel(
    this.title, {
    super.key,
    this.message,
    this.icon = Icons.inbox_outlined,
  });
  final String title;
  final String? message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border.all(color: AppTheme.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.textMuted, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 5),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
          ),
        ],
      ],
    ),
  );
}

class WebsiteRows extends StatelessWidget {
  const WebsiteRows({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border.all(color: AppTheme.border),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(),
          children[i],
        ],
      ],
    ),
  );
}

class WebsiteMetricCard extends StatelessWidget {
  const WebsiteMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });
  final String label, value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    width: (MediaQuery.sizeOf(context).width - 42).clamp(0, 360) / 2,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border.all(color: AppTheme.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            if (icon != null) Icon(icon, size: 15, color: AppTheme.textMuted),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: AppTheme.text,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

class WebsiteMiniStat extends StatelessWidget {
  const WebsiteMiniStat({super.key, required this.label, required this.value});
  final String label, value;
  @override Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 104),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: AppTheme.surface,
      border: Border.all(color: AppTheme.border),
      borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 10.5,
        fontWeight: FontWeight.w700, letterSpacing: 1.0,
        color: AppTheme.textMuted)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontSize: 17,
        fontWeight: FontWeight.w600, color: AppTheme.text,
        fontFeatures: [FontFeature.tabularFigures()])),
    ]),
  );
}

class WebsiteRevenueChart extends StatelessWidget {
  const WebsiteRevenueChart({super.key, required this.values});
  final List<(String, int)> values;
  @override
  Widget build(BuildContext context) => Container(
    height: 240,
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border.all(color: AppTheme.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: CustomPaint(painter: _RevenuePainter(values)),
  );
}

class _RevenuePainter extends CustomPainter {
  _RevenuePainter(this.values);
  final List<(String, int)> values;
  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(38, 8, size.width - 8, size.height - 26);
    final max = values.fold<int>(1, (m, v) => math.max(m, v.$2));
    final grid = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = plot.bottom - plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _label(canvas, '${(max * i / 3).round()}', Offset(0, y - 7));
    }
    if (values.isEmpty) return;
    final step = plot.width / values.length;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = plot.left + step * (i + .5);
      final y = plot.bottom - plot.height * values[i].$2 / max;
      points.add(Offset(x, y));
      if (values.length <= 12) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              x - math.min(22, step * .35),
              y,
              math.min(44, step * .7),
              plot.bottom - y,
            ),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()..color = AppTheme.brand,
        );
      }
      if (i % math.max(1, (values.length / 6).ceil()) == 0) {
        _label(canvas, values[i].$1, Offset(x - 16, plot.bottom + 5));
      }
    }
    if (values.length > 12) {
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        line.lineTo(point.dx, point.dy);
      }
      final area = Path.from(line)
        ..lineTo(points.last.dx, plot.bottom)
        ..lineTo(points.first.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x734F6BFF), Color(0x0A4F6BFF)],
          ).createShader(plot),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = const Color(0xFF4F6BFF)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _label(Canvas canvas, String label, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    painter.layout(maxWidth: 50);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RevenuePainter old) => old.values != values;
}

class WebsiteExpenseChart extends StatelessWidget {
  const WebsiteExpenseChart({super.key, required this.values});
  final List<(String, int)> values;
  static const colors = [
    Color(0xFF4F6BFF),
    AppTheme.success,
    AppTheme.warning,
    AppTheme.danger,
    AppTheme.brand,
    Color(0xFF9B6BF0),
    AppTheme.textMuted,
  ];
  @override
  Widget build(BuildContext context) {
    final total = values.fold<int>(0, (sum, v) => sum + v.$2);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: CustomPaint(painter: _ExpensePainter(values, total)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (var i = 0; i < values.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      values[i].$1,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpensePainter extends CustomPainter {
  _ExpensePainter(this.values, this.total);
  final List<(String, int)> values;
  final int total;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 76);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = total == 0 ? 0.0 : 2 * math.pi * values[i].$2 / total;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color =
              WebsiteExpenseChart.colors[i % WebsiteExpenseChart.colors.length]
          ..strokeWidth = 28
          ..style = PaintingStyle.stroke,
      );
      start += sweep;
    }
    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..color = AppTheme.surface3
          ..strokeWidth = 28
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExpensePainter old) =>
      old.values != values || old.total != total;
}
