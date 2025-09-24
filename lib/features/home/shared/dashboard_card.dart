// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// import '../../../core/constants/app_colors.dart';
//
// class _DashboardCard extends StatelessWidget {
//
//   final _ModuleItem module;
//
//   const _DashboardCard({required this.module});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         // TODO: Navigate to respective module
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18.r),
//           gradient: LinearGradient(
//             colors: [module.color.withOpacity(0.9), module.color.withOpacity(0.6)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: module.color.withOpacity(0.3),
//               blurRadius: 10,
//               offset: Offset(4, 6),
//             )
//           ],
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(16.sp),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(module.icon, size: 40.sp, color: AppColors.cxWhite),
//               SizedBox(height: 12.sp),
//               Text(
//                 module.title,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: AppColors.cxWhite,
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
