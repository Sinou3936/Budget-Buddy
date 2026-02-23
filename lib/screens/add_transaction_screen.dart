import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  String _selectedCategory = '식비';
  String _selectedType = 'expense';
  DateTime _selectedDate = DateTime.now();
  String _aiCategory = '';
  bool _isAnalyzing = false;

  final List<String> _expenseCategories = [
    '식비', '교통', '쇼핑', '문화/여가', '의료', '통신', '주거', '교육', '기타'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedType = _tabController.index == 0 ? 'expense' : 'income';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onTitleChanged(String value) {
    if (value.length >= 2) {
      setState(() => _isAnalyzing = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _titleController.text == value) {
          final category = AiService.classifyTransaction(value);
          setState(() {
            _aiCategory = category;
            _selectedCategory = category;
            _isAnalyzing = false;
          });
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 금액을 입력해주세요')),
      );
      return;
    }

    final amount = double.tryParse(
        _amountController.text.replaceAll(',', '').replaceAll('원', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해주세요')),
      );
      return;
    }

    final provider = context.read<TransactionProvider>();
    final transaction = Transaction(
      id: provider.generateNewId(),
      title: _titleController.text,
      amount: amount,
      category: _selectedCategory,
      type: _selectedType,
      date: _selectedDate,
      memo: _memoController.text.isNotEmpty ? _memoController.text : null,
    );

    await provider.addTransaction(transaction);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('${_selectedType == 'expense' ? '지출' : '수입'} 내역이 추가되었습니다'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('거래 추가'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '지출'),
            Tab(text: '수입'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 입력
            _buildSectionLabel('내용', Icons.edit),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              onChanged: _onTitleChanged,
              decoration: InputDecoration(
                hintText: '예: 스타벅스 아메리카노, 지하철 교통카드...',
                prefixIcon:
                    const Icon(Icons.receipt, color: AppTheme.primaryBlue),
                suffixIcon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _aiCategory.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    size: 12, color: AppTheme.primaryBlue),
                                const SizedBox(width: 4),
                                Text(
                                  'AI: $_aiCategory',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : null,
              ),
            ),

            const SizedBox(height: 20),

            // 금액 입력
            _buildSectionLabel('금액', Icons.attach_money),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: '₩ ',
                prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue),
              ),
            ),

            const SizedBox(height: 20),

            // 카테고리 선택
            _buildSectionLabel('카테고리', Icons.category),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _expenseCategories.map((category) {
                final isSelected = _selectedCategory == category;
                final color =
                    AppTheme.categoryColors[category] ?? Colors.grey;
                final icon = AppTheme.categoryIcons[category] ?? Icons.circle;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : AppTheme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 16,
                            color:
                                isSelected ? color : AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? color
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 날짜 선택
            _buildSectionLabel('날짜', Icons.calendar_today),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                      style: const TextStyle(
                          fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textLight),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 메모
            _buildSectionLabel('메모 (선택)', Icons.note),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: '추가 메모를 입력하세요...',
                prefixIcon: Icon(Icons.note_alt, color: AppTheme.primaryBlue),
              ),
            ),

            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedType == 'expense' ? '지출' : '수입'} 저장',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
