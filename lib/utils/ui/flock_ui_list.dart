import 'package:flutter/material.dart';

import '../../model/flock.dart';

class FlockHorizontalList extends StatelessWidget {
  final List<Flock> flocks;
  final String? selectedFlockId;
  final Function(Flock) onSelect;

  const FlockHorizontalList({
    super.key,
    required this.flocks,
    required this.selectedFlockId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190, // ⬅️ Increased height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        clipBehavior: Clip.none, // ⬅️ Important
        itemCount: flocks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final flock = flocks[index];
          final isSelected = flock.f_name == selectedFlockId;

          return AnimatedScale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            scale: isSelected ? 1.05 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => onSelect(flock),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: isSelected
                        ? Colors.blue.shade50
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade300
                          : Colors.grey.shade200,
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Colors.blue.withOpacity(.25)
                            : Colors.black.withOpacity(.06),
                        blurRadius: 18,
                        spreadRadius: 0,
                        offset: const Offset(0, 6), // ⬅️ smaller offset
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FlockAvatar(
                            icon: flock.icon,
                            isSelected: isSelected,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            flock.f_name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),

                      if (isSelected)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(.4),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlockAvatar extends StatelessWidget {
  final String icon;
  final bool isSelected;

  const _FlockAvatar({
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
            Colors.blue.shade300,
            Colors.blue.shade600,
          ]
              : [
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.blue.withOpacity(.4)
                : Colors.black.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: icon.isEmpty
            ? const Text(
          '🐓🦆🕊️🦃',
          style: TextStyle(fontSize: 18),
        )
            : ClipOval(
          child: Image.asset(
            icon,
            fit: BoxFit.cover,
            height: 50,
            width: 50,
          ),
        ),
      ),
    );
  }
}
