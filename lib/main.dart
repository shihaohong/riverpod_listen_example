import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final articleRepository = Provider<ArticleRepository>(
  (ref) => FakeArticleRepository(),
);

// the future provider for the list of articles.
final articlesProvider = FutureProvider<List<Article>>((ref) async {
  return ref.watch(articleRepository).fetchArticles();
});

// the state provider that caches the list of articles for loading state.
final cachedArticlesProvider = StateProvider<List<Article>?>((ref) => null);

abstract class ArticleRepository {
  Future<List<Article>> fetchArticles();
}

// controls whether the future should return an error or data.
// can adjust the initial value to test different cases.
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
  @override
  Widget build(BuildContext context) {
    ref.listen(
      articlesProvider,
      (_, AsyncValue<List<Article>> next) {
        // when there's a new, non-error value that is non-null, save it to the
        // cached state.
        if (next.value != null) {
          ref.watch(cachedArticlesProvider.state).state = next.value!;
        }
      },
    );
    final currentSetOfArticles = ref.watch(cachedArticlesProvider);

    final AsyncValue<List<Article>> articles = ref.watch(articlesProvider);
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
            // We still want the flutter UI to respond to the [FutureProvider]'s
            // [AsyncValue]'s state.
            // however, we ultimately want to show the value of
            // the cached data, so we use that state to represent
            articles.when(
              data: (_) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: currentSetOfArticles!.map<Text>((Article article) {
                    return Text(article.name);
                  }).toList(),
                );
              },
              loading: () {
                return Column(
                  children: [
                    const CircularProgressIndicator(),
                    // [currentSetOfArticles] can be null on initial load
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
                    // [currentSetOfArticles] can be null on initial load
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
