import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/rounded_task_progress_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 圆角任务进度小组件示例
class RoundedTaskProgressWidgetExample extends StatelessWidget {
  const RoundedTaskProgressWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teamAvatars = [
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC2E34rpRUxl41JgmYHEf1632M2dz9F_oHyMn1u_7r-NjLVTdySSTi5s7lu_cTAXGFLmZWp9kT0uLY51magEqProtp768PJrVo02zkPIXWrKsREg4NL-dmmUKOOD4hAfCgMokZmCopqoQt7RKjm7xlbEOYurKcdD3t4hq3PJgacmPs_iH-6oqGeI9TrmiH_yEgv1-T6l-RtbFcZUtoLrHgBuT0h2DvbL4WGT_fYukt5o_Q45rAE60lAnw44mCEIgdY2zbLktTzm4w',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCNJkHVLv3wQgstyElOSle3RMoSWr-1-UxEnZqmIBu6HVJBFhfwEVxfjSb2EF0y5TOd4smsVGfSs9IMuxBYcWba5SH3ut3dmhIZt4PTJ9lPt9zvKN-1WqcNhn_qh01gVD5mexs_LSv-VKtPHL-uWTAtIZgo6SIZb8VEAqcU4CO0Fjt6T6GoH3RCcJtUC3ydsN6XvV3NEuQ6XoUfBGVz3OIk6fS0gI1PKNBf7GMCpxk18IGtag0TydvjITBc3Hzl_V11JYxf1ZK3eQ',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDlpM5lz1d7uhYRxL_1Zq-0vrok0JRfmuwmk8k1AH5S0j3On58wmS5sl6qAEY38keWvk6Y3lV5spuIId3ctczvjAHLSffWkMokpQVJtnfFReI0-GAnsAFWuVXBuFWhQnAS843wwP2ejdTd63AdnT8U9WA7bgEXVdzwx2vMLkFoXFc_8srCGXrFi-YMung8i3c_kmxbJHOR55SQTZWvQZmM08P0GHpEcfeC8xe236NTw6HV5HFYaMqT_kN-v5mdmHplJIiv-KL0uNQ',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('圆角任务进度小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸 (SmallSize 1x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: RoundedTaskProgressWidget(
                      title: 'Widgefy',
                      subtitle: 'Design',
                      completedTasks: 7,
                      totalTasks: 14,
                      pendingTasks: const [
                        'Design search page for website',
                        'Send an estimate budget for app',
                        'Export assets for HTML developer',
                      ],
                      commentCount: 4,
                      attachmentCount: 1,
                      teamAvatars: teamAvatars,
                      size: const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸 (MediumSize 2x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: RoundedTaskProgressWidget(
                      title: 'Widgefy UI kit',
                      subtitle: 'Graphics design',
                      completedTasks: 7,
                      totalTasks: 14,
                      pendingTasks: const [
                        'Design search page for website',
                        'Send an estimate budget for app',
                        'Export assets for HTML developer',
                      ],
                      commentCount: 4,
                      attachmentCount: 1,
                      teamAvatars: teamAvatars,
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸 (LargeSize 2x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: RoundedTaskProgressWidget(
                      title: 'Widgefy UI kit',
                      subtitle: 'Graphics design',
                      completedTasks: 7,
                      totalTasks: 14,
                      pendingTasks: const [
                        'Design search page for website',
                        'Send an estimate budget for app',
                        'Export assets for HTML developer',
                      ],
                      commentCount: 4,
                      attachmentCount: 1,
                      teamAvatars: teamAvatars,
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (WideSize 4x1)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: RoundedTaskProgressWidget(
                    title: 'Widgefy UI kit',
                    subtitle: 'Graphics design',
                    completedTasks: 7,
                    totalTasks: 14,
                    pendingTasks: const [
                      'Design search page for website',
                      'Send an estimate budget for app',
                      'Export assets for HTML developer',
                    ],
                    commentCount: 4,
                    attachmentCount: 1,
                    teamAvatars: teamAvatars,
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (Wide2Size 4x2)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: RoundedTaskProgressWidget(
                    title: 'Widgefy UI kit',
                    subtitle: 'Graphics design',
                    completedTasks: 7,
                    totalTasks: 14,
                    pendingTasks: const [
                      'Design search page for website',
                      'Send an estimate budget for app',
                      'Export assets for HTML developer',
                    ],
                    commentCount: 4,
                    attachmentCount: 1,
                    teamAvatars: teamAvatars,
                    size: const Wide2Size(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
