import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class InlineLatexText extends StatelessWidget {
  /// Helper widget: hiển thị text có thể chứa LaTeX inline như: "Phép nhân \\( \\dfrac{3}{4} \\times \\dfrac{2}{5} \\) bằng:"
  /// - Tách đoạn plain text và LaTeX (pattern: \(...\))
  /// - Plain text => TextSpan, LaTeX => WidgetSpan(Math.tex)
  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;
  final FontWeight fontWeight;

  const InlineLatexText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color,
    this.textAlign = TextAlign.start,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    final reg = RegExp(r'\\\((.*?)\\\)', dotAll: true);
    final matches = reg.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          color: color ?? Colors.black,
          fontWeight: fontWeight,
        ),
      );
    }

    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (final m in matches) {
      if (m.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, m.start),
            style: TextStyle(
              fontSize: fontSize,
              color: color ?? Colors.black,
              fontWeight: fontWeight,
              height: 1.3,
            ),
          ),
        );
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Math.tex(
              m.group(1) ?? '',
              mathStyle: MathStyle.text,
              textStyle: TextStyle(fontSize: fontSize),
            ),
          ),
        ),
      );

      currentIndex = m.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(
            fontSize: fontSize,
            color: color ?? Colors.black,
            fontWeight: fontWeight,
            height: 1.3,
          ),
        ),
      );
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }
}
