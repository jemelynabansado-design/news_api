import 'package:flutter/material.dart';
import '../services/news_services.dart';
import '../models/article_model.dart';
import '../widgets/news_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _loading = true;
  String _selectedCategory = 'general';
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    _loadNews();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadNews() async {
    setState(() => _loading = true);
    _animationController.reset();
    _articles = await _newsService.fetchNews(_selectedCategory);
    setState(() => _loading = false);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final headerOpacity = (1 - (_scrollOffset / 100)).clamp(0.0, 1.0);
    final headerScale = (1 - (_scrollOffset / 500)).clamp(0.85, 1.0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1E),
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: ScrollConfiguration(
            behavior: ScrollBehavior().copyWith(scrollbars: false),
            child: RawScrollbar(
              controller: _scrollController,
              thickness: 10,
              radius: const Radius.circular(12),
              thumbColor: const Color(0xFF00F5FF).withOpacity(0.7),
              thumbVisibility: true,
              trackColor: Colors.black.withOpacity(0.2),
              trackRadius: const Radius.circular(12),
              trackBorderColor: const Color(0xFF00F5FF).withOpacity(0.3),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Glassmorphic Header
                  SliverToBoxAdapter(
                    child: Opacity(
                      opacity: headerOpacity,
                      child: Transform.scale(
                        scale: headerScale,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00F5FF),
                                      Color(0xFF00A8FF),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00F5FF,
                                      ).withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF00F5FF),
                                        Color(0xFFFFFFFF),
                                        Color(0xFF00A8FF),
                                      ],
                                    ).createShader(bounds),
                                child: const Text(
                                  'ByteNews',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stay Informed, Stay Ahead',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Category
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF00F5FF).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F5FF).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F5FF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F5FF),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'GENERAL NEWS',
                              style: TextStyle(
                                color: Color(0xFF00F5FF),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // News List
                  _loading
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF00F5FF,
                                        ).withOpacity(0.2),
                                        const Color(
                                          0xFF00A8FF,
                                        ).withOpacity(0.2),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00F5FF,
                                        ).withOpacity(0.3),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF00F5FF),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFF00F5FF),
                                          Color(0xFFFFFFFF),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Loading Stories',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return FadeTransition(
                                opacity: Tween<double>(begin: 0.0, end: 1.0)
                                    .animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Interval(
                                          (index / _articles.length) * 0.3,
                                          ((index + 1) / _articles.length) *
                                                  0.3 +
                                              0.7,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                    ),
                                child: SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(0, 0.15),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(
                                            (index / _articles.length) * 0.3,
                                            ((index + 1) / _articles.length) *
                                                    0.3 +
                                                0.7,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      ),
                                  child: Transform.rotate(
                                    angle: (index % 2 == 0 ? -0.01 : 0.01),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 20,
                                      ),
                                      child: NewsCard(
                                        article: _articles[index],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }, childCount: _articles.length),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}