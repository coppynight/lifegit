import SwiftUI
import AVFoundation

struct VersionCelebrationView: View {
    let version: VersionRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showingContent = false
    @State private var particles: [CelebrationParticle] = []
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: version.isImportantMilestone 
                    ? [.purple.opacity(0.8), .pink.opacity(0.8), .orange.opacity(0.6)]
                    : [.blue.opacity(0.8), .cyan.opacity(0.8), .green.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Particle system
            ForEach(particles) { particle in
                ParticleView(particle: particle)
            }
            
            // Main content
            VStack(spacing: 32) {
                Spacer()
                
                // Celebration icon with animation
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                            .scaleEffect(showingContent ? 1.2 : 0.8)
                            .opacity(showingContent ? 0.3 : 0.8)
                            .animation(
                                .easeInOut(duration: 2.0 + Double(index) * 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                                value: showingContent
                            )
                    }
                    
                    // Main celebration circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, .white.opacity(0.8)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(showingContent ? 1.0 : 0.1)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showingContent)
                    
                    // Celebration emoji/icon
                    if version.isImportantMilestone {
                        Text("🎉")
                            .font(.system(size: 48))
                            .scaleEffect(showingContent ? 1.0 : 0.1)
                            .animation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.3), value: showingContent)
                    } else {
                        Image(systemName: "star.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.yellow)
                            .scaleEffect(showingContent ? 1.0 : 0.1)
                            .animation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.3), value: showingContent)
                    }
                }
                
                // Version information
                VStack(spacing: 16) {
                    Text(version.isImportantMilestone ? "重要里程碑达成!" : "版本升级成功!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .scaleEffect(showingContent ? 1.0 : 0.5)
                        .opacity(showingContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: showingContent)
                    
                    Text(version.version)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                        .scaleEffect(showingContent ? 1.0 : 0.5)
                        .opacity(showingContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.7), value: showingContent)
                    
                    Text("完成目标: \(version.triggerBranchName)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .scaleEffect(showingContent ? 1.0 : 0.5)
                        .opacity(showingContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.9), value: showingContent)
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Text("继续")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                .scaleEffect(showingContent ? 1.0 : 0.5)
                .opacity(showingContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.5), value: showingContent)
            }
            .padding()
        }
        .onAppear {
            showingContent = true
            generateParticles()
            playSound()
        }
        .onDisappear {
            audioPlayer?.stop()
        }
    }
    
    private func generateParticles() {
        particles = []
        
        // Generate celebration particles
        for _ in 0..<50 {
            let particle = CelebrationParticle(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: Double.random(in: -100...UIScreen.main.bounds.height + 100),
                size: Double.random(in: 4...12),
                color: [.white, .yellow, .orange, .pink, .purple, .cyan].randomElement() ?? .white,
                velocity: CGVector(
                    dx: Double.random(in: -50...50),
                    dy: Double.random(in: -100...100)
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -180...180)
            )
            particles.append(particle)
        }
    }
    
    private func playSound() {
        // Play celebration sound effect
        guard let soundURL = Bundle.main.url(forResource: "celebration", withExtension: "mp3") else {
            // If no sound file, use system sound
            AudioServicesPlaySystemSound(1016) // Success sound
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
        } catch {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1016)
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let size: Double
    let color: Color
    var velocity: CGVector
    var rotation: Double
    let rotationSpeed: Double
    
    mutating func update() {
        x += velocity.dx * 0.016 // 60fps
        y += velocity.dy * 0.016
        rotation += rotationSpeed * 0.016
        
        // Apply gravity
        velocity.dy += 50 * 0.016
        
        // Apply air resistance
        velocity.dx *= 0.99
        velocity.dy *= 0.99
    }
}

struct ParticleView: View {
    @State var particle: CelebrationParticle
    @State private var timer: Timer?
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .position(x: particle.x, y: particle.y)
            .rotationEffect(.degrees(particle.rotation))
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                    particle.update()
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
    }
}

// MARK: - Preview

#Preview {
    let sampleVersion = VersionRecord(
        version: "v2.0",
        upgradedAt: Date(),
        triggerBranchName: "职业转型",
        versionDescription: "重要人生转折点",
        isImportantMilestone: true,
        achievementCount: 3,
        totalCommitsAtUpgrade: 67
    )
    
    VersionCelebrationView(version: sampleVersion)
}