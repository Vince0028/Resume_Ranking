class UserProfile {
  String id; // Supabase user ID
  String name;
  String bio;
  String email;
  String phone;
  String imagePath; // Path to local image or asset
  String backgroundImagePath; // Path for profile banner
  List<String> hobbies;
  List<Project> projects;
  double? latitude;
  double? longitude;

  UserProfile({
    this.id = '',
    this.name = 'Vince Nelmar Alobin',
    this.bio =
        'Full Stack Developer | Mobile App Enthusiast | UI/UX Designer | Open Source Contributor',
    this.email = 'alobinvince@gmail.com',
    this.phone = '+63 912 345 6789',
    this.imagePath = '',
    this.backgroundImagePath = '',
    this.hobbies = const [
      'Flutter',
      'React',
      'Python',
      'UI/UX',
      'Open Source',
      'Full Stack',
    ],
    this.projects = const [],
    this.latitude,
    this.longitude,
  });

  // Factory constructor for empty profile (new users)
  factory UserProfile.empty() {
    return UserProfile(
      id: '',
      name: '',
      bio: '',
      email: '',
      phone: '',
      imagePath: '',
      backgroundImagePath: '',
      hobbies: [],
      projects: [],
      latitude: null,
      longitude: null,
    );
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'email': email,
      'phone': phone,
      'hobbies': hobbies,
      'latitude': latitude,
      'longitude': longitude,
      'projects': projects.map((p) => p.toJson()).toList(),
    };
  }

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      hobbies: List<String>.from(json['hobbies'] ?? []),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      projects:
          (json['projects'] as List?)
              ?.map((p) => Project.fromJson(p))
              .toList() ??
          [],
    );
  }
}

// Resume model for the ranking system
class Resume {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String title;
  final String content;
  final Map<String, dynamic> resumeData;
  final double averageRating;
  final int totalRatings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Resume({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.title,
    required this.content,
    required this.resumeData,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final resumeData = json['resume_data'] as Map<String, dynamic>? ?? {};

    // Get userName from profiles join first, fallback to resume_data, then 'Unknown'
    final userName = profile?['name'] ?? resumeData['name'] ?? 'Unknown';

    return Resume(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: userName,
      userAvatarUrl: profile?['avatar_url'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      resumeData: resumeData,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'resume_data': resumeData,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
    };
  }
}

class Project {
  final String title;
  final String description;
  final String stack;
  final String? link;

  const Project({
    required this.title,
    required this.description,
    required this.stack,
    this.link,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'stack': stack,
      'link': link,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      stack: json['stack'] ?? '',
      link: json['link'],
    );
  }
}

class Friend {
  String id;
  String name;
  String contact;
  String imagePath;

  Friend({
    required this.id,
    required this.name,
    required this.contact,
    this.imagePath = '',
  });
}
