import '../model/work_entry_model.dart';

/// Utility class for calculating work time statistics
class WorkTimeCalculator {
  // Constants
  static const int msInHour = 1000 * 60 * 60;
  static const int msInMinute = 1000 * 60;
  static const int msInSecond = 1000;

  /// Calculate total hours from work entries
  /// Returns formatted string like "168:30:45"
  static String calculateTotalHours(List<WorkEntry> workEntries) {
    int totalTime = 0;
    
    if (workEntries.isNotEmpty) {
      for (var entry in workEntries) {
        if (entry.checkInTime != null && entry.checkOutTime != null && entry.checkOutTime!.isNotEmpty) {
          final checkIn = DateTime.parse(entry.checkInTime!);
          final checkOut = DateTime.parse(entry.checkOutTime!);
          final diff = checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
          totalTime += diff;
        }
      }
    }
    
    final workedHours = (totalTime / msInHour).floor();
    final workedMinutes = ((totalTime - workedHours * msInHour) / msInMinute).floor();
    final workedSeconds = ((totalTime - workedHours * msInHour - workedMinutes * msInMinute) / msInSecond).floor();
    
    return '$workedHours:${workedMinutes.toString().padLeft(2, '0')}:${workedSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Get total hours as a double value
  static double getTotalHoursAsDouble(List<WorkEntry> workEntries) {
    int totalTime = 0;
    
    if (workEntries.isNotEmpty) {
      for (var entry in workEntries) {
        if (entry.checkInTime != null && entry.checkOutTime != null && entry.checkOutTime!.isNotEmpty) {
          final checkIn = DateTime.parse(entry.checkInTime!);
          final checkOut = DateTime.parse(entry.checkOutTime!);
          final diff = checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
          totalTime += diff;
        }
      }
    }
    
    return totalTime / msInHour;
  }
  
  /// Check if overtime (more than 234 hours)
  static bool isOvertime(List<WorkEntry> workEntries) {
    int totalTime = 0;
    
    for (var entry in workEntries) {
      if (entry.checkInTime != null && entry.checkOutTime != null && entry.checkOutTime!.isNotEmpty) {
        final checkIn = DateTime.parse(entry.checkInTime!);
        final checkOut = DateTime.parse(entry.checkOutTime!);
        final diff = checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
        totalTime += diff;
      }
    }
    
    final workedHours = (totalTime / msInHour).floor();
    return workedHours > 234;
  }
  
  /// Calculate day shift hours (6:00 - 23:00)
  /// Returns formatted string like "142:15:30"
  static String calculateDayHours(List<WorkEntry> workEntries) {
    int totalTime = 0;
    
    for (var entry in workEntries) {
      if (entry.checkInTime != null && entry.checkOutTime != null && entry.checkOutTime!.isNotEmpty) {
        final checkIn = DateTime.parse(entry.checkInTime!);
        final checkOut = DateTime.parse(entry.checkOutTime!);
        
        // Scenario 1: Both check-in and check-out are during day hours (6:00 - 23:00)
        if (checkIn.hour >= 6 && checkIn.hour < 23 && 
            checkOut.hour >= 6 && checkOut.hour < 23 &&
            checkOut.isAfter(checkIn) && checkOut.difference(checkIn).inHours < 24) {
          // Full shift is during day hours
          final diff = checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
          totalTime += diff;
        } 
        // Scenario 2: Check-in during day, check-out at night (23:00-06:00)
        else if (checkIn.hour >= 6 && checkIn.hour < 23) {
          // Check if checkout is after 23:00 same day OR early morning next day (00:00-06:00)
          final isCheckoutNight = checkOut.hour >= 23 || checkOut.hour < 6;
          
          if (isCheckoutNight) {
            // Calculate day hours from check-in until 23:00
            final endOfDayShift = DateTime(
              checkIn.year,
              checkIn.month,
              checkIn.day,
              23, 0, 0
            );
            
            // Only count if check-in is before 23:00
            if (checkIn.isBefore(endOfDayShift)) {
              final diff = endOfDayShift.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
              totalTime += diff;
            }
          }
        }
      }
    }
    
    final workedHours = (totalTime / msInHour).floor();
    final workedMinutes = ((totalTime - workedHours * msInHour) / msInMinute).floor();
    final workedSeconds = ((totalTime - workedHours * msInHour - workedMinutes * msInMinute) / msInSecond).floor();
    
    return '$workedHours:${workedMinutes.toString().padLeft(2, '0')}:${workedSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Get day hours as a double value
  static double getDayHoursAsDouble(List<WorkEntry> workEntries) {
    int totalTime = 0;
    
    for (var entry in workEntries) {
      if (entry.checkInTime != null && entry.checkOutTime != null && entry.checkOutTime!.isNotEmpty) {
        final checkIn = DateTime.parse(entry.checkInTime!);
        final checkOut = DateTime.parse(entry.checkOutTime!);
        
        // Scenario 1: Both check-in and check-out are during day hours (6:00 - 23:00)
        if (checkIn.hour >= 6 && checkIn.hour < 23 && 
            checkOut.hour >= 6 && checkOut.hour < 23 &&
            checkOut.isAfter(checkIn) && checkOut.difference(checkIn).inHours < 24) {
          // Full shift is during day hours
          final diff = checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
          totalTime += diff;
        } 
        // Scenario 2: Check-in during day, check-out at night (23:00-06:00)
        else if (checkIn.hour >= 6 && checkIn.hour < 23) {
          // Check if checkout is after 23:00 same day OR early morning next day (00:00-06:00)
          final isCheckoutNight = checkOut.hour >= 23 || checkOut.hour < 6;
          
          if (isCheckoutNight) {
            // Calculate day hours from check-in until 23:00
            final endOfDayShift = DateTime(
              checkIn.year,
              checkIn.month,
              checkIn.day,
              23, 0, 0
            );
            
            // Only count if check-in is before 23:00
            if (checkIn.isBefore(endOfDayShift)) {
              final diff = endOfDayShift.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
              totalTime += diff;
            }
          }
        }
      }
    }
    
    return totalTime / msInHour;
  }
  
  /// Calculate night shift hours (23:00 - 6:00)
  /// Returns formatted string like "26:30:15"
  static String calculateNightHours(List<WorkEntry> workEntries) {
    int totalTime = 0;
    
    for (var entry in workEntries) {
      if (entry.checkInTime != null && entry.checkOutTime != null && entry.checkOutTime!.isNotEmpty) {
        final checkIn = DateTime.parse(entry.checkInTime!);
        final checkOut = DateTime.parse(entry.checkOutTime!);
        
        // Check if work was during night hours (23:00 - 6:00)
        if (checkIn.hour >= 23 || checkIn.hour < 6) {
          // Shift starts at night
          if (checkOut.hour < 6) {
            // Ends during night too
            final diff = checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
            totalTime += diff;
          } else if (checkOut.hour >= 6) {
            // Ends during day - calculate until 6:00 AM
            final d1 = checkIn;
            final d2 = DateTime(
              checkOut.year,
              checkOut.month,
              checkOut.day,
              6, 0, 0
            );
            
            final diff = d2.millisecondsSinceEpoch - d1.millisecondsSinceEpoch;
            totalTime += diff;
          }
        } else if (checkIn.hour < 23 && 
                  (checkOut.hour >= 23 || checkOut.hour < 6)) {
          // Shift starts during day but ends at night
          final d1 = DateTime(
            checkIn.year,
            checkIn.month,
            checkIn.day,
            23, 0, 0
          );
          
          DateTime d2;
          if (checkOut.hour >= 23) {
            // Check out is on the same day after 23:00
            d2 = checkOut;
          } else {
            // Check out is next day before 6:00
            d2 = checkOut;
          }
          
          final diff = d2.millisecondsSinceEpoch - d1.millisecondsSinceEpoch;
          totalTime += diff;
        }
      }
    }
    
    final workedHours = (totalTime / msInHour).floor();
    final workedMinutes = ((totalTime - workedHours * msInHour) / msInMinute).floor();
    final workedSeconds = ((totalTime - workedHours * msInHour - workedMinutes * msInMinute) / msInSecond).floor();
    
    return '$workedHours:${workedMinutes.toString().padLeft(2, '0')}:${workedSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Get night hours as a double value
  static double getNightHoursAsDouble(List<WorkEntry> workEntries) {
    int totalTime = 0;
    
    for (var entry in workEntries) {
      if (entry.checkInTime != null && entry.checkOutTime != null && entry.checkOutTime!.isNotEmpty) {
        final checkIn = DateTime.parse(entry.checkInTime!);
        final checkOut = DateTime.parse(entry.checkOutTime!);
        
        // Check if work was during night hours (23:00 - 6:00)
        if (checkIn.hour >= 23 || checkIn.hour < 6) {
          // Shift starts at night
          if (checkOut.hour < 6) {
            // Ends during night too
            final diff = checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
            totalTime += diff;
          } else if (checkOut.hour >= 6) {
            // Ends during day - calculate until 6:00 AM
            final d1 = checkIn;
            final d2 = DateTime(
              checkOut.year,
              checkOut.month,
              checkOut.day,
              6, 0, 0
            );
            
            final diff = d2.millisecondsSinceEpoch - d1.millisecondsSinceEpoch;
            totalTime += diff;
          }
        } else if (checkIn.hour < 23 && 
                  (checkOut.hour >= 23 || checkOut.hour < 6)) {
          // Shift starts during day but ends at night
          final d1 = DateTime(
            checkIn.year,
            checkIn.month,
            checkIn.day,
            23, 0, 0
          );
          
          DateTime d2;
          if (checkOut.hour >= 23) {
            // Check out is on the same day after 23:00
            d2 = checkOut;
          } else {
            // Check out is next day before 6:00
            d2 = checkOut;
          }
          
          final diff = d2.millisecondsSinceEpoch - d1.millisecondsSinceEpoch;
          totalTime += diff;
        }
      }
    }
    
    return totalTime / msInHour;
  }
}
