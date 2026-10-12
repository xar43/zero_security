import 'package:get/get.dart';

import '../models/lead_model.dart';

class LeadController extends GetxController {
  final _leads = <LeadModel>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  List<LeadModel> get leads => _leads;

  @override
  void onInit() {
    super.onInit();
    fetchLeads();
  }

  Future<void> fetchLeads() async {
    try {
      _isLoading.value = true;
      _leads.value = await LeadModel.getAll();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> addLead(LeadModel lead) async {
    await lead.save();
    await fetchLeads(); // Refresh the list
  }

  Future<void> deleteLead(LeadModel lead) async {
    await lead.delete();
    await fetchLeads(); // Refresh the list
  }
}
