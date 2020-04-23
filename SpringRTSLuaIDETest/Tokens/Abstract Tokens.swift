//
//  Abstract Tokens.swift
//  SpringRTSLuaIDETest
//
//  Created by Derek Bel on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

extension Token {
	/// An abstract token describing a portion of code contained within a context, which is for e.g. a file, or a
	/// function.
	struct Context {
		let declaration: (index: Int, keyword: ContextKeyword)
		let terminationIndex: Int
		let attributes: [Attribute]
		
		let evaluatableLines: [Evaluatable]
	}

	/// An abstract token describing a portion of code that describes a binary statement that may be
	/// evaluated.
	struct Statement: Evaluatable {
		let leftHandSide: Evaluatable
		let middle: BinaryOperator
		let rightHandSide: Evaluatable
	}

	/// An abstract token describing a portion of code that describes a single value, with possible modifiers.
	struct Expression: Evaluatable {
		let unaryOperator: UnaryOperator?
		let keywords: [Keyword]
		
		let components: [(title: String, type: DataType?)]
	}
	
	static let groupers = [
		Grouper.singleQuote,
		Grouper.doubleQuote,
		Grouper.bracket,
		Grouper.parenthesis,
		Grouper.brace
	]
	
	struct Grouper {
		let open: Punctuation
		let close: Punctuation
		
		static let singleQuote = Grouper(open: .singleQuote, close: .singleQuote)
		static let doubleQuote = Grouper(open: .doubleQuote, close: .doubleQuote)
		static let bracket = Grouper(open: .leftBracket, close: .rightBracket)
		static let parenthesis = Grouper(open: .leftParenthesis, close: .rightParenthesis)
		static let brace = Grouper(open: .leftBrace, close: .rightBrace)
	}
}
