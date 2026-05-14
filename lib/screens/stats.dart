import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/trash_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _timeFilter = 'Past Year';
  String? _selectedArea;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data Filter:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _timeFilter,
                  items: ['Past Week', 'Past Month', 'Past Year'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _timeFilter = val!),
                ),
              ],
            ),
          ),
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: 'City Overview'),
              Tab(icon: Icon(Icons.pie_chart), text: 'Area Details'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildOverviewTab(), _buildAreaDetailsTab()],
            ),
          ),
        ],
      ),
    );
  }

  // Bar Chart
  Widget _buildOverviewTab() {
    final areaStats = context.watch<TrashProvider>().getAreaStats(_timeFilter);
    final areas = areaStats.keys.toList();
    final counts = areaStats.values.toList();

    if (areas.isEmpty) {
      return const Center(child: Text('No reports in this time frame.'));
    }

    double highestCount = counts.reduce((a, b) => a > b ? a : b).toDouble();

    // horizontal scrolling to fix crowded X axis
    double chartWidth = max(
      MediaQuery.of(context).size.width,
      areas.length * 60.0,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: chartWidth,
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: highestCount + 2,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${areas[group.x.toInt()]}\n${rod.toY.toInt()} reports',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= areas.length) return const Text('');
                    String name = areas[value.toInt()];
                    // Truncate name slightly for aesthetics
                    if (name.length > 7) name = '${name.substring(0, 7)}.';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(name, style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) =>
                      Text(value.toInt().toString()),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(areas.length, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: counts[index].toDouble(),
                    color: Colors.blueAccent,
                    width: 25, // Thicker bars since we have scrolling space now
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // Specific area Pie chart
  Widget _buildAreaDetailsTab() {
    final provider = context.watch<TrashProvider>();
    final availableAreas = provider.availableAreas;

    if (availableAreas.isEmpty) {
      return const Center(child: Text('No reports available to analyze.'));
    }

    if (_selectedArea == null || !availableAreas.contains(_selectedArea)) {
      _selectedArea = availableAreas.first;
    }

    final severityStats = provider.getSeverityStatsForArea(
      _selectedArea!,
      _timeFilter,
    );
    final totalReports = severityStats.values.reduce((a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Region:', style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: _selectedArea,
                items: availableAreas.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedArea = val!),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (totalReports == 0)
            const Expanded(
              child: Center(
                child: Text('No reports in this area for the selected time.'),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Total Reports: $totalReports',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: severityStats['Low']!.toDouble(),
                            title: severityStats['Low']! > 0
                                ? '${severityStats['Low']}\nLow'
                                : '',
                            radius: 60,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: severityStats['Medium']!.toDouble(),
                            title: severityStats['Medium']! > 0
                                ? '${severityStats['Medium']}\nMed'
                                : '',
                            radius: 60,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: severityStats['High']!.toDouble(),
                            title: severityStats['High']! > 0
                                ? '${severityStats['High']}\nHigh'
                                : '',
                            radius: 60,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
