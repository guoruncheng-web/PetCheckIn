import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pet_checkin/data/cities.dart';

/// 城市选择器
class CitySelector extends StatefulWidget {
  final CityData? selectedCity;
  final ValueChanged<CityData> onCitySelected;

  const CitySelector({
    super.key,
    this.selectedCity,
    required this.onCitySelected,
  });

  @override
  State<CitySelector> createState() => _CitySelectorState();
}

class _CitySelectorState extends State<CitySelector> {
  String _searchQuery = '';
  List<CityData> _filteredCities = chineseCities;

  @override
  void initState() {
    super.initState();
    _filteredCities = chineseCities;
  }

  void _filterCities(String query) {
    setState(() {
      _searchQuery = query.trim();
      if (_searchQuery.isEmpty) {
        _filteredCities = chineseCities;
      } else {
        _filteredCities = chineseCities
            .where((city) =>
                city.name.contains(_searchQuery) ||
                city.province.contains(_searchQuery))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '选择城市',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 搜索框
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索城市',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: _filterCities,
            ),
          ),

          // 城市列表
          Expanded(
            child: _filteredCities.isEmpty
                ? Center(
                    child: Text(
                      '未找到匹配的城市',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14.sp,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      final isSelected = widget.selectedCity?.code == city.code;

                      return ListTile(
                        leading: Icon(
                          Icons.location_city,
                          color: isSelected ? Colors.orange : Colors.grey,
                        ),
                        title: Text(
                          city.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.orange : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          city.province,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.sp,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Colors.orange,
                                size: 20.w,
                              )
                            : null,
                        onTap: () {
                          widget.onCitySelected(city);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 显示城市选择器的便捷方法
Future<CityData?> showCitySelector(
  BuildContext context, {
  CityData? selectedCity,
}) {
  return showModalBottomSheet<CityData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CitySelector(
      selectedCity: selectedCity,
      onCitySelected: (city) => Navigator.pop(context, city),
    ),
  );
}
