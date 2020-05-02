//
//  Parser.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

enum ParsingError: Error {
	case invalidCharacterInAttributeName
	case noCharactersInAttributeName
	
	case iJustGaveUp
}

protocol Lexer: AnyObject {
	func lex(_ string: String, into tokenStorage: inout [(token: Token, range: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index
}

class CommentLexer: Lexer {
	
	let commentBeginIndex: String.Index
	
	init(commentBeginIndex: String.Index) {
		self.commentBeginIndex = commentBeginIndex
	}
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, range: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
		var nextIndex = startIndex
		
		
		var commentDepth: Int = 0
		var commentDepthMax: Int? = nil
		
		while nextIndex < stopIndex {
			let currentIndex = benchmarker.benchmark("Range calculations (updating index)", shouldResetClock: false) { () -> String.Index in
				let currentIndex = nextIndex
				nextIndex = string.index(after: currentIndex)
				return currentIndex
			}
			
			let character = string[currentIndex]
			
			switch character {
			case "=":
				if commentDepthMax == nil {
					commentDepth += 1
				} else if commentDepth != commentDepthMax {
					commentDepth -= 1
				}
			case "[":
				if commentDepthMax == nil {
					if commentDepth == 0 {
						commentDepth += 1
					} else {
						commentDepthMax = commentDepth
					}
				}
			case "]":
				if commentDepth == commentDepthMax {
					commentDepth -= 1
				} else if commentDepthMax != nil && commentDepth == 0 {
					// We can't use `rangeOfTemp` because we've increased the length of `temp` without moving the index.
					let commentRange = Range<String.Index>(uncheckedBounds: (lower: commentBeginIndex, upper: nextIndex))
					tokenStorage.append((.comment(String(string[commentRange])), range: commentRange))
					return nextIndex
				}
			case "\n", "\r\n", "\r":
				if !(commentDepthMax ?? 0 > 0) {
					let commentRange = Range<String.Index>(uncheckedBounds: (lower: commentBeginIndex, upper: currentIndex))
					tokenStorage.append((.comment(String(string[commentRange])), range: commentRange))
					let newlineRange = Range<String.Index>(uncheckedBounds: (lower: currentIndex, upper: nextIndex))
					tokenStorage.append((.punctuation(.newline), range: newlineRange))
					return nextIndex
				}
			default:
				if commentDepthMax == nil {
					commentDepthMax = 0
				}
				commentDepth = commentDepthMax!
			}
		}
		return nextIndex
	}
}

final class OperatorLexer {
	static let characterSet = CharacterSet(charactersIn: "#=+-*/%^&~|<>=.")

	let operatorStartIndex: String.Index
	init(operatorStartIndex: String.Index) {
		self.operatorStartIndex = operatorStartIndex
	}
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, range: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {

        let singleCharacterOperatorRange = Range<String.Index>(uncheckedBounds: (lower: operatorStartIndex, upper: startIndex))
        
        // Only check a single character if there is no nextIndex.
        if startIndex == string.endIndex {
            let someOperator = Token.Operator.init(rawValue: String(string[singleCharacterOperatorRange]))!
            tokenStorage.append((Token.operator(someOperator), range: singleCharacterOperatorRange))
            return startIndex
        }
		
		let nextIndex = benchmarker.benchmark("Range calculations (updating index)", shouldResetClock: false) {
			return string.index(after: startIndex)
		}
		
		let twoCharacterOperatorRange = Range<String.Index>(uncheckedBounds: (lower: operatorStartIndex, upper: nextIndex))
		
		let twoCharacterOperatorString = String(string[twoCharacterOperatorRange])
		
		if twoCharacterOperatorString == Token.Comment.open.rawValue {
			let jumpToIndex = benchmarker.benchmark("Comments", shouldResetClock: false) {
				return CommentLexer(commentBeginIndex: operatorStartIndex).lex(string, into: &tokenStorage, startingFrom: nextIndex, resignAt: string.endIndex)
			}
			return jumpToIndex
		}
		
		if let someOperator = Token.Operator.init(rawValue: String(string[twoCharacterOperatorRange])) {
			tokenStorage.append((Token.operator(someOperator), range: twoCharacterOperatorRange))
			return nextIndex
		} else {
			let someOperator = Token.Operator.init(rawValue: String(string[singleCharacterOperatorRange]))!
			tokenStorage.append((Token.operator(someOperator), range: singleCharacterOperatorRange))
			return startIndex
		}
	}
}

final class KeywordOrAttributeLexer {
	static let characterSet = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
	static let secondaryCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, range: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
		var nextIndex = startIndex
		
		while nextIndex < stopIndex {
			let currentIndex = benchmarker.benchmark("Range calculations (updating index)", shouldResetClock: false) { () -> String.Index in
				let currentIndex = nextIndex
				nextIndex = string.index(after: currentIndex)
				return currentIndex
			}
			
			let character = string[currentIndex]
			
			if let first = character.unicodeScalars.first,
				!KeywordOrAttributeLexer.secondaryCharacterSet.contains(first) {
				let token: Token
				let range = Range<String.Index>(uncheckedBounds: (lower: string.index(before: startIndex), upper: currentIndex))
				let text = String(string[range])
				if let keyword = Token.Keyword(rawValue: text) {
					token = .keyword(keyword)
				} else if let dataType = Token.DataType(rawValue: text) {
					token = .dataType(dataType)
				} else {
					token = .attribute(text)
				}
				tokenStorage.append((token, range))
				return currentIndex
			}
		}
		return nextIndex
	}
}

final class NumberLiteralLexer: Lexer {
	
	static let characterSet = CharacterSet(charactersIn: "_.").union(CharacterSet.decimalDigits)
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, range: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
		var nextIndex = startIndex
		
		while nextIndex < stopIndex {
			let currentIndex = benchmarker.benchmark("Range calculations (updating index)", shouldResetClock: false) { () -> String.Index in
				let currentIndex = nextIndex
				nextIndex = string.index(after: currentIndex)
				return currentIndex
			}
			
			let character = string[currentIndex]
			
			if let first = character.unicodeScalars.first,
				!NumberLiteralLexer.characterSet.contains(first) {
				let numberRange = Range<String.Index>(uncheckedBounds: (lower: string.index(before: startIndex), upper: currentIndex))
				tokenStorage.append((.numberLiteral(String(string[numberRange])), numberRange))
				return currentIndex
			}
		}
		return nextIndex
	}
}

final class StringLiteralLexer: Lexer {
	
	let terminator: Character
	
	init(terminator: Character) {
		self.terminator = terminator
	}
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, range: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
		var nextIndex = startIndex
		
		var escaped: Bool = false
		
		while nextIndex < stopIndex {
			let currentIndex = benchmarker.benchmark("Range calculations (updating index)", shouldResetClock: false) { () -> String.Index in
				let currentIndex = nextIndex
				nextIndex = string.index(after: currentIndex)
				return currentIndex
			}
			
			let character = string[currentIndex]
			
			switch character {
			case "\\":
				escaped = !escaped
			case terminator:
				if !escaped {
					let tokenRange = Range<String.Index>(uncheckedBounds: (lower: string.index(before: startIndex), upper: nextIndex))
					let text = String(string[tokenRange])
					tokenStorage.append((.stringLiteral(text), tokenRange))
					return nextIndex
				}
				escaped = false
			default:
				escaped = false
			}

		}
		return stopIndex
	}
}
let benchmarker = Benchmarker()

class BaseLexer: Lexer {
	// The string must end in a space to be handled correctly.
	func lex(_ string: String, into tokenStorage: inout [(token: Token, range: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		benchmarker.reset()
		let x = benchmarker.benchmark("Lexing", shouldResetClock: false) { () -> String.Index in
			return lex2(string, into: &tokenStorage, startingFrom: startIndex, resignAt: stopIndex)
		}
		
		// Best total: 1.0121430158615112 seconds
		benchmarker.printReport()
		return x
	}
	
	func lex2(_ string: String, into tokenStorage: inout [(token: Token, range: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
		var nextIndex = string.startIndex
		
		var shouldContinue: Bool = false
		
		while nextIndex < stopIndex {
			let currentIndex = benchmarker.benchmark("Range calculations (updating index)", shouldResetClock: false) { () -> String.Index in
				let currentIndex = nextIndex
				nextIndex = string.index(after: currentIndex)
				return currentIndex
			}
			
			let character = string[currentIndex]
			guard let scalar = character.unicodeScalars.first else {
				fatalError("Failed to find a unicode scalar for a character.")
			}
			
			shouldContinue = false
			
			var rangeOfCurrentCharacter: Range<String.Index> {
				return Range<String.Index>(uncheckedBounds: (lower: currentIndex, upper: nextIndex))
			}
			
			benchmarker.benchmark("Attributes & Keywords", shouldResetClock: false) {
				if KeywordOrAttributeLexer.characterSet.contains(scalar) {
					let jumpToIndex = KeywordOrAttributeLexer().lex(string, into: &tokenStorage, startingFrom: nextIndex, resignAt: string.endIndex)
					nextIndex = jumpToIndex
					shouldContinue = true
				}
			}
			if shouldContinue {
				continue
			}
			
			benchmarker.benchmark("Number literals", shouldResetClock: false) {
				if CharacterSet.decimalDigits.contains(scalar) {
					let jumpToIndex = NumberLiteralLexer().lex(string, into: &tokenStorage, startingFrom: nextIndex, resignAt: string.endIndex)
					nextIndex = jumpToIndex
					shouldContinue = true
				}
			}
			if shouldContinue {
				continue
			}
			benchmarker.benchmark("Operators", shouldResetClock: false) {
				if OperatorLexer.characterSet.contains(scalar) {
					let jumpToIndex = OperatorLexer(operatorStartIndex: currentIndex).lex(string, into: &tokenStorage, startingFrom: nextIndex, resignAt: string.endIndex)
					nextIndex = jumpToIndex
					shouldContinue = true
				}
			}
			
			if [Token.Punctuation.singleQuote.rawValue, Token.Punctuation.doubleQuote.rawValue].contains(character) {
				let jumpToIndex = benchmarker.benchmark("String literals", shouldResetClock: false) {
					return StringLiteralLexer(terminator: character).lex(string, into: &tokenStorage, startingFrom: nextIndex, resignAt: string.endIndex)
				}
				nextIndex = jumpToIndex
				continue
			}
			
			// Punctuation signifies the end of a token. Process it first
			
			benchmarker.benchmark("Punctuation", shouldResetClock: false) {
				if let token = Token.Punctuation(rawValue: character) {
					tokenStorage.append((.punctuation(token), range: rangeOfCurrentCharacter))
					shouldContinue = true
				}
			}
			if shouldContinue {
				continue
			}
			// Bail out if not yet recognised
			tokenStorage.append((.unknown, range: rangeOfCurrentCharacter))
		}
		
		return nextIndex
	}
}
let decimalDigits: CharacterSet = CharacterSet.decimalDigits
let validFirstLetters: CharacterSet = {
	var temp = CharacterSet.letters
	temp.insert(charactersIn: "_")
	return temp
}()
let validLetters: CharacterSet = {
	var temp = CharacterSet.alphanumerics
	temp.insert(charactersIn: "_")
	return temp
}()

func parse(_ tokens: [Token]) {
	print("Found \(tokens.count) tokens:")
	for (index, token) in tokens.enumerated() {
		print("\(index)) \(token)")
	}
}
