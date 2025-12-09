import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/article_model.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final String _bookmarksKey = 'bookmarks_v1';
  bool _isBookmarked = false;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _ttsAvailable = true;

  @override
  void initState() {
    super.initState();
    _initTts();
    _checkIfBookmarked();
  }

  @override
  void dispose() {
    _stopTts();
    _flutterTts.stop();
    super.dispose();
  }

  // -------------------------
  // Text-to-speech helpers
  // -------------------------
  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((err) {
      setState(() => _isSpeaking = false);
    });

    // Try to set language; ignore errors
    _flutterTts.setLanguage("en-US").catchError((_) {
      _ttsAvailable = false;
    });
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.45);
  }

  Future<void> _speakArticle() async {
    if (!_ttsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TTS not available on this device')),
      );
      return;
    }

    final textToRead = [
      widget.article.title,
      widget.article.author.isNotEmpty ? 'By ${widget.article.author}' : null,
      widget.article.description,
      widget.article.content.isNotEmpty ? widget.article.content : null,
    ].whereType<String>().join(".\n\n");

    if (textToRead.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to read')),
      );
      return;
    }

    try {
      await _flutterTts.speak(textToRead);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS failed: $e')),
      );
    }
  }

  Future<void> _stopTts() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    setState(() => _isSpeaking = false);
  }

  // -------------------------
  // Bookmark helpers (SharedPreferences)
  // -------------------------
  Future<void> _checkIfBookmarked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_bookmarksKey) ?? [];
      final exists = stored.any((s) {
        try {
          final Map<String, dynamic> m = jsonDecode(s);
          return (m['url']?.toString() ?? '') == widget.article.url;
        } catch (_) {
          return false;
        }
      });
      setState(() => _isBookmarked = exists);
    } catch (_) {
      setState(() => _isBookmarked = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_bookmarksKey) ?? [];

    // Remove if exists
    final exists = stored.any((s) {
      try {
        final Map<String, dynamic> m = jsonDecode(s);
        return (m['url']?.toString() ?? '') == widget.article.url;
      } catch (_) {
        return false;
      }
    });

    if (exists) {
      final newList = stored.where((s) {
        try {
          final Map<String, dynamic> m = jsonDecode(s);
          return (m['url']?.toString() ?? '') != widget.article.url;
        } catch (_) {
          return true;
        }
      }).toList();
      await prefs.setStringList(_bookmarksKey, newList);
      setState(() => _isBookmarked = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from bookmarks')),
      );
    } else {
      // Save article as JSON map (uses same fields as your Article model)
      final Map<String, dynamic> map = {
        'source': {'id': widget.article.source.id, 'name': widget.article.source.name},
        'author': widget.article.author,
        'title': widget.article.title,
        'description': widget.article.description,
        'url': widget.article.url,
        'urlToImage': widget.article.urlToImage,
        'publishedAt': widget.article.publishedAt,
        'content': widget.article.content,
      };
      stored.insert(0, jsonEncode(map));
      await prefs.setStringList(_bookmarksKey, stored);
      setState(() => _isBookmarked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to bookmarks')),
      );
    }
  }

  // -------------------------
  // Share helper
  // -------------------------
  void _shareArticle() {
    final subject = widget.article.title;
    final text = '${widget.article.title}\n\nRead more: ${widget.article.url}';
    Share.share(text, subject: subject);
  }

  // -------------------------
  // Open URL helper
  // -------------------------
  Future<void> _openUrl() async {
    final uri = Uri.tryParse(widget.article.url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid link')));
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  // -------------------------
  // Copy link to clipboard helper
  // -------------------------
  Future<void> _copyLink() async {
    if (widget.article.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No link to copy')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: widget.article.url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  // -------------------------
  // Utility to safely show SnackBar (avoid calling when not mounted)
  // -------------------------
  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // -------------------------
  // Build UI (keeps your original look & layout)
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      // We keep your background Container and entire layout exactly as-is.
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Image with Cyberpunk Overlay (unchanged layout)
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00F5FF).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                // Share button (now functional)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F5FF).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5FF).withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    onPressed: _shareArticle,
                  ),
                ),

                // Bookmark button (new)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F5FF).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5FF).withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      await _toggleBookmark();
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Use CachedNetworkImage for fade-in / placeholder
                    if (article.urlToImage.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: article.urlToImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade900,
                          child: const Center(child: CircularProgressIndicator(color: Color(0xFF00F5FF))),
                        ),
                        errorWidget: (context, url, error) {
                          return Container(
                            color: Colors.grey.shade900,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              size: 60,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),

                    // Dark gradient overlay (unchanged)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0F0F1E).withOpacity(0.8),
                            const Color(0xFF0F0F1E),
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                    // Neon glow effect (unchanged)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00F5FF).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content (kept identical, though interactive bits added below)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5FF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFF00F5FF).withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F5FF).withOpacity(0.2),
                              blurRadius: 15,
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
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                article.source.name,
                                style: const TextStyle(
                                  color: Color(0xFF00F5FF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title with Gradient (unchanged)
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF00F5FF),
                            Colors.white,
                            Color(0xFF00A8FF),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          article.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Neon Divider
                      Container(
                        height: 3,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F5FF), Color(0xFF00A8FF)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F5FF).withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Author Info (if available)
                      if (article.author.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00F5FF),
                                      Color(0xFF00A8FF),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  article.author,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Description
                      Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.8,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Read Full Article Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F5FF), Color(0xFF00A8FF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F5FF).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _openUrl();
                            },
                            onLongPress: () async {
                              await _copyLink();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Read Full Article',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // TTS controls row
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A8FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: _isSpeaking ? _stopTts : _speakArticle,
                            icon: Icon(_isSpeaking ? Icons.stop_rounded : Icons.headphones_rounded),
                            label: Text(_isSpeaking ? 'Stop Reading' : 'Listen'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF00F5FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () {
                              _shareArticle();
                            },
                            icon: const Icon(Icons.share_rounded, color: Colors.white),
                            label: const Text('Share'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
