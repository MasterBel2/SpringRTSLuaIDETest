//
//  Highlighter.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Cocoa

final class CodePresenter {
	
    func update(_ code: String, describedBy tokens: [(token: Token, range: Range<String.Index>)], shownIn updateRange: NSRange, in textView: NSTextView, with attributeReferences: [ParserToken.AttributeReference]) {
		let benchmarker = Benchmarker()
		
		let errorColor: NSColor = NSColor.systemBlue.withAlphaComponent(0.3)

        func rangeOfTokens(in tokenRange: Range<Int>) -> Range<String.Index> {
            let lowerBound = tokens[tokenRange.lowerBound].range.lowerBound
            let upperBound = tokens[tokenRange.upperBound - 1].range.upperBound
            return lowerBound..<upperBound
        }
		
		benchmarker.benchmark("Highlighting attribute references", shouldResetClock: true) {
			guard let textStorage = textView.textStorage else {
				return
			}
			
			for reference in attributeReferences {
                let nsRange = NSRange(rangeOfTokens(in: reference.startIndex..<(reference.endIndex + 1)), in: code)
				
				textStorage.addAttribute(.backgroundColor, value: errorColor, range: nsRange)
			}
		}
		benchmarker.printReport()
	}
	
	func update(_ code: String, shownIn updateRange: NSRange, in textView: NSTextView, with errors: [ContextParser.ParsingError]) {
		let benchmarker = Benchmarker()
		
		let errorColor: NSColor = NSColor.systemRed.withAlphaComponent(0.3)
		
		benchmarker.benchmark("Highlighting errors", shouldResetClock: true) {
			guard let textStorage = textView.textStorage else {
				return
			}
			
			for error in errors {
				let nsRange = NSRange(error.range, in: code)
				
				textStorage.addAttribute(.backgroundColor, value: errorColor, range: nsRange)
			}
		}
		benchmarker.printReport()
	}

	func update(_ code: String, shownIn updateRange: NSRange, in textView: NSTextView, with tokens: [(Token, Range<String.Index>)]) {
		let benchmarker = Benchmarker()
		
		benchmarker.benchmark("Syntax Highlighting", shouldResetClock: true) {
			guard let textStorage = textView.textStorage else {
				return
			}
			textStorage.invalidateAttributes(in: updateRange)
			textStorage.addAttribute(.font, value: NSFont(name: "Courier", size: 12.0)!, range: updateRange)
			
			for (token, range) in tokens {
				let nsRange = NSRange(range, in: code)
				
				textStorage.addAttribute(.foregroundColor, value: color(for: token), range: nsRange)
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
