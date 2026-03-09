import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../widgets/glass_card.dart';


import '../providers/finance_provider.dart';
import '../core/ai_engine.dart';
import '../widgets/glass_card.dart';

class PremiumAnalyticsScreen extends ConsumerStatefulWidget {
  const PremiumAnalyticsScreen({super.key});

  @override
  ConsumerState<PremiumAnalyticsScreen> createState() =>
      _PremiumAnalyticsScreenState();
}

class _PremiumAnalyticsScreenState
    extends ConsumerState<PremiumAnalyticsScreen>
    with TickerProviderStateMixin {

  late AnimationController _donutController;
  late Animation<double> _donutAnimation;

  @override
  void initState() {
    super.initState();

    _donutController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _donutAnimation =
        CurvedAnimation(parent: _donutController, curve: Curves.easeOut);

    _donutController.forward();
  }

  @override
  Widget build(BuildContext context) {

    final transactions = ref.watch(transactionProvider);

    final categoryData =
        AIEngine.categoryBreakdown(transactions);

    final monthlyData =
        AIEngine.monthlyComparison(transactions);

    final totalSpent =
        categoryData.values.fold(0.0, (a, b) => a + b);

    final current = monthlyData["current"] ?? 0;
    final previous = monthlyData["previous"] ?? 0;

    final growthPercent =
        previous == 0 ? 0 : ((current - previous) / previous) * 100;

    final aiConfidence =
        min(100, (totalSpent / 50000) * 100);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B0F2F),
              Color(0xFF1B1F4A),
              Color(0xFF0B0F2F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [

                const Text(
                  "ULTRA Analytics",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // ==============================
                // 🔥 ANIMATED DONUT
                // ==============================
                GlassCard(
                  height: 350,
                  child: AnimatedBuilder(
                    animation: _donutAnimation,
                    builder: (context, _) {

                      return Stack(
                        alignment: Alignment.center,
                        children: [

                          PieChart(
                            PieChartData(
                              centerSpaceRadius: 100,
                              sectionsSpace: 4,
                              sections: categoryData.entries.map((e) {
                                return PieChartSectionData(
                                  value: e.value *
                                      _donutAnimation.value,
                                  radius: 100,
                                  title: "",
                                  color: _colorForCategory(e.key),
                                );
                              }).toList(),
                            ),
                          ),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              const Text(
                                "Total Spent",
                                style: TextStyle(
                                    color: Colors.white70),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "₹ ${totalSpent.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // ==============================
                // 📈 MONTHLY GROWTH
                // ==============================
                GlassCard(
                  height: 160,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Monthly Growth",
                        style: TextStyle(
                            color: Colors.white70),
                      ),

                      const Spacer(),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [

                          Text(
                            "₹ ${current.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight:
                                    FontWeight.bold),
                          ),

                          Text(
                            "${growthPercent.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                              color: growthPercent >= 0
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ==============================
                // 🔮 SAVINGS FORECAST GRAPH
                // ==============================
                GlassCard(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      borderData:
                          FlBorderData(show: false),
                      titlesData:
                          FlTitlesData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 4,
                          spots: List.generate(
                            6,
                            (index) => FlSpot(
                              index.toDouble(),
                              (totalSpent /
                                      (index + 2))
                                  .toDouble(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==============================
                // 🤖 AI CONFIDENCE METER
                // ==============================
                GlassCard(
                  height: 140,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "AI Confidence Score",
                        style: TextStyle(
                            color: Colors.white70),
                      ),

                      const SizedBox(height: 20),

                      LinearProgressIndicator(
                        value: aiConfidence / 100,
                        minHeight: 10,
                        backgroundColor:
                            Colors.white10,
                        color: Colors.cyanAccent,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "${aiConfidence.toStringAsFixed(0)}%",
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case "Food":
        return Colors.orangeAccent;
      case "Shopping":
        return Colors.purpleAccent;
      case "Bills":
        return Colors.blueAccent;
      default:
        return Colors.tealAccent;
    }
  }

  @override
  void dispose() {
    _donutController.dispose();
    super.dispose();
  }
}
