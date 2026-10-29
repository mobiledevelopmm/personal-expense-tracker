import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../../data/services/notification_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _transactionAlerts = true;

  static const String _emailNotificationsKey = 'email_notifications_enabled';
  static const String _transactionAlertsKey = 'transaction_alerts_enabled';

  bool _isDark = false;
  bool _isUploadingPhoto = false;
  bool _isSavingProfile = false;
  String? _savedName;
  bool _isLoadingProfileName = true;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingProfileName = false);
      return;
    }

    try {
      // Read Firestore first because it is the app's saved profile source.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final firestoreName = (doc.data()?['name'] as String?)?.trim() ?? '';

      // Refresh Firebase Auth as a fallback if Firestore has no name.
      if (firestoreName.isEmpty) {
        await user.reload();
      }

      if (!mounted) return;
      setState(() {
        _savedName = firestoreName.isNotEmpty
            ? firestoreName
            : (FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
            ? FirebaseAuth.instance.currentUser!.displayName!.trim()
            : null);
        _isLoadingProfileName = false;
      });
    } catch (error) {
      debugPrint('Could not load profile name: $error');
      if (!mounted) return;
      setState(() => _isLoadingProfileName = false);
    }
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneEnabled = await NotificationService.instance
        .areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = phoneEnabled;
      _emailNotifications = prefs.getBool(_emailNotificationsKey) ?? true;
      _transactionAlerts = prefs.getBool(_transactionAlertsKey) ?? true;
    });
  }

  static const Color _navy = Color(0xFF101D2C);
  static const Color _navyLight = Color(0xFF1B3042);
  static const Color _emerald = Color(0xFF0F766E);
  static const Color _emeraldDark = Color(0xFF115E59);
  static const Color _mint = Color(0xFFB9E4D0);
  static const Color _lightMint = Color(0xFFE3F3EB);
  static const Color _background = Color(0xFFF3F5F2);
  static const Color _secondaryText = Color(0xFF697A80);
  static const Color _border = Color(0xFFE1E8E3);
  static const Color _danger = Color(0xFFC45B58);

  Color get _pageColor => _isDark ? _navy : _background;
  Color get _surfaceColor => _isDark ? _navyLight : Colors.white;
  Color get _primaryText => _isDark ? Colors.white : _navy;
  Color get _mutedText => _isDark ? const Color(0xFFB0BEC5) : _secondaryText;
  Color get _lineColor => _isDark ? const Color(0xFF344957) : _border;
  Color get _iconSurface => _isDark ? const Color(0xFF294640) : _lightMint;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    _isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

    // Read the latest Firebase user so updated profile details can appear.
    final user = _currentUser;
    final email = user?.email ?? '';
    final name = _displayName(user);

    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 26),
            _buildAccountCard(name, email),
            const SizedBox(height: 30),
            _buildSectionHeading('Preferences', 'Make the app work for you'),
            const SizedBox(height: 15),
            _buildPreferencesCard(),
            const SizedBox(height: 28),
            _buildSectionHeading('Support', 'We are here to help'),
            const SizedBox(height: 15),
            _buildSupportCard(),
            const SizedBox(height: 28),
            _buildLogoutButton(),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'PERSONAL EXPENSE TRACKER',
                style: TextStyle(
                  color: _mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Your money, clearly understood.',
                style: TextStyle(color: _mutedText, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MY ACCOUNT',
                style: TextStyle(
                  color: _emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'My Profile',
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account and preferences',
                style: TextStyle(color: _mutedText, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Account card
  Widget _buildAccountCard(String name, String email) {
    final initials = _getInitials(name);
    final photoUrl = _currentUser?.photoURL;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _lineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.08 : 0.025),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildProfileAvatar(photoUrl, initials),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _iconSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: _emerald,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Account',
                            style: TextStyle(
                              color: _isDark ? _mint : _emeraldDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Center(
            child: Text(
              _isUploadingPhoto
                  ? 'Uploading photo...'
                  : 'Tap your photo to change it',
              style: TextStyle(color: _mutedText, fontSize: 12),
            ),
          ),

          const SizedBox(height: 18),

          // Edit Profile button
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _isSavingProfile ? null : _editProfile,
              icon: _isSavingProfile
                  ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.edit_outlined, size: 18),
              label: Text(_isSavingProfile ? 'Saving...' : 'Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _emerald,
                side: const BorderSide(color: _emerald),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Divider(height: 1, color: _lineColor),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _smallIcon(Icons.email_outlined),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMAIL ADDRESS',
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      email.isEmpty ? 'No email available' : email,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Profile photo with camera button
  Widget _buildProfileAvatar(String? photoUrl, String initials) {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
      child: SizedBox(
        width: 82,
        height: 82,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_emerald, _emeraldDark],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isUploadingPhoto
                  ? const Center(
                child: SizedBox(
                  width: 27,
                  height: 27,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              )
                  : photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: 76,
                height: 76,
                errorBuilder: (context, error, stackTrace) {
                  return _initialsAvatar(initials);
                },
              )
                  : _initialsAvatar(initials),
            ),

            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: _emerald,
                  shape: BoxShape.circle,
                  border: Border.all(color: _surfaceColor, width: 2.5),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsAvatar(String initials) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_emerald, _emeraldDark],
        ),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // Upload profile photo to Firebase Storage and update Firebase Auth.
  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image == null || !mounted) return;

      final user = _currentUser;
      if (user == null) {
        _showMessage('Please sign in again.');
        return;
      }

      setState(() => _isUploadingPhoto = true);

      // Use the default Firebase Storage bucket configured for this app.
      // The uploaded object path must match the path used to get its URL.
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      final imageBytes = await image.readAsBytes();
      final uploadSnapshot = await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get the URL from the actual uploaded object's reference.
      final photoUrl = await uploadSnapshot.ref.getDownloadURL();

      await user.updatePhotoURL(photoUrl);
      await user.reload();

      if (!mounted) return;

      setState(() {});
      _showMessage('Profile photo updated successfully.');
    } on FirebaseException catch (error) {
      if (!mounted) return;

      String message;
      switch (error.code) {
        case 'object-not-found':
          message = 'Photo was not found in Firebase Storage. Check that Firebase Storage is enabled and the upload completed.';
          break;
        case 'bucket-not-found':
          message = 'Firebase Storage bucket was not found. Create/enable the Storage bucket in Firebase Console and check firebase_options.dart.';
          break;
        case 'unauthorized':
        case 'permission-denied':
          message = 'Upload permission denied. Please check your Firebase Storage Rules.';
          break;
        case 'canceled':
          message = 'Photo upload was cancelled. Please try again.';
          break;
        default:
          message =
          'Upload failed (${error.code}): ${error.message ?? 'Please try again.'}';
      }
      _showMessage(message);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not update profile photo. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  // Edit display name

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in again.');
      return;
    }

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialName: _savedName ?? user.displayName ?? '',
        surfaceColor: _surfaceColor,
        primaryText: _primaryText,
        pageColor: _pageColor,
      ),
    );

    if (newName == null || !mounted) return;

    final updatedName = newName.trim();

    if (updatedName.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    if (updatedName == (user.displayName ?? '').trim()) {
      _showMessage('No changes were made.');
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      // Update Firebase Authentication.
      await user.updateDisplayName(updatedName);

      // Update Firestore without deleting existing fields.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': updatedName,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAuth.instance.currentUser?.reload();

      if (!mounted) return;

      setState(() {
        _savedName = updatedName;
      });
      _showMessage('Profile updated successfully.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(
        'Could not update profile: ${error.message ?? error.code}',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(
        'Firestore error: ${error.message ?? error.code}',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not update profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  String _displayName(User? user) {
    final savedName = _savedName?.trim() ?? '';
    if (savedName.isNotEmpty) return savedName;

    // Avoid briefly showing the email prefix while the saved name loads.
    if (_isLoadingProfileName) return 'Loading...';

    final authName = user?.displayName?.trim() ?? '';
    if (authName.isNotEmpty) return authName;

    final emailName = user?.email?.split('@').first.trim() ?? '';
    if (emailName.isNotEmpty) return emailName;

    return 'User';
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}'
        '${parts.last.characters.first}'
        .toUpperCase();
  }

  Widget _smallIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _iconSurface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(child: Icon(icon, color: _emerald, size: 21)),
    );
  }

  // Section headings
  Widget _buildSectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: _mutedText, fontSize: 13)),
      ],
    );
  }

  // Preferences
  Widget _buildPreferencesCard() {
    return _settingsCard(
      children: [
        _settingsRow(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: _notificationsEnabled
              ? 'Your notification preferences'
              : 'Notifications are turned off',
          onTap: _showNotifications,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: _mutedText,
            size: 24,
          ),
        ),
        _rowDivider(),
        _settingsRow(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          subtitle: _isDark ? 'Dark appearance' : 'Light appearance',
          onTap: () {
            context.read<ThemeCubit>().toggleTheme(!_isDark);
          },
          trailing: Switch.adaptive(
            value: _isDark,
            activeTrackColor: _emerald,
            activeThumbColor: _mint,
            onChanged: (value) {
              context.read<ThemeCubit>().toggleTheme(value);
            },
          ),
        ),
        _rowDivider(),
        _settingsRow(
          icon: Icons.shield_outlined,
          title: 'Security',
          subtitle: 'Manage your account security',
          onTap: _showSecurity,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: _mutedText,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    return _settingsCard(
      children: [
        _settingsRow(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'FAQs and app guidance',
          onTap: _showHelp,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: _mutedText,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _lineColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _smallIcon(icon),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _rowDivider() {
    return Divider(height: 1, thickness: 1, color: _lineColor, indent: 53);
  }

  // Notification preferences
  Future<void> _showNotifications() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _surfaceColor,
              title: Text(
                'Notifications',
                style: TextStyle(
                  color: _primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Device Notifications',
                      style: TextStyle(color: _primaryText),
                    ),
                    subtitle: Text(
                      'Choose whether to receive notifications on your phone.',
                      style: TextStyle(color: _mutedText),
                    ),
                    value: _notificationsEnabled,
                    activeTrackColor: _emerald,
                    onChanged: (value) async {
                      await NotificationService.instance
                          .setNotificationsEnabled(value);
                      if (!mounted) return;
                      setDialogState(() {
                        _notificationsEnabled = value;
                      });
                      setState(() {});
                    },
                  ),
                  Divider(color: _lineColor),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Email notifications',
                      style: TextStyle(color: _primaryText),
                    ),
                    value: _emailNotifications,
                    activeTrackColor: _emerald,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(_emailNotificationsKey, value);
                      if (!mounted) return;
                      setDialogState(() => _emailNotifications = value);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Transaction alerts',
                      style: TextStyle(color: _primaryText),
                    ),
                    value: _transactionAlerts,
                    activeTrackColor: _emerald,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(_transactionAlertsKey, value);
                      if (!mounted) return;
                      setDialogState(() => _transactionAlerts = value);
                      setState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Security and Firebase password reset
  Future<void> _showSecurity() async {
    final email = _currentUser?.email ?? '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          icon: const Icon(Icons.shield_outlined, color: _emerald, size: 35),
          title: Text(
            'Account Security',
            style: TextStyle(color: _primaryText, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signed-in email',
                style: TextStyle(color: _mutedText, fontSize: 12),
              ),
              const SizedBox(height: 6),
              SelectableText(
                email.isEmpty ? 'No email available' : email,
                style: TextStyle(
                  color: _primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'You can request a password reset email to help protect your account.',
                style: TextStyle(color: _mutedText, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                foregroundColor: Colors.white,
              ),
              onPressed: email.isEmpty
                  ? null
                  : () {
                Navigator.pop(dialogContext);
                _sendPasswordReset(email);
              },
              child: const Text('Reset Password'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showMessage('Password reset email sent. Please check your inbox.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      final message = switch (error.code) {
        'invalid-email' => 'The email address is invalid.',
        'user-not-found' => 'No account was found for this email.',
        'too-many-requests' => 'Please wait before trying again.',
        _ => 'Could not send the reset email. Please try again.',
      };

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Something went wrong. Please try again.');
    }
  }

  // Help and support
  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          icon: const Icon(
            Icons.support_agent_rounded,
            color: _emerald,
            size: 36,
          ),
          title: Text(
            'Help & Support',
            style: TextStyle(color: _primaryText, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _faq(
                  'How do I add a transaction?',
                  'Open Home and use the add transaction button to record your income or expenses.',
                ),
                _faq(
                  'Where can I view my spending?',
                  'Open Analytics to review income, expenses, and spending categories.',
                ),
                _faq(
                  'How do I change the app appearance?',
                  'Use the Dark Mode switch in Profile to change between light and dark themes.',
                ),
                _faq(
                  'How do I reset my password?',
                  'Open Security and choose Reset Password. Firebase will send a password reset email.',
                ),
                const SizedBox(height: 5),
                Text(
                  'For additional assistance, contact your app administrator.',
                  style: TextStyle(
                    color: _mutedText,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _faq(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              color: _primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            answer,
            style: TextStyle(color: _mutedText, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Logout confirmation
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          icon: const Icon(Icons.logout_rounded, color: _danger, size: 34),
          title: Text(
            'Log Out?',
            style: TextStyle(color: _primaryText, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(color: _mutedText, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await context.read<AuthCubit>().logout();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to log out. Please try again.');
    }
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _danger,
          backgroundColor: _surfaceColor,
          side: BorderSide(
            color: _isDark ? const Color(0xFF714746) : const Color(0xFFE8C7C5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

/// A dedicated dialog widget that owns its text controller.
/// This avoids disposing the controller while the dialog is still closing.
class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialName,
    required this.surfaceColor,
    required this.primaryText,
    required this.pageColor,
  });

  final String initialName;
  final Color surfaceColor;
  final Color primaryText;
  final Color pageColor;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(
        Icons.manage_accounts_outlined,
        color: Color(0xFF0F766E),
        size: 34,
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: widget.primaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: widget.primaryText),
          decoration: InputDecoration(
            labelText: 'Full name',
            hintText: 'Enter your name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            filled: true,
            fillColor: widget.pageColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            if (value.trim().length < 2) {
              return 'Name must have at least 2 characters';
            }
            return null;
          },
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}