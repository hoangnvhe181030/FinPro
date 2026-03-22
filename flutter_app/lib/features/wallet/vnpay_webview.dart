import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_service.dart';
import 'package:provider/provider.dart';

class VNPayWebView extends StatefulWidget {
  final String paymentUrl;
  const VNPayWebView({super.key, required this.paymentUrl});

  @override
  State<VNPayWebView> createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasResult = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Intercept the VNPay return redirect 
            // VNPay redirects to our return-url (localhost:8080/api/vnpay/return?...)
            // On emulator, localhost won't work, so we intercept and handle it
            if (url.contains('/api/vnpay/return')) {
              _handlePaymentReturn(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentReturn(String url) async {
    if (_hasResult) return;
    _hasResult = true;

    final uri = Uri.parse(url);
    final responseCode = uri.queryParameters['vnp_ResponseCode'];
    final isSuccess = responseCode == '00';

    // Also call the backend to process the payment
    if (isSuccess) {
      try {
        // Rewrite URL to use 10.0.2.2 for emulator
        final backendUrl = url.replaceFirst(
          'localhost:8080',
          '10.0.2.2:8080',
        );
        final apiService = context.read<ApiService>();
        await apiService.dio.getUri(Uri.parse(backendUrl));
      } catch (e) {
        debugPrint('VNPay return call error (non-critical): $e');
      }
    }

    if (!mounted) return;

    // Show result dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 64,
              color: isSuccess ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? 'Nạp tiền thành công!' : 'Thanh toán thất bại',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSuccess
                  ? 'Giao dịch đã được xử lý thành công.'
                  : 'Giao dịch không thành công. Vui lòng thử lại.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, isSuccess); // Return to wallet
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: isSuccess ? AppColors.success : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'VNPay',
                style: TextStyle(
                  color: Color(0xFF0088FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Thanh Toán'),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
