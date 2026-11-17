package ir.soundify.soundify

import com.ryanheise.audioservice.AudioServiceFragmentActivity

// just_audio_background needs an AudioService-aware activity, and local_auth
// (biometrics) needs a FragmentActivity. AudioServiceFragmentActivity is both.
class MainActivity : AudioServiceFragmentActivity()
