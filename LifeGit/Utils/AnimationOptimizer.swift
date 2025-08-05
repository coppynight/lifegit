import SwiftUI

/// Animation optimizer for better performance and smoother animations
struct AnimationOptimizer {
    static let shared = AnimationOptimizer()
    
    private init() {}
    
    // MARK: - Optimized Animations
    
    /// Get optimized spring animation based on performance
    @MainActor
    static func optimizedSpring(
        response: Double = 0.5,
        dampingFraction: Double = 0.8,
        blendDuration: Double = 0
    ) -> Animation {
        let optimizer = UIPerformanceOptimizer.shared
        
        if optimizer.averageFrameTime > 1.0/30.0 { // If below 30 FPS
            // Use simpler animation
            return .easeInOut(duration: response * 0.5)
        } else {
            return .spring(
                response: response,
                dampingFraction: dampingFraction,
                blendDuration: blendDuration
            )
        }
    }
    
    /// Get optimized easing animation
    @MainActor
    static func optimizedEasing(duration: Double = 0.3) -> Animation {
        let optimizer = UIPerformanceOptimizer.shared
        let optimizedDuration = optimizer.getOptimizedAnimationDuration(base: duration)
        
        return optimizer.getOptimizedAnimationCurve()
            .speed(duration / optimizedDuration)
    }
    
    /// Get optimized fade animation
    @MainActor
    static func optimizedFade(duration: Double = 0.2) -> Animation {
        let optimizer = UIPerformanceOptimizer.shared
        let optimizedDuration = optimizer.getOptimizedAnimationDuration(base: duration)
        
        return .linear(duration: optimizedDuration)
    }
    
    /// Get optimized slide animation
    @MainActor
    static func optimizedSlide(duration: Double = 0.4) -> Animation {
        let optimizer = UIPerformanceOptimizer.shared
        
        if optimizer.averageFrameTime > 1.0/45.0 { // If below 45 FPS
            return .linear(duration: duration * 0.6)
        } else {
            return .easeOut(duration: optimizer.getOptimizedAnimationDuration(base: duration))
        }
    }
    
    /// Get optimized scale animation
    @MainActor
    static func optimizedScale(duration: Double = 0.2) -> Animation {
        let optimizer = UIPerformanceOptimizer.shared
        let optimizedDuration = optimizer.getOptimizedAnimationDuration(base: duration)
        
        if optimizer.averageFrameTime > 1.0/50.0 { // If below 50 FPS
            return .linear(duration: optimizedDuration)
        } else {
            return .spring(response: optimizedDuration, dampingFraction: 0.7)
        }
    }
}

// MARK: - SwiftUI Animation Extensions

extension View {
    /// Apply optimized spring animation
    func optimizedSpringAnimation<V: Equatable>(
        _ value: V,
        response: Double = 0.5,
        dampingFraction: Double = 0.8
    ) -> some View {
        self.animation(
            AnimationOptimizer.optimizedSpring(
                response: response,
                dampingFraction: dampingFraction
            ),
            value: value
        )
    }
    
    /// Apply optimized easing animation
    func optimizedEasingAnimation<V: Equatable>(
        _ value: V,
        duration: Double = 0.3
    ) -> some View {
        self.animation(
            AnimationOptimizer.optimizedEasing(duration: duration),
            value: value
        )
    }
    
    /// Apply optimized fade transition
    func optimizedFadeTransition(
        isVisible: Bool,
        duration: Double = 0.2
    ) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .animation(
                AnimationOptimizer.optimizedFade(duration: duration),
                value: isVisible
            )
    }
    
    /// Apply optimized slide transition
    func optimizedSlideTransition(
        isVisible: Bool,
        edge: Edge = .leading,
        distance: CGFloat = 20,
        duration: Double = 0.4
    ) -> some View {
        self
            .offset(
                x: edge == .leading || edge == .trailing ? (isVisible ? 0 : (edge == .leading ? -distance : distance)) : 0,
                y: edge == .top || edge == .bottom ? (isVisible ? 0 : (edge == .top ? -distance : distance)) : 0
            )
            .opacity(isVisible ? 1 : 0)
            .animation(
                AnimationOptimizer.optimizedSlide(duration: duration),
                value: isVisible
            )
    }
    
    /// Apply optimized scale transition
    func optimizedScaleTransition(
        isVisible: Bool,
        scale: CGFloat = 0.8,
        duration: Double = 0.2
    ) -> some View {
        self
            .scaleEffect(isVisible ? 1 : scale)
            .opacity(isVisible ? 1 : 0)
            .animation(
                AnimationOptimizer.optimizedScale(duration: duration),
                value: isVisible
            )
    }
}

// MARK: - Performance-Aware Transition Modifiers

struct OptimizedTransition {
    /// Slide transition that adapts to performance
    @MainActor
    static func slide(edge: Edge = .leading) -> AnyTransition {
        let optimizer = UIPerformanceOptimizer.shared
        
        if optimizer.averageFrameTime > 1.0/30.0 {
            // Use simpler transition for poor performance
            return .opacity
        } else {
            return .asymmetric(
                insertion: .move(edge: edge).combined(with: .opacity),
                removal: .opacity
            )
        }
    }
    
    /// Scale transition that adapts to performance
    @MainActor
    static func scale(scale: CGFloat = 0.8) -> AnyTransition {
        let optimizer = UIPerformanceOptimizer.shared
        
        if optimizer.averageFrameTime > 1.0/30.0 {
            return .opacity
        } else {
            return .scale(scale: scale).combined(with: .opacity)
        }
    }
    
    /// Push transition that adapts to performance
    @MainActor
    static func push(from edge: Edge) -> AnyTransition {
        let optimizer = UIPerformanceOptimizer.shared
        
        if optimizer.averageFrameTime > 1.0/30.0 {
            return .opacity
        } else {
            return .asymmetric(
                insertion: .move(edge: edge),
                removal: .move(edge: edge.opposite)
            )
        }
    }
}

// MARK: - Edge Extension

extension Edge {
    var opposite: Edge {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }
}

// MARK: - Performance-Aware Animation Timing

struct AnimationTiming {
    static let shared = AnimationTiming()
    
    private init() {}
    
    /// Get optimized timing for different animation types
    @MainActor
    func getTiming(for type: AnimationType) -> Double {
        let optimizer = UIPerformanceOptimizer.shared
        let baseTiming = type.baseDuration
        
        return optimizer.getOptimizedAnimationDuration(base: baseTiming)
    }
    
    /// Get optimized delay for staggered animations
    @MainActor
    func getStaggerDelay(index: Int, baseDelay: Double = 0.05) -> Double {
        let optimizer = UIPerformanceOptimizer.shared
        
        if optimizer.averageFrameTime > 1.0/45.0 {
            // Reduce stagger delay for poor performance
            return baseDelay * 0.5
        } else {
            return baseDelay
        }
    }
}

enum AnimationType {
    case quick      // Button taps, toggles
    case standard   // View transitions
    case slow       // Complex transitions
    case custom(Double)
    
    var baseDuration: Double {
        switch self {
        case .quick: return 0.15
        case .standard: return 0.3
        case .slow: return 0.6
        case .custom(let duration): return duration
        }
    }
}

// MARK: - Staggered Animation Helper

struct StaggeredAnimation {
    @MainActor
    static func apply<Content: View>(
        to views: [Content],
        delay: Double = 0.05,
        animation: Animation = .easeOut(duration: 0.3)
    ) -> some View {
        let timing = AnimationTiming.shared
        let optimizedDelay = delay // We'll calculate per-index delay in the loop
        
        return ForEach(Array(views.enumerated()), id: \.offset) { index, view in
            view
                .animation(
                    animation.delay(Double(index) * optimizedDelay),
                    value: index
                )
        }
    }
}