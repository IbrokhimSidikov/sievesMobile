class TestOption {
  final int id;
  final int companyId;
  final int createdBy;
  final int updatedBy;
  final int testId;
  final String text;
  final bool isCorrect;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool deleted;

  TestOption({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.updatedBy,
    required this.testId,
    required this.text,
    required this.isCorrect,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
  });

  factory TestOption.fromJson(Map<String, dynamic> json) {
    return TestOption(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'] ?? 0,
      testId: json['test_id'] ?? 0,
      text: json['text'] ?? '',
      isCorrect: json['is_correct'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      deleted: json['deleted'] ?? false,
    );
  }
}

class TestPair {
  final int id;
  final int companyId;
  final int createdBy;
  final int updatedBy;
  final int testId;
  final String leftItem;
  final String rightItem;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool deleted;

  TestPair({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.updatedBy,
    required this.testId,
    required this.leftItem,
    required this.rightItem,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
  });

  factory TestPair.fromJson(Map<String, dynamic> json) {
    return TestPair(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'] ?? 0,
      testId: json['test_id'] ?? 0,
      leftItem: json['left_item'] ?? '',
      rightItem: json['right_item'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      deleted: json['deleted'] ?? false,
    );
  }
}

class Test {
  final int id;
  final int companyId;
  final int createdBy;
  final int updatedBy;
  final int courseId;
  final String testType;
  final String question;
  final int sortOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool deleted;
  final List<TestPair> pairs;
  final List<TestOption> options;

  Test({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.updatedBy,
    required this.courseId,
    required this.testType,
    required this.question,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
    required this.pairs,
    required this.options,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'] ?? 0,
      courseId: json['course_id'] ?? 0,
      testType: json['test_type'] ?? '',
      question: json['question'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      deleted: json['deleted'] ?? false,
      pairs: (json['pairs'] as List<dynamic>?)
              ?.map((pair) => TestPair.fromJson(pair))
              .toList() ??
          [],
      options: (json['options'] as List<dynamic>?)
              ?.map((option) => TestOption.fromJson(option))
              .toList() ??
          [],
    );
  }
}

class CourseWithTests {
  final int id;
  final int companyId;
  final int themeId;
  final int createdBy;
  final int updatedBy;
  final String name;
  final String description;
  final String? pdfUrl;
  final String? videoUrl;
  final int sortOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool deleted;
  final Map<String, dynamic>? theme;
  final List<Test> tests;

  CourseWithTests({
    required this.id,
    required this.companyId,
    required this.themeId,
    required this.createdBy,
    required this.updatedBy,
    required this.name,
    required this.description,
    this.pdfUrl,
    this.videoUrl,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
    this.theme,
    required this.tests,
  });

  factory CourseWithTests.fromJson(Map<String, dynamic> json) {
    return CourseWithTests(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      themeId: json['theme_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pdfUrl: json['pdf_url'],
      videoUrl: json['video_url'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      deleted: json['deleted'] ?? false,
      theme: json['theme'],
      tests: (json['tests'] as List<dynamic>?)
              ?.map((test) => Test.fromJson(test))
              .toList() ??
          [],
    );
  }
}
