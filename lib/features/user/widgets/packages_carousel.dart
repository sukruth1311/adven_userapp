import 'package:flutter/material.dart';
import 'package:user_app/features/user/package_request_screen.dart';

class PackagesCarousel extends StatefulWidget {
  const PackagesCarousel({super.key});

  @override
  State<PackagesCarousel> createState() => _PackagesCarouselState();
}

class _PackagesCarouselState extends State<PackagesCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.85);
  int currentIndex = 0;

  final packages = const [
    {
      "title": "3 Years",
      "price": "₹3,75,000",
      "color1": Color(0xFF6A11CB),
      "color2": Color(0xFF2575FC),
    },
    {
      "title": "5 Years",
      "price": "₹5,25,000",
      "color1": Color(0xFFFF512F),
      "color2": Color(0xFFDD2476),
    },
    {
      "title": "10 Years",
      "price": "₹7,25,000",
      "color1": Color(0xFF11998E),
      "color2": Color(0xFF38EF7D),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Membership Packages",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _controller,
            itemCount: packages.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              final scale = currentIndex == index ? 1.0 : 0.92;

              return AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: scale,
                child: _packageCard(
                  title: packages[index]["title"] as String,
                  price: packages[index]["price"] as String,
                  color1: packages[index]["color1"] as Color,
                  color2: packages[index]["color2"] as Color,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            packages.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentIndex == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentIndex == index
                    ? Colors.deepPurple
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _packageCard({
    required String title,
    required String price,
    required Color color1,
    required Color color2,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black26,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              price,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PackageRequestScreen(packageType: title),
                    ),
                  );
                },

                child: const Text(
                  "Book Now",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
