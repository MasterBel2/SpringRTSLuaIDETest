//
//  Keyword.swift
//  SpringRTSLuaIDETest
//
//  Created by Derek Bel on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

extension Token {
	
	struct ContextKeyword {
		let declarator: Keyword
		let terminators: [Keyword]
	}

	static let contextKeywords: [ContextKeyword] = [
		ContextKeyword(declarator: .function, terminators: [.end]),
		ContextKeyword(declarator: .if, terminators: [.or, .then]),
		ContextKeyword(declarator: .elseif, terminators: [.or, .then]),
		ContextKeyword(declarator: .or, terminators: [.or, .then]),
		ContextKeyword(declarator: .then, terminators: [.else, .elseif, .end]),
		ContextKeyword(declarator: .else, terminators: [.end]),
		ContextKeyword(declarator: .repeat, terminators: [.until]),
		ContextKeyword(declarator: .do, terminators: [.end]),
		ContextKeyword(declarator: .while, terminators: [.do]),
		ContextKeyword(declarator: .for, terminators: [.do]),
	]
	
	enum Keyword: String {
		// Context Keywords
		
		case `for`
		case `do`
		case `if`
		case then
		case `else`
		/// The context keyword `elseif`. Follows an `if ... then` and is followed by an `elseif`, an `else`, or an `end`.
		case elseif
		case `repeat`
		case until
		case `while`
		
		// Comparative Keywords
		
		case and
		case or
		case `in`
		
		// Value Keywords
		case `nil`
		case `true`
		case `false`
		
		// Floating Keywords
		case `break`
		case end
		
		// Expression Modifiers
		
		case function
		case goto
		case local
		case not
		case `return`
	}
}
