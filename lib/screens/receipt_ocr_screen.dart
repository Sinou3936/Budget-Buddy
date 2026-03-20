import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ocr_result.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_env.dart';

class ReceiptOcrScreen extends StatefulWidget {
  const ReceiptOcrScreen({super.key});

  @override
  State<ReceiptOcrScreen> createState() => _ReceiptOcrScreenState();
}

class _ReceiptOcrScreenState extends State<ReceiptOcrScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  OcrResult? _result;
  bool _isAnalyzing = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
        _error = null;
      });
      await _analyze(bytes);
    } catch (_) {
      setState(() => _error = '이미지를 불러오지 못했습니다.');
    }
  }

  Future<void> _analyze(Uint8List bytes) async {
    setState(() { _isAnalyzing = true; _error = null; });
    final result = await GeminiService.instance.parseReceiptImage(bytes);
    setState(() {
      _isAnalyzing = false;
      if (result == null || result.title.isEmpty) {
        _error = '영수증을 인식하지 못했습니다. 다시 시도해주세요.';
      } else {
        _result = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('영수증 스캔'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: !AppEnv.geminiEnabled
          ? _buildApiKeyNotice()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 이미지 영역
                  GestureDetector(
                    onTap: () => _showSourcePicker(),
                    child: Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _imageBytes != null ? AppTheme.primaryBlue : AppTheme.dividerColor,
                          width: _imageBytes != null ? 2 : 1,
                        ),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, color: AppTheme.textLight, size: 48),
                                SizedBox(height: 12),
                                Text('영수증 사진을 찍거나 선택하세요', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 버튼
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('카메라'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('갤러리'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 분석 중
                  if (_isAnalyzing)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('AI가 영수증을 분석하고 있습니다...', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),

                  // 오류
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.dangerRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13))),
                        ],
                      ),
                    ),

                  // 결과
                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
                              SizedBox(width: 6),
                              Text('인식 완료', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                            ],
                          ),
                          const Divider(height: 20),
                          _resultRow('가게명', _result!.title),
                          const SizedBox(height: 8),
                          _resultRow('금액', '${_result!.amount?.toInt() ?? 0}원'),
                          const SizedBox(height: 8),
                          _resultRow('카테고리', _result!.category),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _result),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('이 정보로 거래 추가', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('카메라'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('갤러리'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyNotice() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_off, color: AppTheme.textLight, size: 64),
            SizedBox(height: 16),
            Text('Gemini API 키 미설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
