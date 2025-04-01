import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  const TranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nindogo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.notoSansJpTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TranslatorHome()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/nindogofix.png',
                  width: 180,
                  height: 180,
                ),
              ),
              const Spacer(),
              Text(
                '© 2025 vinsensius13',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class TranslatorHome extends StatefulWidget {
  const TranslatorHome({super.key});

  @override
  State<TranslatorHome> createState() => _TranslatorHomeState();
}

class _TranslatorHomeState extends State<TranslatorHome> {
  final TextEditingController _controller = TextEditingController();
  String translatedText = '';
  String sourceLang = 'id';
  String targetLang = 'ja';
  String sourceFlag = '🇮🇩';
  String targetFlag = '🇯🇵';
  bool isLoading = false;

  void swapLanguage() {
    setState(() {
      final tempLang = sourceLang;
      sourceLang = targetLang;
      targetLang = tempLang;

      sourceFlag = sourceLang == 'id' ? '🇮🇩' : '🇯🇵';
      targetFlag = targetLang == 'ja' ? '🇯🇵' : '🇮🇩';

      translatedText = '';
      _controller.clear();
    });
  }

  String handleTimeInput(String input) {
    if (input.contains(":")) {
      final parts = input.split(":");
      if (parts.length == 2 && int.tryParse(parts[0]) != null && int.tryParse(parts[1]) != null) {
        return input;
      }
    }
    return input.toString();
  }

  Future<void> translateAndAnalyze() async {
    if (_controller.text.trim().isEmpty) return;

    final inputText = handleTimeInput(_controller.text);
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://transapi-2sgz.onrender.com/translate_and_analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': inputText,
          'src': sourceLang,
          'dest': targetLang,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        translatedText = data['translated_text'] ?? 'Gagal menerjemahkan';
      });
    } catch (e) {
      setState(() => translatedText = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: const Text('Nindogo'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sourceFlag, style: const TextStyle(fontSize: 28)),
                    IconButton(
                      icon: const Icon(Icons.compare_arrows, color: Colors.white),
                      onPressed: swapLanguage,
                    ),
                    Text(targetFlag, style: const TextStyle(fontSize: 28)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Insert text',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : translateAndAnalyze,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                    if (translatedText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          translatedText,
                          style: const TextStyle(fontSize: 18),
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}