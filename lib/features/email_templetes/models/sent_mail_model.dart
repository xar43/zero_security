class SentMailModel {
  final String id;
  final String templateId;

  final String fromName;
  final String fromEmail;
  final String toEmail;
  final String ccEmail;
  final String bccEmail;
  final String subject;
  final String body;
  final String signature;

  final int sentAt;

  SentMailModel({
    required this.id,
    required this.templateId,
    required this.fromName,
    required this.fromEmail,
    required this.toEmail,
    required this.ccEmail,
    required this.bccEmail,
    required this.subject,
    required this.body,
    required this.signature,
    required this.sentAt,
  });

  factory SentMailModel.fromJson(Map<String, dynamic> json) {
    return SentMailModel(
      id: json["id"],
      templateId: json["templateId"],
      fromName: json["fromName"],
      fromEmail: json["fromEmail"],
      toEmail: json["toEmail"],
      ccEmail: json["ccEmail"],
      bccEmail: json["bccEmail"],
      subject: json["subject"],
      body: json["body"],
      signature: json["signature"],
      sentAt: json["sentAt"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "templateId": templateId,
      "fromName": fromName,
      "fromEmail": fromEmail,
      "toEmail": toEmail,
      "ccEmail": ccEmail,
      "bccEmail": bccEmail,
      "subject": subject,
      "body": body,
      "signature": signature,
      "sentAt": sentAt,
    };
  }
}
