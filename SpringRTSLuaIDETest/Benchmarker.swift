//
//  Benchmarker.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 23/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

class Benchmarker {
	private(set) var testTimeCache: [String : Double] = [:]
	private(set) var timings: Int = 0
	
	func benchmark<T>(_ testName: String, shouldResetClock: Bool, _ block: () -> T) -> T {
		if shouldResetClock {
			clearCache(for: testName)
		}
		let startTime = CFAbsoluteTimeGetCurrent()
		let result = block()
		let testTime = CFAbsoluteTimeGetCurrent() - startTime
		if let cachedTime = testTimeCache[testName] {
			testTimeCache[testName] = cachedTime + testTime
		} else {
			testTimeCache[testName] = testTime
		}
		timings += 1
		return result
	}
	
	func clearCache(for testName: String) {
		testTimeCache.removeValue(forKey: testName)
	}
	
	func reset() {
		testTimeCache = [:]
		timings = 0
	}
	
	func printReport() {
		print("Ran \(testTimeCache.count) tests, \(timings) individual timings:")
		for test in testTimeCache.map({ (key: $0.key, value: $0.value) }).sorted(by: {$0.value > $1.value}) {
			print("\(test.key): \(test.value) seconds")
		}
	}
}
