//
//  SoundEngine.swift
//  Yap

import AVFoundation

enum YapSound {
    case fail(Agent)
    case success(Agent)
}

final class SoundEngine {

    static let shared = SoundEngine()

    private var player: AVAudioPlayer?

    // MARK: - Gender mapping

    private static let femaleAgents: Set<Agent> = [
        .mom, .therapist, .grandma, .passiveAggressiveColleague, .ex
    ]

    private static func isFemale(_ agent: Agent) -> Bool {
        femaleAgents.contains(agent)
    }

    // MARK: - Sound pools
    // Naming convention: yap_<type>_<f|m>_<n>.caf
    // yap_select_f/m sounds are used as APNs notification sounds (server picks randomly).
    // Keep 3-4 per pool — one is picked at random each time.

    private let failFemale = [
        "yap_fail_f_1",
        "yap_fail_f_2",
    ]

    private let failMale = [
        "yap_fail_m_1",
        "yap_fail_m_2",
    ]

    private let successFemale = [
        "yap_success_f_1",
        "yap_success_f_2",
    ]

    private let successMale = [
        "yap_success_m_1",
        "yap_success_m_2",
        "yap_success_m_3",
    ]

    // MARK: - Public API

    static func play(_ sound: YapSound) {
        shared.playSound(sound)
    }

    // MARK: - Private

    private func playSound(_ sound: YapSound) {
        let pool: [String]
        switch sound {
        case .fail(let agent):
            pool = SoundEngine.isFemale(agent) ? failFemale : failMale
        case .success(let agent):
            pool = SoundEngine.isFemale(agent) ? successFemale : successMale
        }

        guard let filename = pool.randomElement() else { return }
        
        // Files must be at bundle root for APNs push sounds to work
        let url = Bundle.main.url(forResource: filename, withExtension: "caf")
        
        guard let soundURL = url else {
            print("⚠️ SoundEngine: file not found — \(filename).caf")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.play()
            print("🔊 SoundEngine: playing \(filename).caf")
        } catch {
            print("⚠️ SoundEngine: playback error — \(error.localizedDescription)")
        }
    }
}
