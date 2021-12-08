import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final articleRepository = Provider<ArticleRepository>(
  (ref) => FakeArticleRepository(),
);

final articlesProvider = FutureProvider<List<Article>>((ref) async {
  return ref.watch(articleRepository).fetchArticles();
});

abstract class ArticleRepository {
  Future<List<Article>> fetchArticles();
}

bool error = true;

class FakeArticleRepository implements ArticleRepository {
  @override
  Future<List<Article>> fetchArticles() {
    if (error) {
      return Future.delayed(
        const Duration(milliseconds: 500),
        () {
          return Future.error('Oops');
        },
      );
    }
    return Future.delayed(
      const Duration(milliseconds: 500),
      () {
        return [
          Article("Article 1", 1),
          Article("Article 2", 2),
          Article("Article 3", 3),
          Article("Article 4", 4),
          Article("Article 5", 5),
          Article("Article 6", 6),
          Article("Article 7", 7),
        ];
      },
    );
  }
}

class Article {
  final String name;
  final int id;

  Article(this.name, this.id);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: MaterialApp(
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  List<Article>? currentSetOfArticles;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Article>> articles = ref.watch(articlesProvider);
    ref.listen(articlesProvider, (_, AsyncValue<List<Article>> next) {
      if (next.value != null) {
        setState(() {
          currentSetOfArticles = next.value!;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Listen'),
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
              child: const Text('Refresh'),
              onPressed: () {
                ref.refresh(articlesProvider);
              },
            ),
            TextButton(
              child: Text('Toggle error: $error'),
              onPressed: () {
                setState(() {
                  error = !error;
                });
              },
            ),
            articles.when(
              data: (List<Article> articles) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: articles.map<Text>((Article article) {
                    return Text(article.name);
                  }).toList(),
                );
              },
              loading: () {
                return Column(
                  children: [
                    const CircularProgressIndicator(),
                    if (currentSetOfArticles != null)
                      ...currentSetOfArticles!.map<Text>((Article article) {
                        return Text(article.name);
                      }).toList(),
                  ],
                );
              },
              error: (Object error, StackTrace? stackTrace) {
                return Column(
                  children: [
                    Text(error.toString()),
                    if (currentSetOfArticles != null)
                      ...currentSetOfArticles!.map<Text>((Article article) {
                        return Text(article.name);
                      }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
