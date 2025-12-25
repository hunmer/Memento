import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/statistics/models/statistics_models.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'date_range_selector.dart';
import 'chart_components.dart';

/// 通用的统计屏幕组件
class StatisticsScreen extends StatefulWidget {
  final StatisticsConfig config;
  final Future<StatisticsData> Function(
    DateRangeOption range,
    DateTime? startDate,
    DateTime? endDate,
  )
  dataLoader;
  final List<Widget> Function(BuildContext context, StatisticsData data)?
  customSections;
  final Function(DateRangeState)? onDateRangeChanged;
  final Function(RankingData)? onRankingItemTap;

  const StatisticsScreen({
    super.key,
    required this.config,
    required this.dataLoader,
    this.customSections,
    this.onDateRangeChanged,
    this.onRankingItemTap,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateRangeState _state = const DateRangeState(
    selectedRange: DateRangeOption.thisWeek,
  );
  StatisticsData? _data;
  bool _isLoading = false;
  bool _isFirstLoad = true; // 追踪是否首次加载

  @override
  void initState() {
    super.initState();
    _state = _state.copyWith(selectedRange: widget.config.defaultRange);
    _loadData();
  }

  Future<void> _loadData() async {
    // 更新 loading 状态,但不清空现有数据
    setState(() {
      _isLoading = true;
      _state = _state.copyWith(isLoading: true);
    });

    try {
      final now = DateTime.now();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final today = DateTime(now.year, now.month, now.day);

      DateTime startDate;
      DateTime endDate;

      switch (_state.selectedRange) {
        case DateRangeOption.today:
          startDate = today;
          endDate = todayEnd;
          break;
        case DateRangeOption.thisWeek:
          startDate = today.subtract(Duration(days: now.weekday - 1));
          endDate = todayEnd;
          break;
        case DateRangeOption.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          endDate = todayEnd;
          break;
        case DateRangeOption.thisYear:
          startDate = DateTime(now.year, 1, 1);
          endDate = todayEnd;
          break;
        case DateRangeOption.custom:
          startDate = _state.startDate ?? today;
          endDate = _state.endDate ?? todayEnd;
          break;
      }

      final data = await widget.dataLoader(
        _state.selectedRange,
        startDate,
        endDate,
      );

      // 如果是首次加载，先设置数值为 0，然后在下一帧更新为实际值以触发动画
      if (_isFirstLoad && mounted) {
        setState(() {
          _isLoading = false;
          _data = StatisticsData(
            title: widget.config.title,
            subtitle: widget.config.subtitle,
            startDate: startDate,
            endDate: endDate,
            totalValue: 0, // 首次加载先设为 0
            totalValueLabel: data.totalValueLabel,
            distributionData:
                data.distributionData
                    ?.map(
                      (item) => DistributionData(
                        label: item.label,
                        value: 0,
                        color: item.color,
                      ),
                    )
                    .toList(),
            rankingData:
                data.rankingData
                    ?.map(
                      (item) => RankingData(
                        label: item.label,
                        value: 0,
                        icon: item.icon,
                        color: item.color,
                        extraData: item.extraData,
                      ),
                    )
                    .toList(),
            timeSeriesData: data.timeSeriesData,
            hourlyDistribution: data.hourlyDistribution,
            hourlyMainTags: data.hourlyMainTags,
            extraData: data.extraData,
          );
          _state = _state.copyWith(
            startDate: startDate,
            endDate: endDate,
            isLoading: false,
          );
        });

        // 在下一帧更新为实际值，触发动画
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _data = StatisticsData(
                title: widget.config.title,
                subtitle: widget.config.subtitle,
                startDate: startDate,
                endDate: endDate,
                totalValue: data.totalValue,
                totalValueLabel: data.totalValueLabel,
                distributionData: data.distributionData,
                rankingData: data.rankingData,
                timeSeriesData: data.timeSeriesData,
                hourlyDistribution: data.hourlyDistribution,
                hourlyMainTags: data.hourlyMainTags,
                extraData: data.extraData,
              );
              _isFirstLoad = false;
            });
          }
        });
      } else {
        // 非首次加载:直接更新数据,AnimatedFlipCounter 会自动处理动画
        if (mounted) {
          setState(() {
            _isLoading = false;
            _data = StatisticsData(
              title: widget.config.title,
              subtitle: widget.config.subtitle,
              startDate: startDate,
              endDate: endDate,
              totalValue: data.totalValue,
              totalValueLabel: data.totalValueLabel,
              distributionData: data.distributionData,
              rankingData: data.rankingData,
              timeSeriesData: data.timeSeriesData,
              hourlyDistribution: data.hourlyDistribution,
              hourlyMainTags: data.hourlyMainTags,
              extraData: data.extraData,
            );
            _state = _state.copyWith(
              startDate: startDate,
              endDate: endDate,
              isLoading: false,
            );
          });
        }
      }

      widget.onDateRangeChanged?.call(_state);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _state = _state.copyWith(isLoading: false);
        });
        Toast.error('Failed to load data: $e');
      }
    }
  }

  Future<void> _handleRangeChanged(DateRangeOption range) async {
    setState(() {
      _state = _state.copyWith(selectedRange: range, isLoading: true);
    });

    await _loadData();
  }

  Future<void> _handleCustomRangeChanged(
    DateTime startDate,
    DateTime endDate,
  ) async {
    setState(() {
      _state = _state.copyWith(
        selectedRange: DateRangeOption.custom,
        startDate: startDate,
        endDate: endDate,
        isLoading: true,
      );
    });

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text(widget.config.title),
      largeTitle: widget.config.title,

      body: Column(
        children: [
          if (widget.config.showDateRange) ...[
            DateRangeSelector(
              state: _state,
              availableRanges: widget.config.availableRanges,
              onRangeChanged: _handleRangeChanged,
              onCustomRangeChanged: _handleCustomRangeChanged,
              onRefresh: _isLoading ? null : _loadData,
              showRefreshButton: true,
              loadingWidget: widget.config.loadingWidget,
            ),
            DateRangeDisplay(
              startDate: _state.startDate,
              endDate: _state.endDate,
            ),
          ],
          // 移除全屏 loading 状态,保持内容区域始终显示以避免闪烁和动画失效
          if (_data == null)
            widget.config.emptyWidget ??
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('widget_noData'.tr)),
                )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 总价值显示（如果有）
                    if (_data!.totalValue != null)
                      buildStatisticsCard(
                        context: context,
                        title: _data!.title,
                        subtitle: _data!.subtitle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                AnimatedFlipCounter(
                                  value: _data!.totalValue!,
                                  duration: const Duration(milliseconds: 500),
                                  textStyle: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_data!.totalValueLabel != null)
                                  Text(
                                    _data!.totalValueLabel!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_data!.totalValue != null) const SizedBox(height: 16),

                    // 时间序列趋势图
                    if (_data!.timeSeriesData != null &&
                        _data!.timeSeriesData!.isNotEmpty)
                      buildStatisticsCard(
                        context: context,
                        title: 'widget_statisticsTrends'.tr,
                        child: TimeSeriesChart(
                          series: _data!.timeSeriesData!,
                          colorPalette: widget.config.chartColors,
                        ),
                      ),
                    if (_data!.timeSeriesData != null &&
                        _data!.timeSeriesData!.isNotEmpty)
                      const SizedBox(height: 16),

                    // 分布饼图
                    if (_data!.distributionData != null &&
                        _data!.distributionData!.isNotEmpty)
                      buildStatisticsCard(
                        context: context,
                        title: 'widget_statisticsDistribution'.tr,
                        child: DistributionPieChart(
                          data: _data!.distributionData!,
                          colorPalette: widget.config.chartColors,
                          centerValue: _data!.totalValue,
                          centerSubtext: _data!.totalValueLabel,
                        ),
                      ),
                    if (_data!.distributionData != null &&
                        _data!.distributionData!.isNotEmpty)
                      const SizedBox(height: 16),

                    // 24小时分布（仅单日有效）
                    if (widget.config.show24hDistribution &&
                        _data!.isSingleDay &&
                        _data!.hourlyDistribution != null &&
                        _data!.hourlyDistribution!.isNotEmpty)
                      buildStatisticsCard(
                        context: context,
                        title: 'widget_statisticsHourlyDistribution'.tr,
                        child: HourlyDistributionBar(
                          hourlyData: _data!.hourlyDistribution!,
                          colorPalette: widget.config.chartColors,
                          hourlyMainTags: _data!.hourlyMainTags,
                        ),
                      ),
                    if (widget.config.show24hDistribution &&
                        _data!.isSingleDay &&
                        _data!.hourlyDistribution != null &&
                        _data!.hourlyDistribution!.isNotEmpty)
                      const SizedBox(height: 16),

                    // 排行榜
                    if (_data!.rankingData != null &&
                        _data!.rankingData!.isNotEmpty)
                      buildStatisticsCard(
                        context: context,
                        title: 'widget_statisticsRanking'.tr,
                        child: RankingList(
                          data: _data!.rankingData!,
                          colorPalette: widget.config.chartColors,
                          onItemTap: widget.onRankingItemTap,
                          valueLabel: _data!.totalValueLabel,
                        ),
                      ),
                    if (_data!.rankingData != null &&
                        _data!.rankingData!.isNotEmpty)
                      const SizedBox(height: 16),

                    // 自定义部分
                    if (widget.customSections != null)
                      ...widget.customSections!(context, _data!),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
