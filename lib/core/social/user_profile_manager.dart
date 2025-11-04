import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// User Profile Manager
/// Features:
/// - User profiles with avatars
/// - Contact ratings
/// - Sharing statistics
/// - Frequent contacts
class UserProfileManager {
  final Logger _logger = Logger();
  SharedPreferences? _prefs;
  
  UserProfile? _currentProfile;
  final Map<String, ContactProfile> _contacts = {};
  
  /// Initialize profile manager
  Future<bool> initialize() async {
    try {
      _logger.i('[Profile] Initializing user profile manager...');
      _prefs = await SharedPreferences.getInstance();
      
      // Load current user profile
      await _loadCurrentProfile();
      
      // Load contacts
      await _loadContacts();
      
      _logger.i('[Profile] User profile manager initialized');
      return true;
    } catch (e) {
      _logger.e('[Profile] Initialization failed: $e');
      return false;
    }
  }
  
  /// Create or update user profile
  Future<void> setUserProfile(UserProfile profile) async {
    _currentProfile = profile;
    await _prefs?.setString('user_profile', jsonEncode(profile.toJson()));
    _logger.i('[Profile] User profile updated: ${profile.name}');
  }
  
  /// Get current user profile
  UserProfile? getCurrentProfile() => _currentProfile;
  
  /// Add or update contact
  Future<void> updateContact(ContactProfile contact) async {
    _contacts[contact.id] = contact;
    await _saveContacts();
    _logger.i('[Profile] Contact updated: ${contact.name}');
  }
  
  /// Rate a contact
  Future<void> rateContact(String contactId, double rating) async {
    final contact = _contacts[contactId];
    if (contact == null) return;
    
    contact.ratings.add(rating);
    contact.averageRating = contact.ratings.reduce((a, b) => a + b) / contact.ratings.length;
    contact.lastInteraction = DateTime.now();
    
    await _saveContacts();
    _logger.i('[Profile] Contact rated: ${contact.name} - $rating');
  }
  
  /// Record transfer with contact
  Future<void> recordTransfer(String contactId, int fileSize, bool success) async {
    final contact = _contacts[contactId];
    if (contact == null) {
      // Create new contact
      final newContact = ContactProfile(
        id: contactId,
        name: 'User $contactId',
        totalTransfers: 1,
        successfulTransfers: success ? 1 : 0,
        totalBytesTransferred: fileSize,
        lastInteraction: DateTime.now(),
        averageRating: 5.0,
        ratings: [5.0],
        isFavorite: false,
      );
      _contacts[contactId] = newContact;
    } else {
      contact.totalTransfers++;
      if (success) contact.successfulTransfers++;
      contact.totalBytesTransferred += fileSize;
      contact.lastInteraction = DateTime.now();
    }
    
    await _saveContacts();
  }
  
  /// Get frequent contacts
  List<ContactProfile> getFrequentContacts({int limit = 10}) {
    final sorted = _contacts.values.toList()
      ..sort((a, b) => b.totalTransfers.compareTo(a.totalTransfers));
    return sorted.take(limit).toList();
  }
  
  /// Get favorite contacts
  List<ContactProfile> getFavoriteContacts() {
    return _contacts.values.where((c) => c.isFavorite).toList();
  }
  
  /// Toggle favorite status
  Future<void> toggleFavorite(String contactId) async {
    final contact = _contacts[contactId];
    if (contact == null) return;
    
    contact.isFavorite = !contact.isFavorite;
    await _saveContacts();
  }
  
  /// Get sharing statistics
  SharingStatistics getStatistics() {
    int totalTransfers = 0;
    int successfulTransfers = 0;
    int totalBytes = 0;
    
    for (final contact in _contacts.values) {
      totalTransfers += contact.totalTransfers;
      successfulTransfers += contact.successfulTransfers;
      totalBytes += contact.totalBytesTransferred;
    }
    
    return SharingStatistics(
      totalTransfers: totalTransfers,
      successfulTransfers: successfulTransfers,
      failedTransfers: totalTransfers - successfulTransfers,
      totalBytesTransferred: totalBytes,
      totalContacts: _contacts.length,
      favoriteContacts: _contacts.values.where((c) => c.isFavorite).length,
      averageRating: _calculateAverageRating(),
    );
  }
  
  /// Calculate average rating across all contacts
  double _calculateAverageRating() {
    if (_contacts.isEmpty) return 0.0;
    
    double totalRating = 0;
    int count = 0;
    
    for (final contact in _contacts.values) {
      if (contact.ratings.isNotEmpty) {
        totalRating += contact.averageRating;
        count++;
      }
    }
    
    return count > 0 ? totalRating / count : 0.0;
  }
  
  /// Load current profile
  Future<void> _loadCurrentProfile() async {
    final profileJson = _prefs?.getString('user_profile');
    if (profileJson != null) {
      _currentProfile = UserProfile.fromJson(jsonDecode(profileJson));
    } else {
      // Create default profile
      _currentProfile = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'User',
        avatarColor: 0xFF667eea,
        createdAt: DateTime.now(),
      );
      await setUserProfile(_currentProfile!);
    }
  }
  
  /// Load contacts
  Future<void> _loadContacts() async {
    final contactsJson = _prefs?.getString('contacts');
    if (contactsJson != null) {
      final List<dynamic> contactsList = jsonDecode(contactsJson);
      for (final contactJson in contactsList) {
        final contact = ContactProfile.fromJson(contactJson);
        _contacts[contact.id] = contact;
      }
    }
  }
  
  /// Save contacts
  Future<void> _saveContacts() async {
    final contactsList = _contacts.values.map((c) => c.toJson()).toList();
    await _prefs?.setString('contacts', jsonEncode(contactsList));
  }
}

/// User profile
class UserProfile {
  final String id;
  String name;
  int avatarColor;
  String? avatarUrl;
  final DateTime createdAt;
  
  UserProfile({
    required this.id,
    required this.name,
    required this.avatarColor,
    this.avatarUrl,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarColor': avatarColor,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    name: json['name'],
    avatarColor: json['avatarColor'],
    avatarUrl: json['avatarUrl'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Contact profile
class ContactProfile {
  final String id;
  String name;
  int totalTransfers;
  int successfulTransfers;
  int totalBytesTransferred;
  DateTime lastInteraction;
  double averageRating;
  List<double> ratings;
  bool isFavorite;
  
  ContactProfile({
    required this.id,
    required this.name,
    required this.totalTransfers,
    required this.successfulTransfers,
    required this.totalBytesTransferred,
    required this.lastInteraction,
    required this.averageRating,
    required this.ratings,
    required this.isFavorite,
  });
  
  double get successRate => totalTransfers > 0 ? successfulTransfers / totalTransfers : 0.0;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'totalTransfers': totalTransfers,
    'successfulTransfers': successfulTransfers,
    'totalBytesTransferred': totalBytesTransferred,
    'lastInteraction': lastInteraction.toIso8601String(),
    'averageRating': averageRating,
    'ratings': ratings,
    'isFavorite': isFavorite,
  };
  
  factory ContactProfile.fromJson(Map<String, dynamic> json) => ContactProfile(
    id: json['id'],
    name: json['name'],
    totalTransfers: json['totalTransfers'],
    successfulTransfers: json['successfulTransfers'],
    totalBytesTransferred: json['totalBytesTransferred'],
    lastInteraction: DateTime.parse(json['lastInteraction']),
    averageRating: json['averageRating'].toDouble(),
    ratings: List<double>.from(json['ratings']),
    isFavorite: json['isFavorite'],
  );
}

/// Sharing statistics
class SharingStatistics {
  final int totalTransfers;
  final int successfulTransfers;
  final int failedTransfers;
  final int totalBytesTransferred;
  final int totalContacts;
  final int favoriteContacts;
  final double averageRating;
  
  SharingStatistics({
    required this.totalTransfers,
    required this.successfulTransfers,
    required this.failedTransfers,
    required this.totalBytesTransferred,
    required this.totalContacts,
    required this.favoriteContacts,
    required this.averageRating,
  });
  
  double get successRate => totalTransfers > 0 ? successfulTransfers / totalTransfers : 0.0;
}
