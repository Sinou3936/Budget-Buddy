import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AiReportScreen extends StatefulWidget {
  const AiReportScreen({super.key});

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gemini = context.read<GeminiProvider>();
      if (gemini.monthlyReport.isEmpty && !gemini.isReportLoading) {
        gemini.generateReport(context.read<TransactionProvider>());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Consumer2<GeminiProvider, TransactionProvider>(
      builder: (context, gemini, tx, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 150,
                backgroundColor: AppTheme.primaryBlue,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.summarize, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('AI 월말 리포트', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryBlue, Color(0xFF1976D2), AppTheme.primaryTeal],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            '${now.year}년 ${now.month}월 소비 분석',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: gemini.isReportLoading
                      ? _buildLoading()
                      : gemini.monthlyReport.isEmpty
                          ? _buildEmpty(gemini, tx)
                          : _buildReport(gemini, tx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text('AI가 리포트를 작성하고 있습니다...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text('잠시만 기다려주세요', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmpty(GeminiProvider gemini, TransactionProvider tx) {
    return SizedBox(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined, color: AppTheme.textLight, size: 64),
          const SizedBox(height: 16),
          Text(gemini.error ?? '리포트를 생성해주세요', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => gemini.generateReport(tx),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('리포트 생성'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(GeminiProvider gemini, TransactionProvider tx) {
    final lines = gemini.monthlyReport.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...lines.map((line) {
          if (line.startsWith('## ')) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                line.replaceFirst('## ', ''),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
            );
          }
          if (line.trim().isEmpty) return const SizedBox(height: 4);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(line, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.6)),
          );
        }),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => gemini.generateReport(tx),
            icon: const Icon(Icons.refresh),
            label: const Text('리포트 다시 생성'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
