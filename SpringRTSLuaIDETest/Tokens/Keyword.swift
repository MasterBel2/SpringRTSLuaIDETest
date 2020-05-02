//
//  Keyword.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

extension Token {
	
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
