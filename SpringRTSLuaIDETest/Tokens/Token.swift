//
//  Token.swift
//  SpringRTSLuaIDETest
//
//  Created by Derek Bel on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

protocol Evaluatable {}

enum Token {
	case keyword(Keyword)
	case unknown
	
	case comment(String)
	case numberLiteral(String)
	case stringLiteral(String)
	case attribute(Attribute)
	case dataType(DataType)
	case punctuation(Punctuation)
	case grouper(Grouper)
	case unaryOperator(UnaryOperator)
	case binaryOperator(BinaryOperator)
}
