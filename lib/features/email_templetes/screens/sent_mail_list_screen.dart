import 'package:flutter/material.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';

import '../../../config/colors/app_colors.dart';
import '../../../core/helper/app_helper.dart';
import '../../home/widgets/app_drawer.dart';
import '../controller/sent_mail_controller.dart';
import '../models/sent_mail_model.dart';

class SentMailListScreen extends StatefulWidget {
  const SentMailListScreen({super.key});

  @override
  State<SentMailListScreen> createState() => _SentMailListScreenState();
}

class _SentMailListScreenState extends State<SentMailListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<SentMailModel> sentMails = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSentMails();
  }

  Future<void> loadSentMails() async {
    setState(() => loading = true);
    sentMails = await SentMailController.getSentMails();
    setState(() => loading = false);
  }

  String _formatDate(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return "${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _mailPreview(SentMailModel mail) {
    final previewText = """
From: ${mail.fromName} <${mail.fromEmail}>
To: ${mail.toEmail}${mail.ccEmail.isNotEmpty ? "\nCC: ${mail.ccEmail}" : ""}${mail.bccEmail.isNotEmpty ? "\nBCC: ${mail.bccEmail}" : ""}
Subject: ${mail.subject}

${mail.body}

${mail.signature}
""";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .40),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(mail.sentAt),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            previewText.trim(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.kAppBackground,
      appBar: AppBar(
        title: const Text("Sent Mails"),
        flexibleSpace: AppUtils.gradientFlexibleSpace(),
        leading: AppHelper.buildDrawerButton(_scaffoldKey),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.kAppBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : sentMails.isEmpty
              ? const Center(
            child: Text(
              "No Sent Mails Found",
              style: TextStyle(color: Colors.white70),
            ),
          )
              : RefreshIndicator(
            onRefresh: loadSentMails,
            child: ListView.builder(
              itemCount: sentMails.length,
              itemBuilder: (_, index) {
                final mail = sentMails[index];
                return _mailPreview(mail);
              },
            ),
          ),
        ),
      ),
    );
  }
}
