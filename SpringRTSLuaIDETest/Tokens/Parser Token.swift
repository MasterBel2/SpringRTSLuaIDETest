//
//  Abstract Tokens.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

protocol Evaluatable {
	var startIndex: Int { get }
	var endIndex: Int { get }
}

enum ParserToken {
	struct AttributeDeclaration {
		let name: String
		let description: String?
		let startIndex: Int
		let endIndex: Int
		let components: [(name: String, index: Int)]
	}
	struct AttributeReference {
		let startIndex: Int
		let endIndex: Int
		let components: [(name: String, index: Int)]
	}
	
	/// An abstract token describing a portion of code contained within a context, which is for e.g. a file, or a
	/// function.
	struct Context {
		let declaration: (index: Int, keyword: ContextKeyword)
		let terminationIndex: Int
		let attributes: [AttributeDeclaration]
		
		let evaluatableLines: [Evaluatable]
	}
	
	struct ContextKeyword {
		let declarator: Token.Keyword
		let terminators: [Token.Keyword]
		
		static let function = ContextKeyword(declarator: .function, terminators: [.end])
		static let `if` = ContextKeyword(declarator: .if, terminators: [.or, .then])
		static let elseif = ContextKeyword(declarator: .elseif, terminators: [.or, .then])
		static let or = ContextKeyword(declarator: .or, terminators: [.or, .then])
		static let then = ContextKeyword(declarator: .then, terminators: [.else, .elseif, .end])
		static let `else` = ContextKeyword(declarator: .else, terminators: [.end])
		static let `repeat` = ContextKeyword(declarator: .repeat, terminators: [.until])
		static let `do` = ContextKeyword(declarator: .do, terminators: [.end])
		static let `while` = ContextKeyword(declarator: .while, terminators: [.do])
		static let `for` = ContextKeyword(declarator: .for, terminators: [.do])
	}

	static let contextKeywords: [ContextKeyword] = [
		ContextKeyword.function,
		ContextKeyword.if,
		ContextKeyword.elseif,
		ContextKeyword.or,
		ContextKeyword.then,
		ContextKeyword.else,
		ContextKeyword.repeat,
		ContextKeyword.do,
		ContextKeyword.while,
		ContextKeyword.for
	]

	/// An abstract token describing a portion of code that describes a binary statement that may be
	/// evaluated.
	struct Statement: Evaluatable {
		let leftHandSide: Evaluatable
		let middle: BinaryOperator
		let rightHandSide: Evaluatable
		
		let startIndex: Int
		let endIndex: Int
	}

	/// An abstract token describing a portion of code that describes a single value, with possible modifiers.
	struct Expression: Evaluatable {
		let unaryOperator: UnaryOperator
		let value: Evaluatable
		
		let startIndex: Int
		let endIndex: Int
	}
	
	enum Value: Evaluatable {
		case stringLiteral((value: String, index: Int))
		case numberLiteral((value: String, index: Int))
		case attribute((components: [(name: String, index: Int)], startIndex: Int, endIndex: Int))
		
		var endIndex: Int {
			switch self {
			case .stringLiteral(let (_, index)):
				return index + 1
			case .numberLiteral(let (_, index)):
				return index + 1
			case .attribute(let (_, _, endIndex)):
				return endIndex
			}
		}
		var startIndex: Int {
			switch self {
			case .stringLiteral(let (_, index)):
				return index
			case .numberLiteral(let (_, index)):
				return index
			case .attribute(let (_, startIndex, _)):
				return startIndex
			}
		}
	}
	
	static let groupers = [
		Grouper.bracket,
		Grouper.parenthesis,
		Grouper.brace
	]
	
	struct Grouper {
		let open: Token.Punctuation
		let close: Token.Punctuation
		
		static let bracket = Grouper(open: .openingBracket, close: .closingBracket)
		static let parenthesis = Grouper(open: .openingParenthesis, close: .closingParenthesis)
		static let brace = Grouper(open: .openingBrace, close: .closingBrace)
	}
	
	enum UnaryOperator: String {
		case negative = "-"
		case logicalNot = "~"
		case notSureEither = "#"
	}
	
	enum BinaryOperator: String {
		case assign = "="
		case add = "+"
		case subtract = "-"
		case multiply = "*"
		case divide = "/"
		case modulo = "%"
		case exponent = "^"
		case logicalAnd = "&"
		case notSureWhatThisDoes = "~"
		case logicalOr = "|"
		case shiftLeft = "<<"
		case shiftRight = ">>"
		case equal = "=="
		case inequal = "~="
		case lessThanOrEqual = "<="
		case greaterthanOrEqual = ">="
		case lessThan = "<"
		case greaterThan = ">"
		case concatenate = ".."
	}
}
