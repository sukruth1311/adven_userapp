import 'package:flutter/material.dart';

class SideImageSection extends StatelessWidget {
  const SideImageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _textContent()),
                const SizedBox(width: 20),
                Expanded(child: _imageContent()),
              ],
            )
          : Column(
              children: [
                _imageContent(),
                const SizedBox(height: 20),
                _textContent(),
              ],
            ),
    );
  }

  Widget _textContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Get The Best Travel Experience",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        _BulletPoint(text: "Destination Collaboration"),
        _BulletPoint(text: "Amazing Tours"),
        _BulletPoint(text: "Happy Customers"),
      ],
    );
  }

  Widget _imageContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
