import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  final PageController controller;

  const BottomNav({Key? key, required this.controller}) : super(key: key);

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // گوش دادن به تغییرات PageController برای به‌روزرسانی حالت آیکون‌ها
    widget.controller.addListener(() {
      final newIndex = widget.controller.page?.round() ?? 0;
      if (newIndex != _currentIndex) {
        setState(() {
          _currentIndex = newIndex;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        height: 70, // افزایش ارتفاع برای جلوگیری از سرریز عمودی
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3), // پس‌زمینه با افکت بلور
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              activeIcon: Icons.calendar_today,
              inactiveIcon: Icons.calendar_today_outlined,
              label: 'Today',
            ),
            _buildNavItem(
              index: 1,
              activeIcon: Icons.access_time,
              inactiveIcon: Icons.access_time_outlined,
              label: 'Hourly',
            ),
            _buildNavItem(
              index: 2,
              activeIcon: Icons.calendar_month,
              inactiveIcon: Icons.calendar_month_outlined,
              label: 'Daily',
            ),
            _buildNavItem(
              index: 3,
              activeIcon: Icons.radar,
              inactiveIcon: Icons.radar_outlined, // اگر آیکون غیرفعال وجود ندارد، از همان آیکون استفاده می‌شود
              label: 'Map',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    IconData? inactiveIcon,
    required String label,
  }) {
    bool isActive = _currentIndex == index;
    return Flexible(
      child: InkWell(
        onTap: () {
          widget.controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : (inactiveIcon ?? activeIcon),
              color: isActive ? Colors.white : Colors.grey[400],
              size: 28, // کاهش اندازه آیکون برای بهینه‌سازی فضا
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[400],
                fontSize: 10, // کاهش اندازه فونت برای جلوگیری از سرریز
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // حذف listener برای جلوگیری از memory leak
    widget.controller.removeListener(() {});
    super.dispose();
  }
}