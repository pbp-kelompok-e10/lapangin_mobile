

import 'dart:convert';

List<FaqEntry> faqEntryFromJson(String str) => List<FaqEntry>.from(json.decode(str).map((x) => FaqEntry.fromJson(x)));

String faqEntryToJson(List<FaqEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class FaqEntry {
    String model;
    String pk;
    Fields fields;

    FaqEntry({
        required this.model,
        required this.pk,
        required this.fields,
    });

    factory FaqEntry.fromJson(Map<String, dynamic> json) => FaqEntry(
        model: json["model"],
        pk: json["pk"].toString(),
        fields: Fields.fromJson(json["fields"]),
    );

    Map<String, dynamic> toJson() => {
        "model": model,
        "pk": pk,
        "fields": fields.toJson(),
    };
}

class Fields {
    String question;
    String answer;
    String category;
    int? createdBy;
    DateTime createdAt;
    DateTime updatedAt;

    Fields({
        required this.question,
        required this.answer,
        required this.category,
        this.createdBy,
        required this.createdAt,
        required this.updatedAt,
    });

    factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        question: json["question"],
        answer: json["answer"],
        category: json["category"],
        createdBy: json["created_by"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "question": question,
        "answer": answer,
        "category": category,
        "created_by": createdBy,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
    };
}