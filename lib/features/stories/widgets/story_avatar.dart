import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/model/story_model.dart';
import '../pages/story_viewer.dart';

class StoryAvatar extends StatelessWidget {
  final UserStories userStories;
  final double size;

  const StoryAvatar({
    super.key,
    required this.userStories,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnviewed = userStories.hasUnviewedStories;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoryViewer(
              userStories: userStories,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size.w,
            height: size.h,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnviewed
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFF58529),
                        Color(0xFFDD2A7B),
                        Color(0xFF8134AF),
                        Color(0xFF515BD4),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : null,
              border: !hasUnviewed
                  ? Border.all(
                      color: Colors.grey.shade400,
                      width: 2.w,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 3.w,
                ),
              ),
              child: CircleAvatar(
                radius: (size - 12).r,
                backgroundImage: userStories.userPhoto != null
                    ? NetworkImage(userStories.userPhoto!)
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: userStories.userPhoto == null
                    ? Icon(
                        Icons.person,
                        size: (size - 20).sp,
                        color: Colors.grey.shade600,
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          SizedBox(
            width: size.w,
            child: Text(
              userStories.userName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
