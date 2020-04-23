//
//  Core Tokens.swift
//  SpringRTSLuaIDETest
//
//  Created by Derek Bel on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

extension Token {
	
	enum Comment: String {
		case open = "--"
	}
	
	struct Attribute: Hashable {
		let name: String
		let description: String
		let declarationIndex: Int
	}
	
	enum DataType: String {
		case `nil` = "nil"
		case boolean = "boolean"
		case number = "number"
		case string = "string"
		case function = "function"
		case userdata = "userdata"
		case thread = "thread"
		case table = "table"
	}
	
	enum Punctuation: Character {
		case period = "."
		case comma = ","
		case colon = ":"
		
		// Whitespace
		case space = " "
		case tab = "\t"
		case newline = "\n"
		case newline1 = "\r"
		case newline2 = "\r\n"
		
		// Groupers
		case singleQuote = "'"
		case doubleQuote = "\""
		case leftBracket = "["
		case rightBracket = "]"
		case leftBrace = "{"
		case rightBrace = "}"
		case leftParenthesis = "("
		case rightParenthesis = ")"
		
	}
	
	enum UnaryOperator: String {
		case negative = "-"
		case logicalNot = "~"
		//    case  = "#"
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
	//
}
