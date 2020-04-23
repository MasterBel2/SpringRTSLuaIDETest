//
//  Highlighter.swift
//  SpringRTSLuaIDETest
//
//  Created by Derek Bel on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Cocoa

final class CodePresenter {

	func updateCode(_ code: String, shownIn textView: NSTextView, with tokens: [(Token, Range<String.Index>)]) {
		for (token, range) in tokens {
			let nsRange = NSRange(range, in: code)
			textView.setTextColor(color(for: token), range: nsRange)
		}
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
		default:
			return .black
		}
	}
}
