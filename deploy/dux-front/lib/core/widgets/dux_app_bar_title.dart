import 'package:flutter/material.dart';

class DuxAppBarTitle extends StatelessWidget {
  final String title;

  const DuxAppBarTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.network(
          'https://new.dux-erp.com/assets/Img/duxlogo01.png',
          height: 32,
          semanticLabel: 'DUX',
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
