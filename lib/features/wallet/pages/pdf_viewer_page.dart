import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.pdfPath,
    required this.title,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('📄 PDF Viewer: Loading ${widget.pdfPath}');
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (_totalPages > 0)
              Text(
                '${l10n.translate('page')} $_currentPage ${l10n.translate('of')} $_totalPages',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          // Zoom out button
          IconButton(
            icon: Icon(Icons.zoom_out, color: theme.colorScheme.onSurface),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
            },
          ),
          // Zoom in button
          IconButton(
            icon: Icon(Icons.zoom_in, color: theme.colorScheme.onSurface),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Viewer
          Container(
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A24) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: SfPdfViewer.asset(
                widget.pdfPath,
                controller: _pdfViewerController,
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  print('✅ PDF Loaded: ${details.document.pages.count} pages');
                  setState(() {
                    _totalPages = details.document.pages.count;
                    _isLoading = false;
                    _errorMessage = null;
                  });
                },
                onPageChanged: (PdfPageChangedDetails details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
                onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                  print('❌ PDF Load Failed: ${details.error}');
                  print('❌ Description: ${details.description}');
                  setState(() {
                    _isLoading = false;
                    _errorMessage = details.description;
                  });
                },
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              margin: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A24) : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      l10n.translate('loadingDocument'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error display
          if (_errorMessage != null)
            Container(
              margin: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A24) : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.sp,
                        color: AppColors.cxCrimsonRed,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Failed to load PDF',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back),
                        label: Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // Navigation controls
      bottomNavigationBar: _totalPages > 0
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A24) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous page button
                    _buildNavButton(
                      icon: Icons.arrow_back_ios_new,
                      label: l10n.translate('previous'),
                      onPressed: _currentPage > 1
                          ? () {
                              _pdfViewerController.previousPage();
                            }
                          : null,
                      isDark: isDark,
                    ),

                    // Page indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                              : [AppColors.cxRoyalBlue, AppColors.cxRoyalBlue.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Next page button
                    _buildNavButton(
                      icon: Icons.arrow_forward_ios,
                      label: l10n.translate('next'),
                      onPressed: _currentPage < _totalPages
                          ? () {
                              _pdfViewerController.nextPage();
                            }
                          : null,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    final isEnabled = onPressed != null;
    final color = isEnabled
        ? (isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue)
        : (isDark ? const Color(0xFF4B5563) : AppColors.cxSilverTint);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == Icons.arrow_back_ios_new) ...[
              Icon(icon, size: 16.sp, color: color),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (icon == Icons.arrow_forward_ios) ...[
              SizedBox(width: 6.w),
              Icon(icon, size: 16.sp, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
