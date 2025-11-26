# LMS (Learning Management System) - Test Module

## Overview
A professional, production-ready test/quiz system for mobile applications built with Flutter. This system follows industry best practices for mobile test applications with elegant UI/UX design.

## Architecture

### 1. Data Models (`/models`)

#### `QuestionType` (Enum)
- `multipleChoice` - Single correct answer from multiple options
- `trueFalse` - Binary true/false questions
- `multiSelect` - Multiple correct answers possible

#### `AnswerOption`
```dart
{
  id: String,
  text: String,
  isCorrect: bool
}
```

#### `Question`
```dart
{
  id: String,
  text: String,
  type: QuestionType,
  options: List<AnswerOption>,
  explanation: String?,
  points: int
}
```

#### `Test`
```dart
{
  id: String,
  title: String,
  description: String,
  category: String,
  duration: int (minutes),
  totalQuestions: int,
  passingScore: int (percentage),
  imageUrl: String?,
  questions: List<Question>?,
  createdAt: DateTime?,
  isCompleted: bool,
  userScore: int?
}
```

#### `TestAnswer`
```dart
{
  questionId: String,
  selectedOptionIds: List<String>,
  isCorrect: bool
}
```

### 2. Pages (`/pages`)

#### **LmsPage** - Test List View
**Features:**
- Elegant gradient header with test count badge
- Grid/list of test cards with:
  - Category-colored badges
  - Test images with gradient overlays
  - Completion status indicators
  - Test metadata (questions, duration, passing score)
  - Previous scores for completed tests
- Loading states with shimmer effect
- Empty state handling

**Design Elements:**
- Purple gradient header (indigo to violet)
- Category-specific colors (Safety=Red, Service=Blue, Operations=Orange, Product=Green)
- Completion checkmarks for passed tests
- Info chips with icons for quick stats

#### **TestDetailPage** - Test Preview
**Features:**
- Full test information display
- Test header with image and category badge
- Detailed test information section
- Instructions list
- Previous score display (if completed)
- Start/Retake test button

**Design Elements:**
- Large hero image with gradient overlay
- Circular completion badge
- Info rows with colored icons
- Bullet-point instructions
- Prominent CTA button with gradient

#### **TestTakingPage** - Interactive Test Interface
**Features:**
- **Timer System:**
  - Countdown timer in MM:SS format
  - Visual warning when < 5 minutes remain
  - Auto-submit when time expires
  
- **Progress Tracking:**
  - Linear progress bar
  - Answered/Total question counter
  - Visual progress percentage

- **Question Navigation:**
  - Swipeable PageView for questions
  - Previous/Next buttons
  - Question grid modal (bottom sheet)
  - Visual indicators (current, answered, unanswered)

- **Answer Selection:**
  - Single-select (radio) for multiple choice
  - Multi-select (checkbox) for multi-answer questions
  - Visual feedback on selection
  - Answer persistence across navigation

- **Safety Features:**
  - Exit confirmation dialog
  - Submit confirmation for unanswered questions
  - Progress preservation during navigation

**Design Elements:**
- Clean white question cards
- Gradient question number badges
- Color-coded timer (blue → red when low)
- Smooth page transitions
- Bottom navigation bar with gradient buttons

#### **TestResultPage** - Score & Review
**Features:**
- **Result Display:**
  - Pass/Fail status with appropriate colors
  - Large circular progress indicator
  - Percentage score with fraction
  - Pass/Fail badge

- **Statistics Cards:**
  - Correct answers count
  - Incorrect answers count
  - Time taken (MM:SS format)

- **Test Summary:**
  - Complete test information
  - Score comparison with passing score

- **Actions:**
  - Return to test list
  - Retake test (if failed)

**Design Elements:**
- Success (green) or failure (red) theme
- Large circular score display
- Icon-based stat cards
- Gradient action buttons
- Celebratory/encouraging messaging

## User Flow

```
LMS Page (Test List)
    ↓ (Tap test card)
Test Detail Page
    ↓ (Start Test)
Test Taking Page
    ↓ (Submit)
Test Result Page
    ↓ (Back to Tests / Retake)
LMS Page
```

## Key Features

### Professional Test Logic
1. **Timer Management**
   - Accurate countdown timer
   - Auto-submission on timeout
   - Visual time warnings

2. **Answer Tracking**
   - State management for all answers
   - Support for different question types
   - Answer validation

3. **Score Calculation**
   - Automatic grading
   - Percentage-based scoring
   - Pass/fail determination

4. **Navigation**
   - Free navigation between questions
   - Progress preservation
   - Question grid overview

### UI/UX Best Practices
1. **Visual Hierarchy**
   - Clear information architecture
   - Consistent color coding
   - Appropriate use of gradients and shadows

2. **Feedback**
   - Loading states
   - Selection feedback
   - Progress indicators
   - Success/error states

3. **Accessibility**
   - Clear typography
   - Sufficient color contrast
   - Touch-friendly targets
   - Readable font sizes

4. **Responsive Design**
   - Uses flutter_screenutil for scaling
   - Adapts to different screen sizes
   - Proper spacing and padding

## Integration Guide

### 1. API Integration
Replace sample data in `LmsPage._loadTests()` with actual API calls:

```dart
Future<void> _loadTests() async {
  setState(() => _isLoading = true);
  
  try {
    final response = await apiService.get('/api/tests');
    _tests = (response.data as List)
        .map((json) => Test.fromJson(json))
        .toList();
  } catch (e) {
    // Handle error
  }
  
  setState(() => _isLoading = false);
}
```

### 2. Question Loading
In `TestDetailPage._startTest()`, fetch questions from API:

```dart
void _startTest(BuildContext context) async {
  final questions = await apiService.get('/api/tests/${test.id}/questions');
  final testWithQuestions = test.copyWith(
    questions: questions.map((q) => Question.fromJson(q)).toList()
  );
  context.push('/testTaking', extra: testWithQuestions);
}
```

### 3. Result Submission
In `TestTakingPage._submitTest()`, send results to backend:

```dart
await apiService.post('/api/tests/${widget.test.id}/submit', {
  'answers': _answers,
  'score': score,
  'timeTaken': widget.test.duration * 60 - _remainingSeconds,
});
```

## Customization

### Colors
Category colors are defined in `_getCategoryColor()`:
- Safety: Red (`AppColors.cxCrimsonRed`)
- Service: Blue (`AppColors.cxRoyalBlue`)
- Operations: Orange (`AppColors.cxWarning`)
- Product: Green (`AppColors.cxEmeraldGreen`)

### Timing
Adjust timer warning threshold in `TestTakingPage._buildHeader()`:
```dart
final isLowTime = _remainingSeconds < 300; // 5 minutes
```

### Scoring
Modify passing criteria in test data or add custom logic in `TestResultPage`.

## Dependencies
- `flutter_screenutil` - Responsive sizing
- `go_router` - Navigation
- Standard Flutter packages (material, dart:async, dart:ui)

## Future Enhancements
1. **Question Review Mode** - Review answers after completion
2. **Bookmarking** - Mark questions for review
3. **Offline Support** - Cache tests and sync results
4. **Analytics** - Track performance over time
5. **Certificates** - Generate completion certificates
6. **Leaderboards** - Compare scores with peers
7. **Question Explanations** - Show explanations after submission
8. **Adaptive Testing** - Adjust difficulty based on performance

## Notes
- All sample data is currently hardcoded for demonstration
- Images use Unsplash URLs - replace with your CDN
- Timer persists during navigation within test
- Answers are stored in memory (not persisted)
- No authentication checks (add as needed)

## File Structure
```
lib/features/lms/
├── models/
│   ├── answer_option.dart
│   ├── question.dart
│   ├── question_type.dart
│   ├── test.dart
│   └── test_answer.dart
├── pages/
│   ├── lms_page.dart
│   ├── test_detail_page.dart
│   ├── test_taking_page.dart
│   └── test_result_page.dart
└── README.md
```

## License
Part of the Sieves Mobile application.
