import 'package:flutter/material.dart';

/// Content-sized rows stay aligned without clipping larger text.
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  const ResponsiveCardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(16) > 22
          ? 1
          : 2;
      return Column(
        children: [
          for (var index = 0; index < children.length; index += columns)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: 12),
                      Expanded(
                        child: index + column < children.length
                            ? children[index + column]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
