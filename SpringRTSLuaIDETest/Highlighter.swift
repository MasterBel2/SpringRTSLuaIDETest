//
//  Highlighter.swift
//  SpringRTSLuaIDETest
//
//  Created by Derek Bel on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Cocoa

final class CodePresenter {

	func updateCode(_ code: String, shownIn updateRange: NSRange, in textView: NSTextView, with tokens: [(Token, Range<String.Index>)]) {
		let benchmarker = Benchmarker()
		
		benchmarker.benchmark("Highlighting 1", shouldResetClock: true) {
			guard let textStorage = textView.textStorage else {
				return
			}
			textStorage.invalidateAttributes(in: updateRange)
			
			tokens.forEach({ (token, range) in
				let nsRange = NSRange(range, in: code)
				
				textStorage.addAttributes([.foregroundColor : color(for: token)], range: nsRange)
			})
		}
		
		benchmarker.benchmark("Highlighting 2", shouldResetClock: true) {
			guard let textStorage = textView.textStorage else {
				return
			}
			textStorage.invalidateAttributes(in: updateRange)
			
			for (token, range) in tokens {
				let nsRange = NSRange(range, in: code)
				
				textStorage.addAttributes([.foregroundColor : color(for: token)], range: nsRange)
			}
		}
		benchmarker.printReport()
	}
	
	private func color(for token: Token) -> NSColor {
		switch token {
		case .attribute:
			return .orange
		case .comment:
			return .systemGray
		case .dataType, .keyword:
			return .systemPink
		case .stringLiteral:
			return .systemRed
		case .numberLiteral:
			return .systemBlue
		default:
			return .black
		}
	}
}
