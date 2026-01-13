import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/rounded_task_progress_widget.dart';

/// 圆角任务进度小组件示例
class RoundedTaskProgressWidgetExample extends StatelessWidget {
  const RoundedTaskProgressWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆角任务进度小组件')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)] : [const Color(0xFF6366F1), const Color(0xFF9333EA)],
          ),
        ),
        child: const Center(
          child: RoundedTaskProgressWidget(
            title: 'Widgefy UI kit',
            subtitle: 'Graphics design',
            completedTasks: 7,
            totalTasks: 14,
            pendingTasks: [
              'Design search page for website',
              'Send an estimate budget for app',
              'Export assets for HTML developer',
            ],
            commentCount: 4,
            attachmentCount: 1,
            teamAvatars: [
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC2E34rpRUxl41JgmYHEf1632M2dz9F_oHyMn1u_7r-NjLVTdySSTi5s7lu_cTAXGFLmZWp9kT0uLY51magEqProtp768PJrVo02zkPIXWrKsREg4NL-dmmUKOOD4hAfCgMokZmCopqoQt7RKjm7xlbEOYurKcdD3t4hq3PJgacmPs_iH-6oqGeI9TrmiH_yEgv1-T6l-RtbFcZUtoLrHgBuT0h2DvbL4WGT_fYukt5o_Q45rAE60lAnw44mCEIgdY2zbLktTzm4w',
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCNJkHVLv3wQgstyElOSle3RMoSWr-1-UxEnZqmIBu6HVJBFhfwEVxfjSb2EF0y5TOd4smsVGfSs9IMuxBYcWba5SH3ut3dmhIZt4PTJ9lPt9zvKN-1WqcNhn_qh01gVD5mexs_LSv-VKtPHL-uWTAtIZgo6SIZb8VEAqcU4CO0Fjt6T6GoH3RCcJtUC3ydsN6XvV3NEuQ6XoUfBGVz3OIk6fS0gI1PKNBf7GMCpxk18IGtag0TydvjITBc3Hzl_V11JYxf1ZK3eQ',
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDlpM5lz1d7uhYRxL_1Zq-0vrok0JRfmuwmk8k1AH5S0j3On58wmS5sl6qAEY38keWvk6Y3lV5spuIId3ctczvjAHLSffWkMokpQVJtnfFReI0-GAnsAFWuVXBuFWhQnAS843wwP2ejdTd63AdnT8U9WA7bgEXVdzwx2vMLkFoXFc_8srCGXrFi-YMung8i3c_kmxbJHOR55SQTZWvQZmM08P0GHpEcfeC8xe236NTw6HV5HFYaMqT_kN-v5mdmHplJIiv-KL0uNQ',
            ],
          ),
        ),
      ),
    );
  }
}
