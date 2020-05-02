//
//  Core Tokens.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

extension Token {
	
	enum Comment: String {
		case open = "--"
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
		case comma = ","
		case colon = ":"
		case semicolon = ";"
		
		// Whitespace
		case space = " "
		case tab = "\t"
		case newline = "\n"
		case newline1 = "\r"
		case newline2 = "\r\n"
		
		// Groupers
		case singleQuote = "'"
		case doubleQuote = "\""
		case openingBracket = "["
		case closingBracket = "]"
		case openingBrace = "{"
		case closingBrace = "}"
		case openingParenthesis = "("
		case closingParenthesis = ")"
		
	}
	
	enum Operator: String {
		// Although Period is not considered an operator, it serves the role well enough to be identified here.
		case period = "."
		
		case notSureEither = "#"
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
	//
}
