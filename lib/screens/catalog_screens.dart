import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class CatalogItem {
  final int id;
  final String title;
  final double price;
  final String desc;
  bool active;

  CatalogItem({
    required this.id,
    required this.title,
    required this.price,
    required this.desc,
    this.active = true,
  });
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // Static list for UI display
  late List<CatalogItem> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = [
      CatalogItem(
        id: 1,
        title: 'Sofa Deep Chemical Wash',
        price: 49.00,
        desc: 'Eco-friendly chemical deep sanitization vacuuming process.',
        active: true,
      ),
      CatalogItem(
        id: 2,
        title: 'Lounge Sanitization Suite',
        price: 85.00,
        desc: 'Comprehensive luxury interior upholstery extraction treatment.',
        active: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Add button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catalog Management',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Active items listed inside client marketplaces.',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => context.go('/services/add'),
                    icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),

            // Service lists
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20.0),
                itemCount: _catalog.length,
                itemBuilder: (context, index) {
                  final item = _catalog[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('🛠️', style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Marketplace fixed rate: \$${item.price.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 9.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Custom Switch
                            Switch(
                              value: item.active,
                              activeColor: Colors.white,
                              activeTrackColor: AppColors.primary,
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade200,
                              onChanged: (val) {
                                setState(() {
                                  item.active = val;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.title} Marketplace Visibility Changed'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.desc,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}