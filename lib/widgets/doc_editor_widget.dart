import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AutoPointTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Detect single newline insertion
    if (newValue.text.length == oldValue.text.length + 1 &&
        newValue.selection.isCollapsed &&
        newValue.selection.start > 0 &&
        newValue.text[newValue.selection.start - 1] == '\n') {
      
      final cursor = newValue.selection.start; // character position immediately following '\n'
      final textBeforeNewline = newValue.text.substring(0, cursor - 1);
      final lastNewline = textBeforeNewline.lastIndexOf('\n');
      final lineStart = (lastNewline == -1) ? 0 : lastNewline + 1;
      final prevLine = textBeforeNewline.substring(lineStart);

      // Matches any point/list format: •, ☑, ☐, -, *, or numbered (1., 2., etc.)
      final match = RegExp(r'^(\s*)(•|☑|☐|\-|\*|(\d+)\.)\s*(.*)$').firstMatch(prevLine);
      if (match != null) {
        final indent = match.group(1) ?? '';
        final marker = match.group(2)!;
        final numPart = match.group(3);
        final content = match.group(4) ?? '';

        // If user hit Enter on an empty bullet line (e.g. just "• "), clear the bullet and exit list
        if (content.trim().isEmpty) {
          final prefixText = textBeforeNewline.substring(0, lineStart);
          final restText = newValue.text.substring(cursor);
          final newText = '$prefixText$restText';
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: prefixText.length),
          );
        }

        // Generate next automatic point
        String nextPrefix;
        if (numPart != null) {
          final curNum = int.tryParse(numPart) ?? 1;
          nextPrefix = '$indent${curNum + 1}. ';
        } else {
          nextPrefix = '$indent$marker ';
        }

        final newText = newValue.text.substring(0, cursor) + nextPrefix + newValue.text.substring(cursor);
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor + nextPrefix.length),
        );
      }
    }
    return newValue;
  }
}


class DocTextEditingController extends TextEditingController {
  DocTextEditingController({super.text});

  static const Map<String, Color> colorMap = {
    'cyan': Color(0xFF38BDF8),
    'blue': Color(0xFF38BDF8),
    'violet': Color(0xFFC4B5FD),
    'purple': Color(0xFFA78BFA),
    'green': Color(0xFF4ADE80),
    'yellow': Color(0xFFFACC15),
    'amber': Color(0xFFFBBF24),
    'red': Color(0xFFF87171),
    'rose': Color(0xFFFB7185),
    'orange': Color(0xFFFB923C),
    'white': Color(0xFFFFFFFF),
  };

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5);
    final rawText = text;
    if (rawText.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final lines = rawText.split('\n');
    final lineSpans = <InlineSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;
      final lineSuffix = isLastLine ? '' : '\n';

      if (line.trimLeft().startsWith('### ') || line.trimLeft().startsWith('## ') || line.trimLeft().startsWith('# ')) {
        // Heading
        final content = line.replaceAll(RegExp(r'^#+\s*'), '');
        final prefix = line.substring(0, line.length - content.length);
        lineSpans.add(TextSpan(
          children: [
            TextSpan(
              text: prefix,
              style: TextStyle(
                color: AppTheme.primary.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            ..._parseInline(
              content,
              baseStyle.copyWith(
                color: const Color(0xFFC4B5FD),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: lineSuffix, style: baseStyle),
          ],
        ));
      } else if (line.trimLeft().startsWith('• ') || line.trimLeft().startsWith('- ')) {
        // Bullet Point
        final bulletMatch = RegExp(r'^(\s*)([•\-])\s*(.*)$').firstMatch(line);
        if (bulletMatch != null) {
          final indent = bulletMatch.group(1) ?? '';
          final content = bulletMatch.group(3) ?? '';
          lineSpans.add(TextSpan(
            children: [
              TextSpan(text: indent, style: baseStyle),
              const TextSpan(
                text: '• ',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ..._parseInline(content, baseStyle),
              TextSpan(text: lineSuffix, style: baseStyle),
            ],
          ));
        } else {
          lineSpans.add(TextSpan(children: [
            ..._parseInline(line, baseStyle),
            TextSpan(text: lineSuffix, style: baseStyle),
          ]));
        }
      } else if (line.trimLeft().startsWith('☑ ') || line.trimLeft().startsWith('[x] ')) {
        // Completed Checkpoint
        final content = line.replaceFirst(RegExp(r'^(\s*)(☑|\[x\])\s*'), '');
        lineSpans.add(TextSpan(
          children: [
            const TextSpan(
              text: '☑ ',
              style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 14),
            ),
            ..._parseInline(content, baseStyle.copyWith(color: const Color(0xFF86EFAC))),
            TextSpan(text: lineSuffix, style: baseStyle),
          ],
        ));
      } else if (line.trimLeft().startsWith('☐ ') || line.trimLeft().startsWith('[ ] ')) {
        // Open Checkpoint
        final content = line.replaceFirst(RegExp(r'^(\s*)(☐|\[ \])\s*'), '');
        lineSpans.add(TextSpan(
          children: [
            const TextSpan(
              text: '☐ ',
              style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 14),
            ),
            ..._parseInline(content, baseStyle),
            TextSpan(text: lineSuffix, style: baseStyle),
          ],
        ));
      } else {
        // Normal text line
        lineSpans.add(TextSpan(children: [
          ..._parseInline(line, baseStyle),
          TextSpan(text: lineSuffix, style: baseStyle),
        ]));
      }
    }

    return TextSpan(children: lineSpans);
  }

  List<InlineSpan> _parseInline(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    // Regular expression for inline formatting:
    // 1. [color:NAME]...[/color]
    // 2. **...** (bold)
    // 3. *...* (italic)
    // 4. <b>...</b>
    // 5. <i>...</i>
    final inlineRegex = RegExp(
      r'(\[color:([a-zA-Z]+)\](.*?)\[/color\])|(\*\*(.*?)\*\*)|(\*(.*?)\*)|(<b>(.*?)</b>)|(<i>(.*?)</i>)',
      dotAll: true,
    );

    int lastMatchEnd = 0;

    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // [color:name]content[/color]
        final colorName = match.group(2)?.toLowerCase() ?? 'white';
        final content = match.group(3) ?? '';
        final textColor = colorMap[colorName] ?? Colors.white;

        spans.add(TextSpan(
          children: [
            TextSpan(
              text: '[color:$colorName]',
              style: TextStyle(color: textColor.withOpacity(0.35), fontSize: 10),
            ),
            TextSpan(
              text: content,
              style: baseStyle.copyWith(color: textColor, fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: '[/color]',
              style: TextStyle(color: textColor.withOpacity(0.35), fontSize: 10),
            ),
          ],
        ));
      } else if (match.group(4) != null) {
        // **bold**
        final content = match.group(5) ?? '';
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ));
      } else if (match.group(6) != null) {
        // *italic*
        final content = match.group(7) ?? '';
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(8) != null) {
        // <b>bold</b>
        final content = match.group(9) ?? '';
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ));
      } else if (match.group(10) != null) {
        // <i>italic</i>
        final content = match.group(11) ?? '';
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

class DocEditorWidget extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final DocTextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const DocEditorWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  State<DocEditorWidget> createState() => _DocEditorWidgetState();
}

class _DocEditorWidgetState extends State<DocEditorWidget> {
  final FocusNode _focusNode = FocusNode();

  void _insertFormat({String prefix = '', String suffix = ''}) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    final selectedText = text.substring(start, end);
    final replacement = '$prefix${selectedText.isEmpty ? "text" : selectedText}$suffix';
    final newText = text.replaceRange(start, end, replacement);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + (selectedText.isEmpty ? 4 : selectedText.length),
      ),
    );

    widget.onChanged?.call(newText);
    _focusNode.requestFocus();
  }

  void _insertLinePrefix(String linePrefix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    int start = selection.start;
    if (start < 0) start = text.length;

    // Check if we need a newline before
    final needsLeadingNewline = start > 0 && !text.substring(0, start).endsWith('\n');
    final insertion = '${needsLeadingNewline ? "\n" : ""}$linePrefix ';
    final newText = text.replaceRange(start, start, insertion);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insertion.length),
    );

    widget.onChanged?.call(newText);
    _focusNode.requestFocus();
  }

  void _insertColor(String colorName) {
    _insertFormat(prefix: '[color:$colorName]', suffix: '[/color]');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Formatting Toolbar (Bold, Italic, Heading, Bullet, Checkpoint, Colors)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF13172E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: const Color(0x227C5CFC)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolbarBtn(
                  label: 'B',
                  isBold: true,
                  tooltip: 'Bold (**text**)',
                  onTap: () => _insertFormat(prefix: '**', suffix: '**'),
                ),
                _buildToolbarBtn(
                  label: 'I',
                  isItalic: true,
                  tooltip: 'Italic (*text*)',
                  onTap: () => _insertFormat(prefix: '*', suffix: '*'),
                ),
                const SizedBox(width: 4),
                _buildDivider(),
                const SizedBox(width: 4),
                _buildToolbarBtn(
                  label: 'H',
                  tooltip: 'Heading (### Heading)',
                  onTap: () => _insertLinePrefix('###'),
                ),
                _buildToolbarBtn(
                  label: '• List',
                  tooltip: 'Bullet Point (• Item)',
                  onTap: () => _insertLinePrefix('•'),
                ),
                _buildToolbarBtn(
                  label: '☑ Point',
                  tooltip: 'Checkpoint (☑ Item)',
                  onTap: () => _insertLinePrefix('☑'),
                ),
                const SizedBox(width: 4),
                _buildDivider(),
                const SizedBox(width: 6),

                // Color picker swatches
                const Text(
                  'Color: ',
                  style: TextStyle(color: AppTheme.textDim, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                _buildColorSwatch('cyan', const Color(0xFF38BDF8), 'Cyan'),
                _buildColorSwatch('violet', const Color(0xFFC4B5FD), 'Violet'),
                _buildColorSwatch('green', const Color(0xFF4ADE80), 'Green'),
                _buildColorSwatch('yellow', const Color(0xFFFACC15), 'Yellow'),
                _buildColorSwatch('red', const Color(0xFFF87171), 'Red'),
                _buildColorSwatch('orange', const Color(0xFFFB923C), 'Orange'),
                _buildColorSwatch('white', const Color(0xFFFFFFFF), 'White'),
              ],
            ),
          ),
        ),

        // Text Editing Area
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          maxLines: 5,
          inputFormatters: [AutoPointTextInputFormatter()],
          style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5),
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: const Color(0x0AFFFFFF),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              borderSide: BorderSide(color: Color(0x227C5CFC)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              borderSide: BorderSide(color: Color(0x227C5CFC)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }

  Widget _buildToolbarBtn({
    required String label,
    bool isBold = false,
    bool isItalic = false,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withOpacity(0.12),
    );
  }

  Widget _buildColorSwatch(String name, Color color, String tooltip) {
    return Tooltip(
      message: '$tooltip text',
      child: InkWell(
        onTap: () => _insertColor(name),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

