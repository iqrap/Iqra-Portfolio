import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

// pubspec.yaml dependencies: google_fonts, url_launcher, visibility_detector, font_awesome_flutter
// pubspec.yaml assets: - assets/profile.png.png

void main() {
  VisibilityDetectorController.instance.updateInterval = const Duration(
    milliseconds: 60,
  );
  runApp(const PortfolioApp());
}

// ───────────────────────── Design tokens ─────────────────────────
class C {
  static const primary = Color(0xFF0F6B5C);
  static const deep = Color(0xFF0A4A40);
  static const accent = Color(0xFF1CC8A6);
  static const tint = Color(0xFFE8F5F2);
  static const ink = Color(0xFF10201D);
  static const muted = Color(0xFF55655F);
  static const bg = Color(0xFFF7FAF9);
  static const line = Color(0xFFDDE8E4);
}

TextStyle head(double s, {Color c = C.ink, double h = 1.15}) =>
    GoogleFonts.sora(
      fontSize: s,
      fontWeight: FontWeight.w700,
      color: c,
      height: h,
      letterSpacing: -0.5,
    );
TextStyle body(
  double s, {
  Color c = C.muted,
  FontWeight w = FontWeight.w400,
  double h = 1.65,
}) => GoogleFonts.dmSans(fontSize: s, color: c, fontWeight: w, height: h);

Future<void> openUrl(String u) =>
    launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Iqra Pervez | Portfolio',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: C.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: C.primary),
      textTheme: GoogleFonts.dmSansTextTheme(),
    ),
    home: const PortfolioHome(),
  );
}

// ───────────────────────── Page ─────────────────────────
class PortfolioHome extends StatefulWidget {
  const PortfolioHome({super.key});
  @override
  State<PortfolioHome> createState() => _PortfolioHomeState();
}

class _PortfolioHomeState extends State<PortfolioHome> {
  static const names = [
    'Home',
    'About',
    'Experience',
    'Projects',
    'Skills',
    'Education',
    'Contact',
  ];
  final _scroll = ScrollController();
  final _scaffold = GlobalKey<ScaffoldState>();
  final _keys = List.generate(names.length, (_) => GlobalKey());
  final _active = ValueNotifier<int>(0);
  final _progress = ValueNotifier<double>(0);
  final _contactFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _wide = true;
  bool _sendingMessage = false;
  String? _contactStatus;
  bool? _contactSucceeded;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendContactMessage() async {
    if (!_contactFormKey.currentState!.validate()) return;

    setState(() {
      _sendingMessage = true;
      _contactStatus = null;
      _contactSucceeded = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://formspree.io/f/xoejglen'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'message': _messageController.text.trim(),
              '_subject': 'New portfolio contact message',
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      setState(() {
        _sendingMessage = false;
        _contactSucceeded =
            response.statusCode >= 200 && response.statusCode < 300;
        _contactStatus = _contactSucceeded!
            ? 'Thanks! Your message was sent. I’ll get back to you soon.'
            : 'Your message could not be sent. Please try again or email perveziqra9@gmail.com.';
      });

      if (_contactSucceeded!) {
        _contactFormKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _sendingMessage = false;
        _contactSucceeded = false;
        _contactStatus =
            'Sending timed out. Please check your connection and try again.';
      });
    } on http.ClientException catch (error) {
      debugPrint('Formspree request failed: $error');
      if (!mounted) return;
      setState(() {
        _sendingMessage = false;
        _contactSucceeded = false;
        _contactStatus = 'Could not connect. Please try again or email perveziqra9@gmail.com.';
      });
    } catch (error) {
      debugPrint('Contact form submission failed: $error');
      if (!mounted) return;
      setState(() {
        _sendingMessage = false;
        _contactSucceeded = false;
        _contactStatus =
            'Something went wrong while sending. Please try again.';
      });
    }
  }

  void _onScroll() {
    final max = _scroll.position.maxScrollExtent;
    _progress.value = max == 0 ? 0 : (_scroll.offset / max).clamp(0.0, 1.0);
    int a = 0;
    for (int i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.localToGlobal(Offset.zero).dy <= 200) a = i;
    }
    _active.value = a;
  }

  void _go(int i) {
    if (i == 0) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    final ctx = _keys[i].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _wide = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      key: _scaffold,
      endDrawer: _wide ? null : _drawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                _hero(),
                _section(1, _about()),
                _section(2, _experience(), tinted: true),
                _section(3, _projects()),
                _section(4, _skills(), tinted: true),
                _section(5, _education(), verticalPadding: _wide ? 36 : 28),
                _section(6, _contact(), verticalPadding: _wide ? 36 : 28),
                _footer(),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _nav()),
        ],
      ),
    );
  }

  // ── Layout helpers ──
  Widget _section(
    int i,
    Widget child, {
    bool tinted = false,
    double? verticalPadding,
  }) => Container(
    key: _keys[i],
    width: double.infinity,
    color: tinted ? Colors.white : null,
    padding: EdgeInsets.symmetric(
      horizontal: _wide ? 64 : 22,
      vertical: verticalPadding ?? (_wide ? 96 : 64),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: child,
      ),
    ),
  );

  Widget _title(String t, [String? sub]) => Reveal(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: head(_wide ? 40 : 30)),
        const SizedBox(height: 12),
        Container(
          height: 4,
          width: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [C.primary, C.accent]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(sub, style: body(16)),
          ),
        ],
        const SizedBox(height: 40),
      ],
    ),
  );

  Widget _split(Widget a, Widget b, {int fa = 1, int fb = 1}) => _wide
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: fa, child: a),
            const SizedBox(width: 48),
            Expanded(flex: fb, child: b),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [a, const SizedBox(height: 32), b],
        );

  /// Responsive grid with staggered reveal.
  Widget _grid(List<Widget> kids, {double min = 340}) => LayoutBuilder(
    builder: (_, c) {
      final cols = math.max(1, ((c.maxWidth + 20) / (min + 20)).floor());
      final w = (c.maxWidth - (cols - 1) * 20) / cols;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          for (int i = 0; i < kids.length; i++)
            SizedBox(
              width: w,
              child: Reveal(delay: 80 * (i % cols), child: kids[i]),
            ),
        ],
      );
    },
  );

  // ── Navigation ──
  Widget _nav() => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        color: Colors.white.withValues(alpha: 0.78),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _wide ? 64 : 20,
                vertical: 12,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _go(0),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [C.primary, C.accent],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('IP', style: head(14, c: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Text('Iqra Pervez', style: head(18, c: C.primary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_wide)
                    ValueListenableBuilder<int>(
                      valueListenable: _active,
                      builder: (_, a, _) => Row(
                        children: [
                          for (int i = 0; i < names.length; i++)
                            _NavItem(names[i], a == i, () => _go(i)),
                        ],
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => _scaffold.currentState?.openEndDrawer(),
                    ),
                ],
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _progress,
              builder: (_, p, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: math.max(p, 0.002),
                  child: Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [C.primary, C.accent]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _drawer() => Drawer(
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Iqra Pervez', style: head(22, c: C.primary)),
          const SizedBox(height: 20),
          for (int i = 0; i < names.length; i++)
            ListTile(
              title: Text(
                names[i],
                style: body(17, c: C.ink, w: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 250), () => _go(i));
              },
            ),
        ],
      ),
    ),
  );

  // ── Hero ──
  // Set to false if your photo has a background (it will be clipped inside the arch instead).
  static const bool _cutoutPhoto = true;

  Widget _hero() {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: C.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Pulse(),
                const SizedBox(width: 10),
                Text(
                  'Software Developer',
                  style: body(15, c: C.deep, w: FontWeight.w700, h: 1.2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        Reveal(
          delay: 120,
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Hi, I’m '),
                TextSpan(
                  text: 'Iqra',
                  style: TextStyle(color: C.primary),
                ),
              ],
            ),
            style: head(_wide ? 78 : 46, h: 1.05),
          ),
        ),
        const SizedBox(height: 22),
        Reveal(
          delay: 240,
          child: Text(
            'Full Stack Developer | Mobile & Web\nML Enthusiast',
            style: head(
              _wide ? 26 : 19,
              h: 1.4,
            ).copyWith(fontWeight: FontWeight.w500, letterSpacing: 0),
          ),
        ),
        const SizedBox(height: 20),
        Reveal(
          delay: 340,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              'I build modern and user-friendly applications that solve real problems. Passionate about technology, learning and creating impactful solutions.',
              style: body(17),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Reveal(
          delay: 440,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _Btn(
                'View My Projects',
                filled: true,
                icon: Icons.arrow_forward_rounded,
                onTap: () => _go(3),
              ),
              _Btn('Get in Touch', onTap: () => _go(6)),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Reveal(
          delay: 540,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 22,
            runSpacing: 16,
            children: const [
              _TechIcon(FontAwesomeIcons.react, 'React'),
              _TechIcon(FontAwesomeIcons.mobileScreenButton, 'React Native'),
              _TechIcon(FontAwesomeIcons.python, 'Python'),
              _TechIcon(FontAwesomeIcons.brain, 'TensorFlow'),
              _TechIcon(FontAwesomeIcons.fire, 'Firebase'),
              _TechIcon(FontAwesomeIcons.flutter, 'Flutter'),
            ],
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF1FAF7), C.tint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _Blobs()),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _wide ? 64 : 22,
              _wide ? 130 : 110,
              _wide ? 64 : 22,
              0,
            ),
            child: Center(
              child: ConstrainedBox(
                key: _keys[0],
                constraints: const BoxConstraints(maxWidth: 1180),
                child: _wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 80),
                              child: text,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(flex: 5, child: _heroImage()),
                        ],
                      )
                    : Column(
                        children: [
                          text,
                          const SizedBox(height: 40),
                          _heroImage(),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroImage() {
    final h = _wide ? 640.0 : 470.0, aw = _wide ? 400.0 : 290.0;
    return Reveal(
      delay: 250,
      dx: 0.06,
      dy: 0,
      child: SizedBox(
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // soft back blob
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: aw * 0.7,
                height: h * 0.6,
                decoration: BoxDecoration(
                  color: C.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(aw),
                    topRight: Radius.circular(aw * 0.25),
                  ),
                ),
              ),
            ),
            // arch behind the photo
            Positioned(
              right: _wide ? 10 : 0,
              bottom: 0,
              child: Container(
                width: aw,
                height: h * 0.8,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      C.accent.withValues(alpha: 0.28),
                      C.primary.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(aw / 2),
                    bottom: const Radius.circular(24),
                  ),
                ),
                child: _cutoutPhoto ? null : _photo(BoxFit.cover),
              ),
            ),
            if (_cutoutPhoto)
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: aw * 1.2,
                  height: h * 0.97,
                  child: _photo(BoxFit.contain),
                ),
              ),
            Positioned(
              top: _wide ? 50 : 20,
              right: 0,
              child: Bob(
                phase: 0.2,
                child: Transform.rotate(
                  angle: -0.14,
                  child: Text(
                    'Turning\nIdeas into\nSolutions ♡',
                    style: GoogleFonts.caveat(
                      fontSize: _wide ? 32 : 24,
                      color: C.primary,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo(BoxFit fit) => Image.asset(
    'assets/profile.png.png', // your photo: transparent PNG works best
    fit: fit,
    alignment: Alignment.bottomCenter,
    errorBuilder: (_, _, _) => Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: C.deep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text('IP', style: head(72, c: Colors.white)),
    ),
  );

  // ── About ──
  Widget _about() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title('About me'),
      _split(
        Reveal(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Building intelligent solutions with code.',
                style: head(24, c: C.primary),
              ),
              const SizedBox(height: 18),
              Text(
                'I develop web and mobile applications and integrate machine learning into real-world projects. From building full-stack systems to training models, I enjoy turning ideas into practical, user-friendly solutions.',
                style: body(16.5),
              ),
            ],
          ),
        ),
        Reveal(
          delay: 150,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [C.deep, C.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What sets me apart', style: head(20, c: Colors.white)),
                const SizedBox(height: 14),
                Text(
                  'I combine full-stack development with machine learning to build complete solutions, from designing user interfaces and developing APIs to training models and integrating them into applications.',
                  style: body(15.5, c: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 48),
      _grid(const [
        Counter(to: 1, label: 'Major AI project'),
        Counter(to: 4, suffix: '+', label: 'Academic projects'),
        Counter(to: 2, label: 'Industry roles'),
        Counter(to: 2027, label: 'Expected graduation'),
      ], min: 220),
    ],
  );

  // ── Experience (a real sequence, so a timeline fits) ──
  Widget _experience() {
    const jobs = [
      (
        'Digital Solutions Associate',
        'Ataraxy Developers',
        [
          'Developing cross-platform mobile apps in Flutter with clean architecture and responsive UI',
          'Working with clients to gather requirements and keep projects aligned',
          'Testing apps to ship high-quality, bug-free releases',
          'Contributing across the full software development lifecycle',
        ],
        ['Flutter', 'App testing', 'Client management'],
      ),
      (
        'WordPress & CRM Specialist',
        'Zaptic',
        [
          'Building and customizing WordPress sites for client branding and functionality',
          'Implementing CRM systems to streamline workflows and organize data',
          'Developing automation workflows that cut manual tasks',
        ],
        ['WordPress', 'CRM', 'Automation'],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Where I\'ve worked'),
        for (int i = 0; i < jobs.length; i++)
          Reveal(
            delay: 100,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: C.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: C.accent.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: Container(width: 2, color: C.line)),
                    ],
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < jobs.length - 1 ? 28 : 0,
                      ),
                      child: _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(jobs[i].$1, style: head(21)),
                            const SizedBox(height: 4),
                            Text(
                              jobs[i].$2,
                              style: body(
                                15.5,
                                c: C.primary,
                                w: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final p in jobs[i].$3)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 3),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: C.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        p,
                                        style: body(
                                          15,
                                          c: C.ink.withValues(alpha: 0.85),
                                          h: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [for (final t in jobs[i].$4) _Tag(t)],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Projects ──
  Widget _projects() {
    const extra = [
      (
        'Learn Hub System',
        '2025',
        'An educational platform for learning and resource sharing.',
        ['Web', 'Database'],
        Icons.school_rounded,
      ),
      (
        'FUSST Venue Booking',
        '2025',
        'A booking app to manage and reserve university venues efficiently.',
        ['Web', 'Booking'],
        Icons.event_available_rounded,
      ),
      (
        'Cognitive Metamorphic Cipher',
        '2025',
        'A data security project exploring adaptive cipher behavior for secure handling of information.',
        ['Security', 'Algorithms'],
        Icons.lock_rounded,
      ),
      (
        'Cinema Booking System',
        '2023',
        'A reservation system for booking movie tickets and managing cinema plans.',
        ['C++', 'OOP'],
        Icons.movie_rounded,
      ),
    ];
    final featuredText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Final year project',
          style: body(14, c: Colors.white70, w: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          'DermaScanAI: AI-powered skincare analysis',
          style: head(_wide ? 30 : 24, c: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Deep learning and computer vision analyze facial skin conditions (dryness, redness, oiliness, pores) from uploaded images. A CNN-based classifier and an AI ingredient scanner evaluate products against each user\'s skin profile.',
          style: body(15.5, c: Colors.white.withValues(alpha: 0.9)),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in [
              'Python',
              'TensorFlow',
              'React Native',
              'Firebase',
            ])
              _Tag(t, dark: true),
          ],
        ),
        const SizedBox(height: 24),
        // TODO: point to the real project link
        _Btn(
          'View project',
          icon: Icons.open_in_new_rounded,
          light: true,
          onTap: () => openUrl('https://github.com/iqrap/DermaScanAI'),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Selected work'),
        Reveal(
          child: Hover(
            lift: 4,
            builder: (_) => Container(
              padding: EdgeInsets.all(_wide ? 44 : 26),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [C.deep, C.primary, Color(0xFF149684)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: C.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: _wide
                  ? Row(
                      children: [
                        Expanded(flex: 6, child: featuredText),
                        const SizedBox(width: 40),
                        const Expanded(flex: 3, child: _ScanVisual()),
                      ],
                    )
                  : Column(
                      children: [
                        featuredText,
                        const SizedBox(height: 28),
                        const _ScanVisual(),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 56),
        Reveal(child: Text('More projects', style: head(22))),
        const SizedBox(height: 22),
        _grid([
          for (final p in extra)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: C.tint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(p.$5, color: C.primary, size: 22),
                      ),
                      const Spacer(),
                      Text(p.$2, style: body(13, w: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(p.$1, style: head(17)),
                  const SizedBox(height: 8),
                  Text(p.$3, style: body(14.5, h: 1.5)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final t in p.$4) _Tag(t)],
                  ),
                ],
              ),
            ),
        ], min: 500),
      ],
    );
  }

  // ── Skills ──
  Widget _skills() {
    const cats = [
      (
        'Mobile',
        Icons.phone_android_rounded,
        ['Flutter', 'React Native (Expo)', 'Java (Android)'],
      ),
      (
        'Web',
        Icons.language_rounded,
        ['React', 'TypeScript', 'Tailwind CSS', 'HTML', 'CSS'],
      ),
      (
        'Backend',
        Icons.dns_rounded,
        ['ASP.NET Core Web API', 'REST APIs', 'Node.js', 'Express.js'],
      ),
      ('Database', Icons.storage_rounded, ['SQL', 'Firebase', 'MongoDB']),
      (
        'Languages',
        Icons.code_rounded,
        ['JavaScript', 'Python', 'C#', 'Java', 'C++', 'dart'],
      ),
      (
        'ML / AI',
        Icons.psychology_rounded,
        [
          'Data cleaning',
          'Preprocessing',
          'Model training',
          'Model deployment',
        ],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Technical toolkit'),
        _grid([
          for (final c in cats)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(c.$2, color: C.accent, size: 26),
                      const SizedBox(width: 12),
                      Text(c.$1, style: head(18, c: C.primary)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final s in c.$3) _Tag(s)],
                  ),
                ],
              ),
            ),
        ], min: 340),
        const SizedBox(height: 40),
        Reveal(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Soft skills',
                style: body(15, c: C.ink, w: FontWeight.w700),
              ),
              for (final s in [
                'Problem solving',
                'Teamwork',
                'Communication',
                'Time management',
                'Adaptability',
              ])
                _Tag(s, outline: true),
            ],
          ),
        ),
      ],
    );
  }

  // ── Education ──
  Widget _education() {
    Widget edu(String yr, String deg, String uni) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              yr,
              style: body(13.5, c: C.primary, w: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(deg, style: head(16.5)),
            const SizedBox(height: 4),
            Text(uni, style: body(14)),
          ],
        ),
      ),
    );
    Widget win(String t, String d) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFF5A623),
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: head(16.5)),
                  const SizedBox(height: 6),
                  Text(d, style: body(14, h: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Education & achievements'),
        _split(
          Reveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Academic background', style: head(20)),
                const SizedBox(height: 18),
                edu(
                  '2023 to 2027',
                  'BS in Information Technology',
                  'Foundation University, current CGPA 3.00',
                ),
                edu(
                  '2020 to 2022',
                  'Intermediate in Computer Science (ICS)',
                  'Global College, grade B',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Reveal(
            delay: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Achievements', style: head(20)),
                const SizedBox(height: 18),
                win(
                  'Open House project exhibition',
                  'Presented a university project and explained its features and implementation to visitors and faculty.',
                ),
                win(
                  'Alibaba Cloud AI Hackathon',
                  'Gained hands-on experience in AI-based problem solving and building technology solutions.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Contact ──
  Widget _contact() => Reveal(
    child: Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.symmetric(
        horizontal: _wide ? 60 : 24,
        vertical: _wide ? 72 : 48,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [C.deep, C.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned(right: -80, top: -80, child: _circle(240, 0.07)),
          Positioned(left: -60, bottom: -90, child: _circle(200, 0.06)),
          Center(
            child: Column(
              children: [
                Text(
                  'Let\'s work together',
                  textAlign: TextAlign.center,
                  style: head(_wide ? 40 : 28, c: Colors.white),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    'I can help you build cross-platform mobile apps, responsive websites and robust backend APIs, and integrate AI/ML features into existing products.',
                    textAlign: TextAlign.center,
                    style: body(16.5, c: Colors.white.withValues(alpha: 0.85)),
                  ),
                ),
                const SizedBox(height: 36),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _contactFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _contactField(
                                  controller: _nameController,
                                  label: 'Your name',
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Please enter your name.'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _contactField(
                                  controller: _emailController,
                                  label: 'Your email',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _contactField(
                            controller: _nameController,
                            label: 'Your name',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Please enter your name.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _contactField(
                            controller: _emailController,
                            label: 'Your email',
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _contactField(
                          controller: _messageController,
                          label: 'Your message',
                          maxLines: 5,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter a message.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton.icon(
                            onPressed: _sendingMessage
                                ? null
                                : _sendContactMessage,
                            icon: _sendingMessage
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: C.primary,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                              _sendingMessage ? 'Sending...' : 'Send message',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: C.primary,
                              disabledForegroundColor: C.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 17,
                              ),
                              textStyle: body(
                                15,
                                c: C.primary,
                                w: FontWeight.w700,
                                h: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        if (_contactStatus != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _contactStatus!,
                            textAlign: TextAlign.center,
                            style: body(
                              14,
                              c: _contactSucceeded!
                                  ? const Color(0xFFC5F5E6)
                                  : const Color(0xFFFFD6D6),
                              w: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _Btn(
                      'LinkedIn',
                      icon: Icons.link_rounded,
                      onDark: true,
                      onTap: () => openUrl(
                        'https://www.linkedin.com/in/iqra-pervez-1a317136b/',
                      ),
                    ),
                    _Btn(
                      'GitHub',
                      icon: Icons.code_rounded,
                      onDark: true,
                      onTap: () => openUrl('https://github.com/iqrap'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _contactField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(
          label,
          style: body(14, c: Colors.white, w: FontWeight.w600, h: 1.2),
        ),
      ),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines > 1 ? maxLines : 1,
        textCapitalization: keyboardType == TextInputType.emailAddress
            ? TextCapitalization.none
            : maxLines > 1
            ? TextCapitalization.sentences
            : TextCapitalization.words,
        style: body(15, c: C.ink, h: 1.35),
        validator: validator,
        textAlignVertical: maxLines > 1
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        autofillHints: keyboardType == TextInputType.emailAddress
            ? const [AutofillHints.email]
            : maxLines == 1
            ? const [AutofillHints.name]
            : null,
        decoration: InputDecoration(
          hintText: keyboardType == TextInputType.emailAddress
              ? 'name@example.com'
              : maxLines > 1
              ? 'Write your message...'
              : 'Enter your name',
          hintStyle: body(14, c: C.muted.withValues(alpha: 0.75), h: 1.35),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          constraints: BoxConstraints(minHeight: maxLines > 1 ? 140 : 58),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: maxLines > 1 ? 16 : 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 2),
          ),
          errorMaxLines: 2,
        ),
      ),
    ],
  );

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  Widget _circle(double s, double a) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: a),
    ),
  );

  Widget _footer() => Container(
    width: double.infinity,
    color: C.ink,
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 10,
      children: [
        Text(
          '© 2026 Iqra Pervez. All rights reserved.',
          style: body(14, c: Colors.white60),
        ),
        TextButton.icon(
          onPressed: () => _go(0),
          icon: const Icon(
            Icons.arrow_upward_rounded,
            size: 18,
            color: C.accent,
          ),
          label: Text(
            'Back to top',
            style: body(14, c: C.accent, w: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

// ───────────────────────── Reusable widgets ─────────────────────────

/// Fades and slides its child in once, the first time it scrolls into view.
class Reveal extends StatefulWidget {
  final Widget child;
  final int delay;
  final double dx, dy;
  const Reveal({
    super.key,
    required this.child,
    this.delay = 0,
    this.dx = 0,
    this.dy = 0.08,
  });
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  final _id = UniqueKey();
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return VisibilityDetector(
      key: _id,
      onVisibilityChanged: (i) {
        if (!_shown && i.visibleFraction > 0.12) {
          Future.delayed(Duration(milliseconds: widget.delay), () {
            if (mounted) setState(() => _shown = true);
          });
        }
      },
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _shown ? Offset.zero : Offset(widget.dx, widget.dy),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hover wrapper that lifts its child.
class Hover extends StatefulWidget {
  final Widget Function(bool hovered) builder;
  final double lift;
  final VoidCallback? onTap;
  const Hover({super.key, required this.builder, this.lift = 6, this.onTap});
  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _h ? -widget.lift : 0, 0),
        child: widget.builder(_h),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Hover(
    builder: (h) => AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: h ? C.accent : C.line),
        boxShadow: [
          BoxShadow(
            color: C.primary.withValues(alpha: h ? 0.16 : 0.05),
            blurRadius: h ? 30 : 14,
            offset: Offset(0, h ? 16 : 6),
          ),
        ],
      ),
      child: child,
    ),
  );
}

class _Tag extends StatelessWidget {
  final String text;
  final bool dark, outline;
  const _Tag(this.text, {this.dark = false, this.outline = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: 0.18)
          : (outline ? Colors.transparent : C.tint),
      border: outline ? Border.all(color: C.line) : null,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: body(
        13,
        c: dark ? Colors.white : C.primary,
        w: FontWeight.w600,
        h: 1.2,
      ),
    ),
  );
}

class _Btn extends StatelessWidget {
  final String label;
  final bool filled, light, onDark;
  final IconData? icon;
  final VoidCallback onTap;
  const _Btn(
    this.label, {
    required this.onTap,
    this.filled = false,
    this.light = false,
    this.onDark = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final bg = filled ? C.primary : (light ? Colors.white : Colors.transparent);
    final fg = filled
        ? Colors.white
        : (light ? C.primary : (onDark ? Colors.white : C.primary));
    final border = filled || light
        ? Colors.transparent
        : (onDark ? Colors.white54 : C.primary);
    return Hover(
      lift: 3,
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
          boxShadow: h && filled
              ? [
                  BoxShadow(
                    color: C.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: body(15, c: fg, w: FontWeight.w700, h: 1.2),
            ),
            if (icon != null) ...[
              const SizedBox(width: 10),
              AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                offset: h ? const Offset(0.2, 0) : Offset.zero,
                child: Icon(icon, size: 18, color: fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;
  const _NavItem(this.title, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => Hover(
    lift: 0,
    onTap: onTap,
    builder: (h) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: body(
              14.5,
              c: active || h ? C.primary : C.ink,
              w: active ? FontWeight.w700 : FontWeight.w500,
              h: 1.3,
            ),
            child: Text(title),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 2.5,
            width: active ? 22 : (h ? 10 : 0),
            decoration: BoxDecoration(
              color: C.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Counts up from 0 when scrolled into view.
class Counter extends StatefulWidget {
  final int to;
  final String suffix, label;
  const Counter({
    super.key,
    required this.to,
    this.suffix = '',
    required this.label,
  });
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  final _id = UniqueKey();
  bool _go = false;
  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: _id,
    onVisibilityChanged: (i) {
      if (!_go && i.visibleFraction > 0.4) setState(() => _go = true);
    },
    child: _Card(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _go ? widget.to.toDouble() : 0),
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${v.round()}${widget.suffix}', style: head(40, c: C.primary)),
            const SizedBox(height: 6),
            Text(widget.label, style: body(14.5, w: FontWeight.w500)),
          ],
        ),
      ),
    ),
  );
}

/// Types and deletes a rotating list of phrases.
class Typewriter extends StatefulWidget {
  final String prefix;
  final List<String> words;
  final TextStyle style;
  const Typewriter({
    super.key,
    required this.prefix,
    required this.words,
    required this.style,
  });
  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter> {
  Timer? _t;
  int _w = 0, _c = 0, _hold = 0;
  bool _del = false, _cursor = true;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 65), (_) {
      if (_hold > 0) {
        _hold--;
        if (_hold % 8 == 0) setState(() => _cursor = !_cursor);
        return;
      }
      setState(() {
        _cursor = true;
        final word = widget.words[_w];
        if (!_del) {
          _c++;
          if (_c >= word.length) {
            _del = true;
            _hold = 24;
          }
        } else {
          _c--;
          if (_c <= 0) {
            _del = false;
            _w = (_w + 1) % widget.words.length;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_w];
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: widget.prefix,
            style: widget.style.copyWith(color: C.muted),
          ),
          TextSpan(text: word.substring(0, _c.clamp(0, word.length))),
          TextSpan(
            text: '|',
            style: TextStyle(color: _cursor ? C.accent : Colors.transparent),
          ),
        ],
      ),
      style: widget.style,
    );
  }
}

/// Gently floats its child up and down.
class Bob extends StatefulWidget {
  final Widget child;
  final double phase;
  const Bob({super.key, required this.child, this.phase = 0});
  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..value = widget.phase
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    builder: (_, child) => Transform.translate(
      offset: Offset(0, -10 + 20 * Curves.easeInOut.transform(_c.value)),
      child: child,
    ),
    child: widget.child,
  );
}

/// Soft pulsing status dot.
class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 14,
    height: 14,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 14 * (0.5 + _c.value * 0.5),
            height: 14 * (0.5 + _c.value * 0.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.accent.withValues(alpha: 0.5 * (1 - _c.value)),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: C.accent,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Slowly drifting background glows for the hero.
class _Blobs extends StatefulWidget {
  const _Blobs();
  @override
  State<_Blobs> createState() => _BlobsState();
}

class _BlobsState extends State<_Blobs> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value * 2 * math.pi;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -120 + math.sin(t) * 40,
              top: -80 + math.cos(t) * 30,
              child: _blob(520, C.accent),
            ),
            Positioned(
              right: -140 + math.cos(t) * 40,
              bottom: -160 + math.sin(t) * 40,
              child: _blob(600, C.primary),
            ),
          ],
        );
      },
    ),
  );
}

/// Animated project image for the DermaScanAI card.
class _ScanVisual extends StatelessWidget {
  const _ScanVisual();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.5,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Opacity(
        opacity: ((scale - 0.94) / 0.06).clamp(0, 1),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/DermaScanAI Project.png',
          width: double.infinity,
          fit: BoxFit.contain,
          semanticLabel: 'DermaScanAI skincare analysis app preview',
        ),
      ),
    ),
  );
}

class _TechIcon extends StatelessWidget {
  final FaIconData icon;
  final String label;
  const _TechIcon(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Hover(
    lift: 5,
    builder: (_) => SizedBox(
      width: 82,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: C.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: FaIcon(icon, color: C.primary, size: 26)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: body(12.5, c: C.muted, w: FontWeight.w500, h: 1.2),
          ),
        ],
      ),
    ),
  );
}
