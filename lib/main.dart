import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bird_flutter/bird_flutter.dart';
import 'services/audio_service.dart';
import 'pages/mobile_layout.dart';
import 'pages/main_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(LoadingApp());
}

class LoadingApp extends StatefulWidget {
  @override
  State<LoadingApp> createState() => _LoadingAppState();
}

class _LoadingAppState extends State<LoadingApp> {
  AudioService? _audioService;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      final audioService = AudioService();
      await audioService.initialize();
      setState(() {
        _audioService = audioService;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: Colors.brown[900],
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.amber),
                SizedBox(height: 16),
                Text('Loading sounds...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: Colors.brown[900],
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Error: $_error', style: TextStyle(color: Colors.white)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _initializeAudio();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MyApp(audioService: _audioService!);
  }
}

class MyApp extends StatelessWidget {
  final AudioService audioService;

  const MyApp({Key? key, required this.audioService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MyHomePage(audioService: audioService),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final AudioService audioService;

  const MyHomePage({Key? key, required this.audioService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return $$ >> (context) {
      final bloc = HookBloc.useMemo(
        () => PlaybackBloc(audioService),
        [],
      );

      HookBloc.useDispose(bloc);

      return MobileSequencerLayout(bloc: bloc);
    };
  }
}
