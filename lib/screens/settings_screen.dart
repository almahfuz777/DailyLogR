// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dailylogr/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/version_provider.dart';
import 'package:dailylogr/providers/user_config_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLinkingGoogle = false;
  bool _isNotificationsEnabled = false;
  bool _isLoadingNotifications = true;
  bool _isAutoSaveEnabled = true;
  bool _isLoadingAutoSave = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationState();
    _loadAutoSaveState();
  }

  Future<void> _loadAutoSaveState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isAutoSaveEnabled = prefs.getBool('pref_auto_save') ?? true;
        _isLoadingAutoSave = false;
      });
    }
  }

  Future<void> _setAutoSaveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_auto_save', enabled);
    if (mounted) {
      setState(() {
        _isAutoSaveEnabled = enabled;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }

  /// Shows a dialog for selecting the first day of the week.
  Future<void> _showFirstDayOfWeekDialog(int currentDay) async {
    // Dart weekday: Mon=1 ... Sat=6, Sun=7
    const days = [
      (label: 'Saturday', value: 6),
      (label: 'Sunday', value: 7),
      (label: 'Monday', value: 1),
      (label: 'Friday', value: 5),
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('First Day of Week'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        children: days.map((day) {
          final isSelected = day.value == currentDay;
          return SimpleDialogOption(
            onPressed: () {
              ref.read(userConfigProvider.notifier).setFirstDayOfWeek(day.value);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Expanded(child: Text(day.label)),
                if (isSelected)
                  Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _loadNotificationState() async {
    final isEnabled = await NotificationService().isDailyRemindersEnabled();
    if (mounted) {
      setState(() {
        _isNotificationsEnabled = isEnabled;
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context, {required bool isNew}) async {
    final oldPasswordController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    /// Change password dialog
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Column(
                children: [
                  Icon(
                    isNew ? Icons.lock_person_outlined : Icons.lock_reset_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(isNew ? 'Set Password' : 'Change Password'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null) ...[
                    Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 8),
                  ],
                  if (!isNew) ...[
                    TextField(
                      controller: oldPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isNew ? 'Password' : 'New Password',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!isNew && oldPasswordController.text.isEmpty) {
                            setState(() => errorMessage = 'Please enter your current password');
                            return;
                          }
                          if (passwordController.text.length < 6) {
                            setState(() => errorMessage = 'Password must be at least 6 characters');
                            return;
                          }
                          if (passwordController.text != confirmController.text) {
                            setState(() => errorMessage = 'Passwords do not match');
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          try {
                            await FirebaseAuthService.updatePassword(
                              passwordController.text,
                              oldPassword: isNew ? null : oldPasswordController.text,
                            );
                            if (!context.mounted) return;
                            
                            // Re-trigger a rebuild of the Settings screen so the UI updates
                            this.setState(() {}); 

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isNew 
                                  ? 'Password set! You can now log in using your email and password.' 
                                  : 'Password updated successfully.'),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            setState(() {
                              if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
                                errorMessage = 'The current password you entered is incorrect.';
                              } else {
                                errorMessage = e.message ?? 'An error occurred';
                              }
                            });
                          } catch (e) {
                            setState(() => errorMessage = 'An error occurred');
                          } finally {
                            if (context.mounted) setState(() => isLoading = false);
                          }
                        },
                  child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ) 
                    : Text(isNew ? 'Set Password' : 'Update'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  /// Link Google account
  Future<void> _linkGoogleAccount() async {
    setState(() => _isLinkingGoogle = true);
    try {
      final user = FirebaseAuthService.currentUser;
      if (user == null) {
        await FirebaseAuthService.signInWithGoogle();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in with Google.')),
        );
      } else {
        await FirebaseAuthService.linkGoogleAccount();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully connected your Google account.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String msg = e.message ?? 'Failed to connect Google account.';
      if (e.code == 'credential-already-in-use') {
        msg = 'This Google account is already linked to another user.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().toLowerCase();
      if (err.contains('canceled') || err.contains('aborted')) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLinkingGoogle = false);
    }
  }

  /// Build settings screen
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuthService.currentUser;
    
    final hasPasswordProvider = user?.providerData.any((p) => p.providerId == 'password') ?? false;
    final hasGoogleProvider = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    
    // Watch dynamic version status
    final versionState = ref.watch(appVersionProvider);

    // Items for settings screen
    return ListView(
      padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'General',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          Builder(
            builder: (context) {
              final config = ref.watch(userConfigProvider);
              const dayNames = {
                1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
                4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday',
              };
              return ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('First Day of Week'),
                subtitle: Text(dayNames[config.firstDayOfWeek] ?? 'Saturday'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFirstDayOfWeekDialog(config.firstDayOfWeek),
              );
            },
          ),

          if (_isLoadingAutoSave)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SwitchListTile(
              secondary: const Icon(Icons.save_as_outlined),
              title: const Text('Auto-save Entries'),
              subtitle: const Text('Save changes to entries automatically as you write.'),
              value: _isAutoSaveEnabled,
              onChanged: _setAutoSaveEnabled,
            ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          
          if (_isLoadingNotifications)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Get Daily Reminders'),
                  subtitle: const Text('Gentle reminders to log your day in your journal.'),
                  value: _isNotificationsEnabled,
                  onChanged: (bool value) async {
                    // Optimistically update UI
                    setState(() {
                      _isNotificationsEnabled = value;
                    });
                    
                    // Attempt to set it (which requests permissions if enabling)
                    await NotificationService().setDailyRemindersEnabled(value);
                    
                    // Re-sync with actual state (in case permission was denied)
                    final actuallyEnabled = await NotificationService().isDailyRemindersEnabled();
                    if (mounted && actuallyEnabled != _isNotificationsEnabled) {
                      setState(() {
                        _isNotificationsEnabled = actuallyEnabled;
                      });
                      
                      // If user tried to enable it, but it failed (likely permanently denied by OS)
                      if (value == true && actuallyEnabled == false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Notifications are blocked in device settings.'),
                            persist: false,
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'Settings',
                              onPressed: () => openAppSettings(),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          
          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Account & Security',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          
          if (user != null)
            // Change password / Set new password
            if (hasPasswordProvider)
              // Change password for email/password users
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangePasswordDialog(context, isNew: false),
              )
            else 
              // Set password for existing google account users
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Set Password'),
                subtitle: const Text('Enable Email/Password login for this account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangePasswordDialog(context, isNew: true),
              ),

          // Connect Google account
          ListTile(
            leading: _isLinkingGoogle
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : SvgPicture.asset('assets/icons/google_logo.svg', height: 20),
            title: const Text('Google Account'),
            subtitle: Text(
              hasGoogleProvider
                ? 'Connected'
                : 'Sign in faster with Google'),
            trailing: hasGoogleProvider
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right),
            onTap: hasGoogleProvider || _isLinkingGoogle ? null : _linkGoogleAccount,
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'App Information',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Current Version', maxLines: 1),
            subtitle: Text(versionState.currentVersion),
            trailing: versionState.isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    onPressed: () => ref.read(appVersionProvider.notifier).checkForUpdates(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Check Updates'),
                  ),
          ),

          if (versionState.statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: versionState.apkDownloadUrl != null
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: versionState.apkDownloadUrl != null
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          versionState.apkDownloadUrl != null
                              ? Icons.system_update_outlined
                              : Icons.check_circle_outline,
                          color: versionState.apkDownloadUrl != null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            versionState.statusMessage!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: versionState.apkDownloadUrl != null
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (versionState.apkDownloadUrl != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _launchUrl(versionState.apkDownloadUrl!),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Update Now'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
    );
  }
}