//
//  Token.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

enum Token: Equatable {
	case keyword(Keyword)
	case unknown
	
	case comment(String)
	case numberLiteral(String)
	case stringLiteral(String)
	case attribute(String)
	case dataType(DataType)
	case punctuation(Punctuation)
	case `operator`(Operator)
	
	static let newlines: [Token] = [
			.punctuation(.newline),
			.punctuation(.newline1),
			.punctuation(.newline2)
		]
	
	static let whitespace: [Token] = [
		Token.punctuation(.space),
		Token.punctuation(.tab),
		Token.punctuation(.newline),
		Token.punctuation(.newline1),
		Token.punctuation(.newline2)
	]
}
