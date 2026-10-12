class EmailTemplateModel {
  final String id;
  final String title;

  final String fromName;
  final String fromEmail;

  final String toEmail;
  final String ccEmail;
  final String bccEmail;

  final String subject;
  final String body;

  final String signature;

  EmailTemplateModel({
    required this.id,
    required this.title,
    required this.fromName,
    required this.fromEmail,
    required this.toEmail,
    required this.ccEmail,
    required this.bccEmail,
    required this.subject,
    required this.body,
    required this.signature,
  });

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) {
    return EmailTemplateModel(
      id: json["id"] ?? "",
      title: json["title"] ?? "",

      fromName: json["fromName"] ?? "",
      fromEmail: json["fromEmail"] ?? "",

      toEmail: json["toEmail"] ?? "",
      ccEmail: json["ccEmail"] ?? "",
      bccEmail: json["bccEmail"] ?? "",

      subject: json["subject"] ?? "",
      body: json["body"] ?? "",

      signature: json["signature"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,

      "fromName": fromName,
      "fromEmail": fromEmail,

      "toEmail": toEmail,
      "ccEmail": ccEmail,
      "bccEmail": bccEmail,

      "subject": subject,
      "body": body,

      "signature": signature,
    };
  }
}
