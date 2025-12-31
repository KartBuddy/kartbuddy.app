// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// class WebViewScreen extends StatefulWidget {
//   final String url;
//   final String title;
//
//   const WebViewScreen({
//     super.key,
//     required this.url,
//     required this.title,
//   });
//
//   @override
//   State<WebViewScreen> createState() => _WebViewScreenState();
// }
//
// class _WebViewScreenState extends State<WebViewScreen> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//   bool _hasError = false;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeWebView();
//   }
//
//   void _initializeWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(Colors.white)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             print('🔵 WebView page started loading: $url');
//             setState(() {
//               _isLoading = true;
//               _hasError = false;
//               _errorMessage = null;
//             });
//             // Set a timeout for loading
//             Future.delayed(const Duration(seconds: 30), () {
//               if (mounted && _isLoading) {
//                 setState(() {
//                   _isLoading = false;
//                   _hasError = true;
//                   _errorMessage = 'Page is taking too long to load. Please check your internet connection and try again.';
//                 });
//               }
//             });
//           },
//           onPageFinished: (String url) {
//             print('✅ WebView page finished loading: $url');
//             if (mounted) {
//               setState(() {
//                 _isLoading = false;
//               });
//             }
//           },
//           onWebResourceError: (WebResourceError error) {
//             print('❌ WebView error: ${error.description}');
//             print('❌ Error code: ${error.errorCode}');
//             print('❌ Error type: ${error.errorType}');
//             if (mounted) {
//               setState(() {
//                 _isLoading = false;
//                 _hasError = true;
//                 _errorMessage = error.description.isNotEmpty
//                     ? error.description
//                     : 'Failed to load page. Please check your internet connection.';
//               });
//             }
//           },
//           onHttpError: (HttpResponseError error) {
//             print('❌ WebView HTTP error: ${error.response?.statusCode}');
//             if (mounted) {
//               setState(() {
//                 _isLoading = false;
//                 _hasError = true;
//                 _errorMessage = 'HTTP Error ${error.response?.statusCode}. Please try again.';
//               });
//             }
//           },
//         ),
//       );
//
//     print('🔵 Loading URL: ${widget.url}');
//     try {
//       _controller.loadRequest(Uri.parse(widget.url));
//     } catch (e) {
//       print('❌ Error loading URL: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _hasError = true;
//           _errorMessage = 'Invalid URL. Please contact support.';
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(
//           widget.title,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colors.black87,
//           ),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//             height: 1,
//             color: Colors.grey[200],
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           if (!_hasError)
//             WebViewWidget(controller: _controller)
//           else
//             Container(
//               color: Colors.white,
//               padding: const EdgeInsets.all(24),
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.error_outline,
//                       size: 64,
//                       color: Colors.red[300],
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Failed to Load Page',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       _errorMessage ?? 'Unable to load the page. Please check your internet connection.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _hasError = false;
//                           _isLoading = true;
//                         });
//                         _controller.reload();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1E3A8A),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       ),
//                       child: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           if (_isLoading && !_hasError)
//             Container(
//               color: Colors.white,
//               child: const Center(
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
