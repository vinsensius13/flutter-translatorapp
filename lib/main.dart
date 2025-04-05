import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

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
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/nindogox.png',
                  width: 180,
                  height: 180,
                ),
              ),
              const Spacer(),
              Text(
                '2025 © akuma13',
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
  bool isPlayingAudio = false;
  final player = AudioPlayer();

  void swapLanguage() {
  setState(() {

    final tempLang = sourceLang;
    sourceLang = targetLang;
    targetLang = tempLang;

    sourceFlag = sourceLang == 'id' ? '🇮🇩' : '🇯🇵';
    targetFlag = targetLang == 'ja' ? '🇯🇵' : '🇮🇩';

    final tempText = _controller.text;
    _controller.text = translatedText;
    translatedText = tempText;
  });
  translateAndAnalyze();
}
  String handleTimeInput(String input) {
    if (input.contains(":")) {
      final parts = input.split(":");
      if (parts.length == 2 &&
          int.tryParse(parts[0]) != null &&
          int.tryParse(parts[1]) != null) {
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
        translatedText = data['translated_text'] ?? 'Failed to translate';
      });
    } catch (e) {
      setState(() => translatedText = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> playTTS() async {
    if (translatedText.trim().isEmpty) return;

    setState(() => isPlayingAudio = true);
    try {
      final response = await http.post(
        Uri.parse('https://transapi-2sgz.onrender.com/speak'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': translatedText,
          'src': targetLang,
          'dest': targetLang,
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await player.play(BytesSource(bytes));
      } else {
        debugPrint('Failed to play audio: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saat play TTS: $e');
    } finally {
      setState(() => isPlayingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 129, 77, 250),
        elevation: 4,
        shadowColor: Colors.indigo,
        title: Image.asset('assets/images/iconlogo.png', height: 38),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sourceFlag, style: const TextStyle(fontSize: 30)),
                IconButton(
                  icon: const Icon(Icons.compare_arrows, size: 28),
                  onPressed: swapLanguage,
                ),
                Text(targetFlag, style: const TextStyle(fontSize: 30)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Input text here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : translateAndAnalyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 129, 77, 250),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Translate', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 24),
            if (translatedText.isNotEmpty)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.indigo.shade100),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        translatedText,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: 'ttsBtn',
                            onPressed: isPlayingAudio ? null : playTTS,
                            backgroundColor: const Color.fromARGB(255, 129, 77, 250),
                            child: isPlayingAudio
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Icon(Icons.volume_up, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          FloatingActionButton(
                            heroTag: 'copyBtn',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: translatedText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard!')),
                              );
                            },
                            backgroundColor: const Color.fromARGB(255, 129, 77, 250),
                            child: const Icon(Icons.copy, color: Colors.white),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
