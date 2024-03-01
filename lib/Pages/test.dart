import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class BackendTestingPage1 extends StatelessWidget {
  final AudioPlayer audioPlayer = AudioPlayer();

  BackendTestingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Audio Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => playAudioFromFirestore(),
              child: const Text('Play'),
            ),
            ElevatedButton(
              onPressed: () => pauseAudio(),
              child: const Text('Pause'),
            ),
            StreamBuilder<Duration>(
              stream: audioPlayer.positionStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final String formattedDuration = formatDuration(
                    snapshot.data ?? Duration.zero,
                    audioPlayer.duration ?? Duration.zero);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Slider(
                      value: snapshot.data!.inMilliseconds.toDouble(),
                      onChanged: (double value) {
                        Duration newPosition =
                            Duration(milliseconds: value.toInt());
                        seekAudio(newPosition);
                      },
                      min: 0.0,
                      max: audioPlayer.duration?.inMilliseconds.toDouble() ??
                          0.0,
                    ),
                    Text(formattedDuration),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> playAudioFromFirestore() async {
    final audioUrl = await fetchAudioUrlFromFirestore();
    try {
      await audioPlayer.setUrl(audioUrl);
      await audioPlayer.play();
      updatePlayingStatus(true);
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> pauseAudio() async {
    try {
      await audioPlayer.pause();
      updatePlayingStatus(false);
    } catch (e) {
      print("Error pausing audio: $e");
    }
  }

  Future<void> seekAudio(Duration position) async {
    try {
      await audioPlayer.seek(position);
      updatePosition(position.inMilliseconds);
    } catch (e) {
      print("Error seeking audio: $e");
    }
  }

Future<String> fetchAudioUrlFromFirestore() async {
    try {
      // Fetch the Firestore document
      DocumentSnapshot<Map<String, dynamic>> audioData = await FirebaseFirestore.instance.collection('Songs').doc('SongId1').get();

      // Get the audio URL stored in Firestore
      String audioStoragePath = audioData['audioUrl'] ?? '';

      // Retrieve the download URL from Firebase Storage
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child(audioStoragePath);
      String downloadURL = await ref.getDownloadURL();
       String manualAudioURL = 'gs://duostreaming-a7e93.appspot.com/Song/Love-Me-Like-You-Do_320(PaglaSongs).mp3';

      
      print('Fetched audio URL: $manualAudioURL');
      return manualAudioURL;

    } catch (e) {
      print("Error fetching audio URL: $e");
      return '';
    }
  }


  void updatePlayingStatus(bool isPlaying) {
    FirebaseFirestore.instance.collection('Songs').doc('songID1').update({'isPlaying': isPlaying});
  }

  void updatePosition(int position) {
    FirebaseFirestore.instance.collection('Songs').doc('songID1').update({'position': position});
  }


    String formatDuration(Duration currentDuration, Duration totalDuration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(currentDuration.inMinutes.remainder(60));
    String seconds = twoDigits(currentDuration.inSeconds.remainder(60));
    return "$minutes:$seconds / ${twoDigits(totalDuration.inMinutes.remainder(60))}:${twoDigits(totalDuration.inSeconds.remainder(60))}";
  }
}