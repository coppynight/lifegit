import Foundation
import SwiftUI
import Combine

/// UI performance optimizer for smooth scrolling and responsive interactions
@MainActor
class UIPerformanceOptimizer: ObservableObject {
    static let shared = UIPerformanceOptimizer()
    
    // MARK: - Performance Metrics
    @Published var averageFrameTime: TimeInterval = 0
    @Published var isPerformanceOptimized = false
    
    // MARK: - Caching
    private var imageCache = NSCache<NSString, UIImage>()
    private var dataCache = NSCache<NSString, AnyObject>()
    private var viewCache = NSCache<NSString, AnyObject>()
    
    // MARK: - Performance Monitoring
    private var frameTimeHistory: [TimeInterval] = []
    private var lastFrameTime: CFAbsoluteTime = 0
    private var performanceTimer: Timer?
    
    // MARK: - Configuration
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private let maxCacheItems = 100
    private let targetFrameTime: TimeInterval = 1.0 / 60.0 // 60 FPS
    
    private init() {
        setupCaches()
        startPerformanceMonitoring()
    }
    
    // MARK: - Cache Setup
    
    private func setupCaches() {
        // Image cache configuration
        imageCache.totalCostLimit = maxCacheSize / 2
        imageCache.countLimit = maxCacheItems
        
        // Data cache configuration
        dataCache.totalCostLimit = maxCacheSize / 4
        dataCache.countLimit = maxCacheItems
        
        // View cache configuration
        viewCache.totalCostLimit = maxCacheSize / 4
        viewCache.countLimit = maxCacheItems / 2
        
        // Memory warning handling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        clearCaches()
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updatePerformanceMetrics()
        }
    }
    
    private func updatePerformanceMetrics() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        if lastFrameTime > 0 {
            let frameTime = currentTime - lastFrameTime
            frameTimeHistory.append(frameTime)
            
            // Keep only recent history
            if frameTimeHistory.count > 60 {
                frameTimeHistory.removeFirst()
            }
            
            // Calculate average
            averageFrameTime = frameTimeHistory.reduce(0, +) / Double(frameTimeHistory.count)
            
            // Update optimization status
            isPerformanceOptimized = averageFrameTime <= targetFrameTime * 1.2 // 20% tolerance
        }
        
        lastFrameTime = currentTime
    }
    
    // MARK: - Image Caching
    
    func cacheImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4) // Approximate memory cost
        imageCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func getCachedImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    // MARK: - Data Caching
    
    func cacheData<T: AnyObject>(_ data: T, forKey key: String) {
        dataCache.setObject(data, forKey: key as NSString)
    }
    
    func getCachedData<T: AnyObject>(forKey key: String, type: T.Type) -> T? {
        return dataCache.object(forKey: key as NSString) as? T
    }
    
    // MARK: - View Caching
    
    func cacheViewData<T: AnyObject>(_ data: T, forKey key: String) {
        viewCache.setObject(data, forKey: key as NSString)
    }
    
    func getCachedViewData<T: AnyObject>(forKey key: String, type: T.Type) -> T? {
        return viewCache.object(forKey: key as NSString) as? T
    }
    
    // MARK: - List Performance Optimization
    
    /// Optimize list performance by implementing virtual scrolling concepts
    func optimizeListPerformance<T>(
        items: [T],
        visibleRange: Range<Int>,
        bufferSize: Int = 5
    ) -> [T] {
        let startIndex = max(0, visibleRange.lowerBound - bufferSize)
        let endIndex = min(items.count, visibleRange.upperBound + bufferSize)
        
        return Array(items[startIndex..<endIndex])
    }
    
    /// Calculate visible range for list optimization
    func calculateVisibleRange(
        scrollOffset: CGFloat,
        itemHeight: CGFloat,
        containerHeight: CGFloat
    ) -> Range<Int> {
        let startIndex = max(0, Int(scrollOffset / itemHeight))
        let visibleCount = Int(ceil(containerHeight / itemHeight)) + 1
        let endIndex = startIndex + visibleCount
        
        return startIndex..<endIndex
    }
    
    // MARK: - Animation Optimization
    
    /// Get optimized animation duration based on performance
    func getOptimizedAnimationDuration(base: TimeInterval = 0.3) -> TimeInterval {
        if averageFrameTime > targetFrameTime * 2 {
            // Reduce animation duration if performance is poor
            return base * 0.5
        } else if averageFrameTime > targetFrameTime * 1.5 {
            return base * 0.75
        } else {
            return base
        }
    }
    
    /// Get optimized animation curve based on performance
    func getOptimizedAnimationCurve() -> Animation {
        if averageFrameTime > targetFrameTime * 2 {
            return .linear
        } else {
            return .easeInOut
        }
    }
    
    // MARK: - Memory Management
    
    func clearCaches() {
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
        viewCache.removeAllObjects()
    }
    
    func getCacheStatistics() -> CacheStatistics {
        return CacheStatistics(
            imageCacheCount: imageCache.countLimit,
            dataCacheCount: dataCache.countLimit,
            viewCacheCount: viewCache.countLimit,
            totalMemoryUsage: getTotalCacheMemoryUsage()
        )
    }
    
    private func getTotalCacheMemoryUsage() -> Int {
        // This is an approximation - actual implementation would need more detailed tracking
        return maxCacheSize / 4 // Assume 25% usage on average
    }
    
    // MARK: - Debouncing for Performance
    
    private var debounceTimers: [String: Timer] = [:]
    
    func debounce(key: String, delay: TimeInterval, action: @escaping () -> Void) {
        // Cancel existing timer
        debounceTimers[key]?.invalidate()
        
        // Create new timer
        debounceTimers[key] = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
            self.debounceTimers.removeValue(forKey: key)
        }
    }
    
    // MARK: - Batch Operations
    
    func batchUpdates<T>(
        items: [T],
        batchSize: Int = 10,
        delay: TimeInterval = 0.01,
        update: @escaping ([T]) -> Void
    ) {
        let batches = items.chunked(into: batchSize)
        
        for (index, batch) in batches.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * Double(index)) {
                update(batch)
            }
        }
    }
    
    deinit {
        performanceTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

struct CacheStatistics {
    let imageCacheCount: Int
    let dataCacheCount: Int
    let viewCacheCount: Int
    let totalMemoryUsage: Int
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - SwiftUI Performance Extensions

extension View {
    /// Apply performance optimizations to a view
    func optimizedForPerformance() -> some View {
        self
            .drawingGroup() // Flatten view hierarchy for better performance
            .clipped() // Optimize rendering
    }
    
    /// Apply optimized animations
    func optimizedAnimation(_ animation: Animation? = nil) -> some View {
        let optimizer = UIPerformanceOptimizer.shared
        let optimizedAnimation = animation ?? optimizer.getOptimizedAnimationCurve()
        
        return self.animation(optimizedAnimation, value: UUID())
    }
    
    /// Debounced onChange modifier
    func debouncedOnChange<V: Equatable>(
        of value: V,
        debounceTime: TimeInterval = 0.3,
        perform action: @escaping (V) -> Void
    ) -> some View {
        self.onChange(of: value) { newValue in
            UIPerformanceOptimizer.shared.debounce(
                key: "onChange_\(String(describing: V.self))",
                delay: debounceTime
            ) {
                action(newValue)
            }
        }
    }
}

// MARK: - List Performance Helper

struct OptimizedList<Data, Content>: View where Data: RandomAccessCollection, Data.Element: Identifiable, Content: View {
    let data: Data
    let content: (Data.Element) -> Content
    
    @State private var visibleRange: Range<Int> = 0..<10
    @StateObject private var optimizer = UIPerformanceOptimizer.shared
    
    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    if visibleRange.contains(index) {
                        content(item)
                            .onAppear {
                                updateVisibleRange(around: index)
                            }
                    } else {
                        // Placeholder for non-visible items
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 60) // Estimated item height
                            .onAppear {
                                updateVisibleRange(around: index)
                            }
                    }
                }
            }
            .optimizedForPerformance()
        }
    }
    
    private func updateVisibleRange(around index: Int) {
        let bufferSize = 5
        let newStart = max(0, index - bufferSize)
        let newEnd = min(data.count, index + bufferSize)
        
        if newStart != visibleRange.lowerBound || newEnd != visibleRange.upperBound {
            visibleRange = newStart..<newEnd
        }
    }
}