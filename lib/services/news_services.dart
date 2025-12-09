import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class NewsService {
  final String apiKey = '';

  Future<List<Article>> fetchNews(String category) async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything?domains=wsj.com&apiKey=3dd478239dce43c6a431206096b215c2',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Article> articles = [];

      for (var element in data['articles']) {
        articles.add(Article.fromJson(element));
      }

      return articles;
    } else {
      throw Exception('Failed to load news');
    }
  }
}

