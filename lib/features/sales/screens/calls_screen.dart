import 'dart:io';

import 'package:call_log/call_log.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toggle_timer/config/colors/app_colors.dart';
import 'package:toggle_timer/config/typography/app_typography.dart';
import 'package:toggle_timer/core/utils/app_prompts.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/common_widgets/custom_text_field.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key, required this.phone});
  final String phone;

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  // Android specific
  List<CallLogEntry> _callLogs = [];
  List<CallLogEntry> _filteredCallLogs = [];
  CallType? _selectedCallType;

  // iOS specific
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];

  // Common
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final bool _isAndroid = Platform.isAndroid;
  final bool _isIOS = Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      _checkPermissionsAndLoadCallLogs();
    } else if (_isIOS) {
      _checkPermissionsAndLoadContacts();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to normalize phone numbers for comparison
  String _normalizePhoneNumber(String? number) {
    if (number == null) return '';
    // Remove all non-digit characters
    return number.replaceAll(RegExp(r'[^\d]'), '');
  }

  bool _isPhoneNumberMatch(String? number1, String number2) {
    if (number1 == null) return false;
    final normalized1 = _normalizePhoneNumber(number1);
    final normalized2 = _normalizePhoneNumber(number2);

    // Check if the normalized numbers contain each other (handles different formats)
    return normalized1.contains(normalized2) || normalized2.contains(normalized1);
  }

  // iOS Contact Methods
  Future<void> _checkPermissionsAndLoadContacts() async {
    setState(() => _isLoading = true);

    PermissionStatus status = await Permission.contacts.request();

    if (status.isGranted) {
      await _loadContacts();
    } else if (status.isPermanentlyDenied) {
      setState(() => _isLoading = false);
      _showPermissionDialog();
    } else {
      setState(() => _isLoading = false);
      AppPrompts.showError(message: 'Contacts permission is required to view contacts.');
    }
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await FastContacts.getAllContacts();
      setState(() {
        _contacts = contacts;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AppPrompts.showError(message: 'Failed to load contacts: $e');
    }
  }

  // Android Call Log Methods
  Future<void> _checkPermissionsAndLoadCallLogs() async {
    setState(() => _isLoading = true);

    PermissionStatus status = await Permission.phone.request();

    if (status.isGranted) {
      await _loadCallLogs();
    } else if (status.isPermanentlyDenied) {
      setState(() => _isLoading = false);
      _showPermissionDialog();
    } else {
      setState(() => _isLoading = false);
      AppPrompts.showError(message: 'Call log permission is required to view call history.');
    }
  }

  Future<void> _loadCallLogs() async {
    try {
      Iterable<CallLogEntry> entries = await CallLog.get();
      setState(() {
        _callLogs = entries.toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AppPrompts.showError(message: 'Failed to load call logs: $e');
    }
  }

  void _applyFilters() {
    if (_isAndroid) {
      _applyAndroidFilters();
    } else if (_isIOS) {
      _applyIOSFilters();
    }
  }

  void _applyAndroidFilters() {
    List<CallLogEntry> filtered = List.from(_callLogs);

    // First filter by the phone number from argument
    if (widget.phone.isNotEmpty) {
      filtered = filtered.where((call) {
        return _isPhoneNumberMatch(call.number, widget.phone);
      }).toList();
    }

    // Then apply call type filter if selected
    if (_selectedCallType != null) {
      filtered = filtered.where((call) => call.callType == _selectedCallType).toList();
    }

    // Then apply search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((call) {
        final name = call.name?.toLowerCase() ?? '';
        final number = call.number?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || number.contains(query);
      }).toList();
    }

    filtered.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

    setState(() => _filteredCallLogs = filtered);
  }

  void _applyIOSFilters() {
    List<Contact> filtered = List.from(_contacts);

    // First filter by the phone number from argument
    if (widget.phone.isNotEmpty) {
      filtered = filtered.where((contact) {
        return contact.phones.any((phone) => _isPhoneNumberMatch(phone.number, widget.phone));
      }).toList();
    }

    // Then apply search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((contact) {
        final name = contact.displayName.toLowerCase();
        final hasMatchingPhone = contact.phones.any(
          (phone) => phone.number.toLowerCase().contains(_searchQuery.toLowerCase()),
        );
        final hasMatchingEmail = contact.emails.any(
          (email) => email.address.toLowerCase().contains(_searchQuery.toLowerCase()),
        );
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || hasMatchingPhone || hasMatchingEmail;
      }).toList();
    }

    // Sort by display name
    filtered.sort((a, b) => a.displayName.compareTo(b.displayName));

    setState(() => _filteredContacts = filtered);
  }

  void _showPermissionDialog() => showDialog(
    context: context,
    builder: (context) => Platform.isIOS
        ? CupertinoAlertDialog(
            title: const Text('Permission Required'),
            content: Text(
              _isAndroid
                  ? 'Call log permission is needed to display your call history. Please enable it in app settings.'
                  : 'Contacts permission is needed to display your contacts. Please enable it in app settings.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          )
        : AlertDialog(
            title: const Text('Permission Required'),
            content: Text(
              _isAndroid
                  ? 'Call log permission is needed to display your call history. Please enable it in app settings.'
                  : 'Contacts permission is needed to display your contacts. Please enable it in app settings.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
  );

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '--:--';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  IconData _getCallTypeIcon(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  Color _getCallTypeColor(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
      default:
        return AppColors.kAppGrey;
    }
  }

  String _getPrimaryPhoneNumber(Contact contact) {
    if (contact.phones.isEmpty) return 'No phone number';
    return contact.phones.first.number;
  }

  String _getPrimaryEmail(Contact contact) {
    if (contact.emails.isEmpty) return '';
    return contact.emails.first.address;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: AppUtils.gradientFlexibleSpace(),
      title: Text(_isIOS ? 'Contacts for ${widget.phone}' : 'Calls for ${widget.phone}'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.kAppBackground.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Search bar using CustomTextField
              CustomTextField(
                controller: _searchController,
                hintText: _isIOS ? 'Search contacts...' : 'Search by name or number...',
                prefixIcon: const Icon(Icons.search, color: AppColors.kAppGrey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.kAppGrey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
                onChanged: (value) => setState(() {
                  _searchQuery = value;
                  _applyFilters();
                }),
                fillColor: AppColors.kAppGrey.withOpacity(0.1),
              ),
              const SizedBox(height: 12),
              // Call type filter chips (Android only)
              if (_isAndroid) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Incoming', CallType.incoming),
                      const SizedBox(width: 8),
                      _buildFilterChip('Outgoing', CallType.outgoing),
                      const SizedBox(width: 8),
                      _buildFilterChip('Missed', CallType.missed),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    body: _buildBody(),
  );

  Widget _buildFilterChip(String label, CallType? type) {
    final isSelected = _selectedCallType == type;
    return FilterChip(
      label: Text(
        label,
        style: AppTypography.style14SemiBold.copyWith(color: isSelected ? AppColors.kAppWhite : AppColors.kAppGrey),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _selectedCallType = type;
        _applyFilters();
      }),
      backgroundColor: AppColors.kAppBackground,
      selectedColor: AppColors.kAppPrimary,
      checkmarkColor: AppColors.kAppWhite,
      side: BorderSide(color: AppColors.kAppGrey.withOpacity(0.3)),
    );
  }

  Widget _buildBody() {
    if (!_isAndroid && !_isIOS) {
      return _buildPlatformNotSupported();
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.kAppPrimary));
    }

    if (_isAndroid) {
      return _buildAndroidCallLogs();
    } else {
      return _buildIOSContacts();
    }
  }

  Widget _buildAndroidCallLogs() {
    if (_filteredCallLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_callLogs.isEmpty ? Icons.history : Icons.search_off, size: 64, color: AppColors.kAppGrey),
            const SizedBox(height: 16),
            Text(
              _callLogs.isEmpty
                  ? 'No call logs found for ${widget.phone}'
                  : 'No matching calls found for ${widget.phone}',
              style: AppTypography.style16Regular.copyWith(color: AppColors.kAppGrey),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.kAppBackground,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredCallLogs.length,
        itemBuilder: (context, index) {
          final call = _filteredCallLogs[index];
          final date = DateTime.fromMillisecondsSinceEpoch(call.timestamp ?? 0);
          final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.kAppWhite.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kAppGrey.withOpacity(0.1)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCallTypeColor(call.callType).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getCallTypeIcon(call.callType), color: _getCallTypeColor(call.callType), size: 20),
              ),
              title: Text(
                call.name ?? call.number ?? 'Unknown',
                style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppWhite),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (call.name != null && call.number != null)
                    Text(call.number!, style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey)),
                  Text(
                    formattedDate,
                    style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey.withOpacity(0.7)),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(call.duration),
                    style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppWhite),
                  ),
                  if (call.callType == CallType.missed)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Missed', style: AppTypography.style10SemiBold.copyWith(color: Colors.red)),
                    ),
                ],
              ),
              onTap: () => _showCallDetailsDialog(call),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIOSContacts() {
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_contacts.isEmpty ? Icons.contacts : Icons.search_off, size: 64, color: AppColors.kAppGrey),
            const SizedBox(height: 16),
            Text(
              _contacts.isEmpty
                  ? 'No contacts found for ${widget.phone}'
                  : 'No matching contacts found for ${widget.phone}',
              style: AppTypography.style16Regular.copyWith(color: AppColors.kAppGrey),
            ),
            const SizedBox(height: 8),
            if (_contacts.isEmpty)
              Text(
                'Add contacts to get started',
                style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey.withOpacity(0.7)),
              ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.kAppBackground,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredContacts.length,
        itemBuilder: (context, index) {
          final contact = _filteredContacts[index];
          final primaryPhone = _getPrimaryPhoneNumber(contact);
          final primaryEmail = _getPrimaryEmail(contact);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.kAppWhite.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kAppGrey.withOpacity(0.1)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: AppColors.kAppPrimary.withOpacity(0.2),
                child: Text(
                  contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
                  style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppPrimary),
                ),
              ),
              title: Text(
                contact.displayName,
                style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppWhite),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(primaryPhone, style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey)),
                  if (primaryEmail.isNotEmpty)
                    Text(
                      primaryEmail,
                      style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey.withOpacity(0.7)),
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.kAppGrey),
                color: AppColors.kAppBackground,
                onSelected: (value) {
                  if (value == 'call') {
                    _launchPhone(primaryPhone);
                  } else if (value == 'message') {
                    _launchSMS(primaryPhone);
                  } else if (value == 'email' && primaryEmail.isNotEmpty) {
                    _launchEmail(primaryEmail);
                  }
                },
                itemBuilder: (context) => [
                  if (primaryPhone != 'No phone number')
                    PopupMenuItem(
                      value: 'call',
                      child: Row(
                        children: [
                          Icon(Icons.call, color: AppColors.kAppPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text('Call', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite)),
                        ],
                      ),
                    ),
                  if (primaryPhone != 'No phone number')
                    PopupMenuItem(
                      value: 'message',
                      child: Row(
                        children: [
                          Icon(Icons.message, color: AppColors.kAppPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text('Message', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite)),
                        ],
                      ),
                    ),
                  if (primaryEmail.isNotEmpty)
                    PopupMenuItem(
                      value: 'email',
                      child: Row(
                        children: [
                          Icon(Icons.email, color: AppColors.kAppPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text('Email', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite)),
                        ],
                      ),
                    ),
                ],
              ),
              onTap: () => _showContactDetailsDialog(contact),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        AppPrompts.showError(message: 'Could not launch phone app');
      }
    } catch (e) {
      AppPrompts.showError(message: e.toString());
    }
  }

  Future<void> _launchSMS(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        AppPrompts.showError(message: 'Could not launch messaging app');
      }
    } catch (e) {
      AppPrompts.showError(message: e.toString());
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        AppPrompts.showError(message: 'Could not launch email app');
      }
    } catch (e) {
      AppPrompts.showError(message: e.toString());
    }
  }

  Widget _buildPlatformNotSupported() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isIOS ? Icons.phone_iphone : Icons.phone_android,
              size: 80,
              color: AppColors.kAppGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Not Available',
              style: AppTypography.style24SemiBold.copyWith(color: AppColors.kAppWhite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getPlatformMessage(),
              style: AppTypography.style16Regular.copyWith(color: AppColors.kAppGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildAlternativeOptions(),
          ],
        ),
      ),
    );
  }

  String _getPlatformMessage() {
    if (Platform.isWindows) {
      return 'This feature is not available on Windows platform.';
    } else if (Platform.isMacOS) {
      return 'This feature is not available on macOS platform.';
    } else if (Platform.isLinux) {
      return 'This feature is not available on Linux platform.';
    } else {
      return 'This feature is only available on Android and iOS devices.';
    }
  }

  Widget _buildAlternativeOptions() => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.kAppWhite.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.kAppGrey.withOpacity(0.1)),
    ),
    child: Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.kAppPrimary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.call, color: AppColors.kAppPrimary),
          ),
          title: Text('Open Dialer', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppWhite)),
          subtitle: Text(
            'Open the dialer to make a call',
            style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey),
          ),
          onTap: () async {
            try {
              await launchUrl(Uri.parse('tel:1234567890'));
            } catch (e) {
              AppPrompts.showError(message: e.toString());
            }
          },
        ),
        if (Platform.isIOS)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.kAppPrimary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.contacts, color: AppColors.kAppPrimary),
            ),
            title: Text('Add Contacts', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppWhite)),
            subtitle: Text(
              'Add contacts to your device',
              style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey),
            ),
            onTap: () {
              AppPrompts.showInfo(message: 'Please add contacts through the Contacts app on your device');
            },
          ),
      ],
    ),
  );

  void _showCallDetailsDialog(CallLogEntry call) {
    final date = DateTime.fromMillisecondsSinceEpoch(call.timestamp ?? 0);
    final formattedDate = DateFormat('MMMM dd, yyyy');
    final formattedTime = DateFormat('hh:mm:ss a');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.kAppBackground,
        title: Text('Call Details', style: AppTypography.style20SemiBold.copyWith(color: AppColors.kAppWhite)),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name:', call.name ?? 'Unknown'),
              const Divider(color: AppColors.kAppGrey),
              _buildDetailRow('Number:', call.number ?? 'Unknown'),
              const Divider(color: AppColors.kAppGrey),
              _buildDetailRow('Type:', call.callType.toString().split('.').last),
              const Divider(color: AppColors.kAppGrey),
              _buildDetailRow('Date:', formattedDate.format(date)),
              const Divider(color: AppColors.kAppGrey),
              _buildDetailRow('Time:', formattedTime.format(date)),
              const Divider(color: AppColors.kAppGrey),
              _buildDetailRow('Duration:', _formatDuration(call.duration)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppGrey)),
          ),
          if (call.number != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _launchPhone(call.number!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kAppPrimary,
                foregroundColor: AppColors.kAppWhite,
              ),
              child: const Text('Call'),
            ),
        ],
      ),
    );
  }

  void _showContactDetailsDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.kAppBackground,
        title: Text(contact.displayName, style: AppTypography.style20SemiBold.copyWith(color: AppColors.kAppWhite)),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact.phones.isNotEmpty) ...[
                Text('Phone Numbers', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppPrimary)),
                const SizedBox(height: 8),
                ...contact.phones.map(
                  (phone) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: AppColors.kAppGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phone.number,
                                style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite),
                              ),
                              Text(
                                phone.label,
                                style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (contact.emails.isNotEmpty) ...[
                const Divider(color: AppColors.kAppGrey),
                Text('Emails', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppPrimary)),
                const SizedBox(height: 8),
                ...contact.emails.map(
                  (email) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.email, size: 16, color: AppColors.kAppGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email.address,
                                style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite),
                              ),
                              Text(
                                email.label,
                                style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (contact.organization != null) ...[
                const Divider(color: AppColors.kAppGrey),
                Text('Organization', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppPrimary)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contact.organization!.company.isNotEmpty)
                        Text(
                          contact.organization!.company,
                          style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite),
                        ),
                      if (contact.organization!.department.isNotEmpty)
                        Text(
                          contact.organization!.department,
                          style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey),
                        ),
                      if (contact.organization!.jobDescription.isNotEmpty)
                        Text(
                          contact.organization!.jobDescription,
                          style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppGrey)),
          ),
          if (contact.phones.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _launchPhone(contact.phones.first.number);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kAppPrimary,
                foregroundColor: AppColors.kAppWhite,
              ),
              child: const Text('Call'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppGrey)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value, style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite)),
        ),
      ],
    ),
  );
}
