import 'package:flutter/material.dart';
class Review {
  final String author;
  final int rate;
  final String review;


  Review({required this.author,
    required this.rate,
    required this.review});
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      author: json["author"],
      rate: json["rate"],
      review: json["review"],
    );
  }
}

