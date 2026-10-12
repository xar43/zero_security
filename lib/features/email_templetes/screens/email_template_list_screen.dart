import 'package:flutter/material.dart';

import '../../../config/colors/app_colors.dart';
import '../../../core/helper/app_helper.dart';
import '../../../core/utils/app_utils.dart';
import '../../home/widgets/app_drawer.dart';
import '../controller/email_template_controller.dart';
import '../models/email_template_model.dart';
import '../widgets/template_card.dart';
import 'add_edit_email_template_screen.dart';

class EmailTemplateListScreen extends StatefulWidget {
  const EmailTemplateListScreen({super.key});

  @override
  State<EmailTemplateListScreen> createState() =>
      _EmailTemplateListScreenState();
}

class _EmailTemplateListScreenState extends State<EmailTemplateListScreen> {
  List<EmailTemplateModel> templates = [];
  bool loading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  void initState() {
    super.initState();
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    setState(() => loading = true);

    templates = await EmailTemplateController.getTemplates();

    setState(() => loading = false);
  }

  Future<void> deleteTemplate(String id) async {
    await EmailTemplateController.deleteTemplate(id);
    loadTemplates();
  }

  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.kAppBackground,
        title: const Text(
          "Delete Template",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this template?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteTemplate(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> openAddEdit({EmailTemplateModel? template}) async {
    final result = await showAddEditEmailTemplateSheet(
      context,
      template: template,
    );

    if (result == true) {
      loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.kAppBackground,
      drawer: AppDrawer(),
      appBar: AppBar(
        title: const Text('Email Templates'),
        flexibleSpace: AppUtils.gradientFlexibleSpace(),
        leading: AppHelper.buildDrawerButton(_scaffoldKey),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kAppSecondary.withOpacity(.25),
        onPressed: () => openAddEdit(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: loading
              ? const Center(child: CircularProgressIndicator())
              : templates.isEmpty
              ? const Center(
            child: Text(
              "No Templates Found",
              style: TextStyle(color: Colors.white70),
            ),
          )
              : RefreshIndicator(
            onRefresh: loadTemplates,
            child: ListView.builder(
                padding: EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];

                return TemplateCard(
                  template: template,
                  onEdit: () => openAddEdit(template: template),
                  onDelete: () => confirmDelete(template.id),
                );
              },
            ),
            ),
    );
  }
}
