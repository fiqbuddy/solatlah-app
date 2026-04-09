import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/learning_service.dart';
import '../widgets/speech_test_widget.dart';
import '../widgets/quiz_widget.dart';
import '../services/profile_service.dart';

class LessonPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final int courseId;
  final bool isCompleted;

  const LessonPage({
    super.key,
    required this.lesson,
    required this.courseId,
    required this.isCompleted,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  final learningService = LearningService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int? _playingIndex; // which audio in the list is playing

  List<Map<String, dynamic>> _lessonAudios = [];
  List<Map<String, dynamic>> _lessonQuestions = [];

  List<Map<String, dynamic>> _lessonNiat = [];
  List<Map<String, dynamic>> _modelHotspots = [];
  Map<String, dynamic>? _selectedHotspot;
  int? _expandedNiatIndex;
  String? _testMode; // 'speech' or 'quiz'
  bool _isKid = false;
  bool _questionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAudios();
    _checkAge();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted)
        setState(() {
          _playingIndex = null;
          _position = Duration.zero;
          _duration = Duration.zero;
        });
    });
  }

  Future<void> _loadAudios() async {
    try {
      final audios = await learningService.getLessonAudios(widget.lesson['id']);
      final niat = await learningService.getLessonNiat(widget.lesson['id']);
      final questions =
          await learningService.getLessonQuestions(widget.lesson['id']);
      final hotspots =
          await learningService.getModelHotspots(widget.lesson['id']);
      if (mounted)
        setState(() {
          _lessonAudios = audios;
          _lessonNiat = niat;
          _lessonQuestions = questions;
          _questionsLoaded = true;
          _modelHotspots = hotspots;
        });
    } catch (e) {
      debugPrint('Error loading: $e');
      if (mounted)
        setState(() {
          _lessonAudios = [];
          _lessonNiat = [];
          _lessonQuestions = [];
          _questionsLoaded = true;
        });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url, int index) async {
    if (_playingIndex == index && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_playingIndex == index && _playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.stop();
      setState(() {
        _playingIndex = index;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.music,
            audioMode: AndroidAudioMode.normal,
            stayAwake: false,
          ),
        ),
      );
      await _audioPlayer.play(UrlSource(url));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _checkAge() async {
    final profileService = ProfileService();
    await profileService.getProfile();
    if (mounted) setState(() => _isKid = profileService.isKid);
  }

  Widget _buildAudioCard(Map<String, dynamic> audio, int index) {
    final url = _isKid
        ? (audio['audio_url_kids'] ?? audio['audio_url'])
        : audio['audio_url'];
    final isThisPlaying = _playingIndex == index;
    final isPlaying = isThisPlaying && _playerState == PlayerState.playing;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isThisPlaying ? const Color(0xFF1B5E20) : Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isThisPlaying ? Colors.white30 : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _playAudio(url, index),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isThisPlaying ? Colors.white : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color:
                        isThisPlaying ? const Color(0xFF1B5E20) : Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  audio['title'],
                  style: TextStyle(
                    color: isThisPlaying ? Colors.white : Colors.white70,
                    fontWeight:
                        isThisPlaying ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isThisPlaying)
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
            ],
          ),
          if (isThisPlaying) ...[
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white10,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 3,
              ),
              child: Slider(
                value: _position.inSeconds
                    .toDouble()
                    .clamp(0, _duration.inSeconds.toDouble()),
                max: _duration.inSeconds.toDouble() == 0
                    ? 1
                    : _duration.inSeconds.toDouble(),
                onChanged: (value) async {
                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position),
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(_formatDuration(_duration),
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNiatCard(Map<String, dynamic> niat, int index) {
    final isExpanded = _expandedNiatIndex == index;
    final niatUrl = _isKid
        ? (niat['audio_url_kids'] ?? niat['audio_url'])
        : niat['audio_url'];
    final hasAudio = niatUrl != null && niatUrl.toString().isNotEmpty;
    final isThisPlaying =
        _playingIndex == (100 + index); // offset to avoid clash
    final isPlaying = isThisPlaying && _playerState == PlayerState.playing;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFF1B5E20) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header tap to expand
          GestureDetector(
            onTap: () =>
                setState(() => _expandedNiatIndex = isExpanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          isExpanded ? Colors.white24 : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isExpanded
                              ? Colors.white
                              : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      niat['solat_name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:
                            isExpanded ? Colors.white : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color:
                        isExpanded ? Colors.white70 : const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  // Arabic
                  Text(
                    niat['arabic_text'],
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 2.0,
                      color: Colors.white,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Transliteration
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      niat['transliteration'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Translation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      niat['translation'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.white60,
                      ),
                    ),
                  ),

                  // Audio button
                  if (hasAudio) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _playAudio(niatUrl, 100 + index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPlaying ? 'Pause' : 'Play Audio',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isThisPlaying) ...[
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white10,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _position.inSeconds
                              .toDouble()
                              .clamp(0, _duration.inSeconds.toDouble()),
                          max: _duration.inSeconds.toDouble() == 0
                              ? 1
                              : _duration.inSeconds.toDouble(),
                          onChanged: (value) async {
                            await _audioPlayer
                                .seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_position),
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                            Text(_formatDuration(_duration),
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arabicText = widget.lesson['arabic_text'];
    final transliteration = widget.lesson['transliteration'];
    final translation = widget.lesson['translation'];
    final audioUrl = _isKid
        ? (widget.lesson['audio_url_kids'] ?? widget.lesson['audio_url'])
        : widget.lesson['audio_url'];
    final modelUrl = widget.lesson['model_url'];
    final hasNiat = _lessonNiat.isNotEmpty;
    final hasArabic = arabicText != null && arabicText.toString().isNotEmpty;
    final hasSingleAudio = audioUrl != null && audioUrl.toString().isNotEmpty;
    final hasMultiAudio = _lessonAudios.isNotEmpty;
    final hasModel = modelUrl != null && modelUrl.toString().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.lesson['title'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Langkah ${widget.lesson['order']}',
                  style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.green.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Text(widget.lesson['content'],
                  style: const TextStyle(
                      fontSize: 15, height: 1.7, color: Color(0xFF2D2D2D))),
            ),

            // Niat cards
            if (hasNiat) ...[
              const SizedBox(height: 20),
              const Text(
                'Lafaz Niat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ketik pada setiap solat untuk lihat lafaz niat',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ..._lessonNiat.asMap().entries.map(
                    (e) => _buildNiatCard(e.value, e.key),
                  ),
            ],

            // Arabic card
            if (hasArabic) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(arabicText,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            fontSize: 24,
                            height: 2.0,
                            color: Colors.white,
                            fontFamily: 'serif')),
                    if (transliteration != null) ...[
                      const Divider(color: Colors.white24, height: 24),
                      Text(transliteration,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic)),
                    ],
                    if (translation != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(translation,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: Colors.white60)),
                      ),
                    ],

                    // Single audio (non-niat lessons)
                    if (hasSingleAudio && !hasMultiAudio) ...[
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (_playerState == PlayerState.playing) {
                                await _audioPlayer.pause();
                              } else if (_playerState == PlayerState.paused) {
                                await _audioPlayer.resume();
                              } else {
                                await _audioPlayer.play(UrlSource(audioUrl));
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle),
                              child: Icon(
                                _playerState == PlayerState.playing
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.white10,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: _position.inSeconds.toDouble().clamp(
                                        0, _duration.inSeconds.toDouble()),
                                    max: _duration.inSeconds.toDouble() == 0
                                        ? 1
                                        : _duration.inSeconds.toDouble(),
                                    onChanged: (value) async {
                                      await _audioPlayer.seek(
                                          Duration(seconds: value.toInt()));
                                    },
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(_position),
                                          style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11)),
                                      Text(_formatDuration(_duration),
                                          style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Multiple audios
                    if (hasMultiAudio) ...[
                      const Divider(color: Colors.white24, height: 24),
                      const Text('Lafaz Audio',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      ..._lessonAudios.asMap().entries.map(
                            (e) => _buildAudioCard(e.value, e.key),
                          ),
                    ],
                  ],
                ),
              ),
            ],

            // 3D Model
            if (hasModel) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: const [
                          Icon(Icons.view_in_ar,
                              color: Color(0xFF2E7D32), size: 20),
                          SizedBox(width: 8),
                          Text('3D View',
                              style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          SizedBox(width: 8),
                          Text('(drag to rotate)',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),

                    // Model viewer
                    ClipRRect(
                      borderRadius: _modelHotspots.isEmpty
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            )
                          : BorderRadius.zero,
                      child: SizedBox(
                        height: 300,
                        child: ModelViewer(
                          src: modelUrl,
                          alt: widget.lesson['title'],
                          ar: false,
                          autoRotate: true,
                          cameraControls: true,
                          backgroundColor: const Color(0xFFF4FAF4),
                          minCameraOrbit: 'auto 90deg auto',
                          maxCameraOrbit: 'auto 90deg auto',
                        ),
                      ),
                    ),

                    // Hotspot info panel
                    if (_modelHotspots.isNotEmpty) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Maklumat Pose',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Hotspot selector chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _modelHotspots.map((hotspot) {
                                final isSelected =
                                    _selectedHotspot?['id'] == hotspot['id'];
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedHotspot =
                                      isSelected ? null : hotspot),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF2E7D32),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF2E7D32),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          hotspot['title'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            // Selected hotspot description
                            if (_selectedHotspot != null) ...[
                              const SizedBox(height: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4FAF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF2E7D32)
                                          .withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.info,
                                            color: Color(0xFF2E7D32), size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          _selectedHotspot!['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1B5E20),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedHotspot!['description'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.6,
                                        color: Color(0xFF2D2D2D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

// Completed banner
            if (widget.isCompleted)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E7D32)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Pembelajaran sudah selesai! Anda masih boleh untuk mengambil ujian semula.',
                          style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

// Speech test
            // Test section
            // Test section
            if (!_questionsLoaded) ...[
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
            ] else if (widget.lesson['expected_reading'] != null &&
                _lessonQuestions.isNotEmpty) ...[
              // Both available — let user choose
              if (_testMode == null) ...[
                const Text('Pilih Jenis Ujian',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _testMode = 'speech'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF2E7D32), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.green.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.mic,
                                  color: Color(0xFF2E7D32), size: 36),
                              SizedBox(height: 8),
                              Text('Ujian Sebutan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                      fontSize: 13)),
                              SizedBox(height: 4),
                              Text('Baca dengan suara',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _testMode = 'quiz'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF2E7D32), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.green.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.quiz,
                                  color: Color(0xFF2E7D32), size: 36),
                              SizedBox(height: 8),
                              Text('Kuiz Pilihan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                      fontSize: 13)),
                              SizedBox(height: 4),
                              Text('Soalan aneka pilihan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                GestureDetector(
                  onTap: () => setState(() => _testMode = null),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back_ios,
                          size: 14, color: Color(0xFF2E7D32)),
                      Text('Tukar jenis ujian',
                          style: TextStyle(
                              color: Color(0xFF2E7D32), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_testMode == 'speech')
                  SpeechTestWidget(
                    expectedText: widget.lesson['expected_reading'],
                    isAlreadyPassed: widget.isCompleted,
                    onPassed: () async {
                      if (!widget.isCompleted) {
                        await learningService.completeLesson(
                            widget.lesson['id'], widget.courseId);
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                  )
                else
                  QuizWidget(
                    questions: _lessonQuestions,
                    isAlreadyPassed: widget.isCompleted,
                    onPassed: () async {
                      if (!widget.isCompleted) {
                        await learningService.completeLesson(
                            widget.lesson['id'], widget.courseId);
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                  ),
              ],
            ] else if (widget.lesson['expected_reading'] != null) ...[
              SpeechTestWidget(
                expectedText: widget.lesson['expected_reading'],
                isAlreadyPassed: widget.isCompleted,
                onPassed: () async {
                  if (!widget.isCompleted) {
                    await learningService.completeLesson(
                        widget.lesson['id'], widget.courseId);
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
            ] else if (_lessonQuestions.isNotEmpty) ...[
              QuizWidget(
                questions: _lessonQuestions,
                isAlreadyPassed: widget.isCompleted,
                onPassed: () async {
                  if (!widget.isCompleted) {
                    await learningService.completeLesson(
                        widget.lesson['id'], widget.courseId);
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
