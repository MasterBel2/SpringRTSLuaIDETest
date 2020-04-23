//
//  Parser.swift
//  SpringRTSLuaIDETest
//
//  Created by Derek Bel on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

enum ParsingError: Error {
	case invalidCharacterInAttributeName
	case noCharactersInAttributeName
	
	case iJustGaveUp
}

protocol Lexer: AnyObject {
//	var resignControlTarget: Lexer? { get set }
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, rangeOfToken: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index
}

class CommentLexer: Lexer {
	
	let commentBeginIndex: String.Index
	
	init(commentBeginIndex: String.Index) {
		self.commentBeginIndex = commentBeginIndex
	}
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, rangeOfToken: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
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
					tokenStorage.append((.comment(String(string[commentRange])), rangeOfToken: commentRange))
					return nextIndex
				}
			case "\n", "\r\n", "\r":
				if !(commentDepthMax ?? 0 > 0) {
					let commentRange = Range<String.Index>(uncheckedBounds: (lower: commentBeginIndex, upper: currentIndex))
					tokenStorage.append((.comment(String(string[commentRange])), rangeOfToken: commentRange))
					let newlineRange = Range<String.Index>(uncheckedBounds: (lower: currentIndex, upper: nextIndex))
					tokenStorage.append((.punctuation(.newline), rangeOfToken: newlineRange))
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

final class KeywordOrAttributeLexer {
	static let characterSet = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
	static let secondaryCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, rangeOfToken: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
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
				let numberRange = Range<String.Index>(uncheckedBounds: (lower: string.index(before: startIndex), upper: currentIndex))
				tokenStorage.append((.numberLiteral(String(string[numberRange])), numberRange))
				return nextIndex
			}
		}
		return nextIndex
	}
}

final class Tester {
	func test(string: String) {
		var nextIndex = string.startIndex
		benchmarker.benchmark("Advancing Indexes", shouldResetClock: true) {
			for _ in 0..<(string.count) {
				let currentIndex = nextIndex
				nextIndex = string.index(after: currentIndex)
				_ = string[currentIndex]
			}
		}

		nextIndex = string.startIndex

		benchmarker.benchmark("Iterating through characters", shouldResetClock: true) {
			for character in string {
				_ = character
			}
			nextIndex = string.index(nextIndex, offsetBy: string.count)
		}

		benchmarker.printReport()
		benchmarker.reset()
	}
}

final class NumberLiteralLexer: Lexer {
	
	static let characterSet = CharacterSet(charactersIn: "_.").union(CharacterSet.decimalDigits)
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, rangeOfToken: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
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
				return nextIndex
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
	
	func lex(_ string: String, into tokenStorage: inout [(token: Token, rangeOfToken: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
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
	func lex(_ string: String, into tokenStorage: inout [(token: Token, rangeOfToken: Range<String.Index>)], startingFrom startIndex: String.Index, resignAt stopIndex: String.Index) -> String.Index {
		
		//		Tester().test(string: string)
		
		return benchmarker.benchmark("Lexing", shouldResetClock: false) {
			
			var tempStartIndex = string.startIndex
			var nextIndex = string.startIndex
			
			var temp: String = "" {
				didSet {
					if temp == "" {
						tempStartIndex = nextIndex
					}
				}
			}
			
			var stringLiteralEndCharacter: Character?
			var escaped: Bool = false
			
			var shouldContinue: Bool = false
			
			benchmarker.reset()
			
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
				
				var rangeOfTemp: Range<String.Index> {
					return Range<String.Index>(uncheckedBounds: (lower: tempStartIndex, upper: currentIndex))
				}
				var rangeOfCurrentCharacter: Range<String.Index> {
					return Range<String.Index>(uncheckedBounds: (lower: currentIndex, upper: nextIndex))
				}
				
				// Comments override everything. Check them first.
				if temp == Token.Comment.open.rawValue {
					let jumpToIndex = benchmarker.benchmark("Comments", shouldResetClock: false) {
						return CommentLexer(commentBeginIndex: tempStartIndex).lex(string, into: &tokenStorage, startingFrom: nextIndex, resignAt: string.endIndex)
					}
					nextIndex = jumpToIndex
					temp = ""
					continue
				}
				
				benchmarker.benchmark("Attributes & Keywords", shouldResetClock: false) {
					if CharacterSet.decimalDigits.contains(scalar) {
						let jumpToIndex = NumberLiteralLexer().lex(string, into: &tokenStorage, startingFrom: nextIndex, resignAt: string.endIndex)
						nextIndex = jumpToIndex
						temp = ""
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
						temp = ""
						shouldContinue = true
					}
				}
				if shouldContinue {
					continue
				}
				
				if [Token.Punctuation.singleQuote.rawValue, Token.Punctuation.doubleQuote.rawValue].contains(character) {
					let jumpToIndex = benchmarker.benchmark("String literals", shouldResetClock: false) {
						return StringLiteralLexer(terminator: character).lex(string, into: &tokenStorage, startingFrom: nextIndex, resignAt: string.endIndex)
					}
					nextIndex = jumpToIndex
					temp = ""
					continue
				}
				
				// Punctuation signifies the end of a token. Process it first
				
				if let token = Token.Punctuation(rawValue: character) {
					benchmarker.benchmark("Punctuation", shouldResetClock: false) {
						if !(temp.count > 0) {
							tokenStorage.append((.punctuation(token), rangeOfToken: rangeOfCurrentCharacter))
						} else {
							let completedTempToken: Token
							// close of a previous word:
							if let keyword = Token.Keyword(rawValue: temp) {
								completedTempToken = .keyword(keyword)
							}
							else if let binaryOperator = Token.BinaryOperator(rawValue: temp) {
								// 2. Check for operators
								completedTempToken = .binaryOperator(binaryOperator)
							} else if let dataType = Token.DataType(rawValue: temp) {
								// 3. Check for data types
								completedTempToken = .dataType(dataType)
							} else if let token = numberToken(from: temp) {
								// 4. Check for numbers
								completedTempToken = token
							} else if let token = attributeToken(from: temp) {
								// 5. Check for attribute names
								completedTempToken = token
							} else {
								// 6. Just give up
								completedTempToken = .unknown
							}
							
							tokenStorage.append((completedTempToken, rangeOfToken: rangeOfTemp))
							tokenStorage.append((.punctuation(token), rangeOfToken: rangeOfCurrentCharacter))
							temp = ""
						}
						shouldContinue = true
					}
				}
				if shouldContinue {
					continue
				}
				
				benchmarker.benchmark("Unary operators", shouldResetClock: false) {
					if temp.count == 1,
						let unaryOperator = Token.UnaryOperator(rawValue: temp),
						validLetters.contains(character.unicodeScalars.first!) {
						tokenStorage.append((.unaryOperator(unaryOperator), rangeOfTemp))
						temp = ""
					}
				}
				
				// If this hasn't been recognised yet, we'll move on.
				temp.append(character)
			}
			
			benchmarker.printReport()
			return nextIndex
		}
		
		func numberToken(from text: String) -> Token? {
			return benchmarker.benchmark("Numbers", shouldResetClock: false) {
				for unicodeScalar in text.unicodeScalars {
					if !decimalDigits.contains(unicodeScalar) {
						return nil
					}
				}
				return .numberLiteral(text)
			}
		}
		func attributeToken(from text: String) -> Token? {
			return benchmarker.benchmark("Attributes", shouldResetClock: false) {
				guard let first = text.unicodeScalars.first else {
					return nil
				}
				if !validFirstLetters.contains(first) {
					return nil
				}
				
				for unicodeScalar in text.unicodeScalars {
					if !validLetters.contains(unicodeScalar) {
						return nil
					}
				}
				return .attribute(Token.Attribute(name: text, description: "", declarationIndex: 0))
			}
		}
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
//
//struct Context: X {
//	let parent: X?
//
//	let lineIndexes: (startIndex: Int, endIndex: Int)
//	let attributes: [(name: String, Int) : Attribute]
//
//	let tag: Category
//
//	func invalidate() {
//		<#code#>
//	}
//
//	enum Category {
//		case project
//		case file
//		case declaration
//		case branch
//	}
//}
//
//struct Attribute: X {
//	let parent: X
//
//	let name: String
//	let lineIndex: Int
//	let type: PropertyType
//	let inferredType: DataType
//
//	func invalidate() {
//		<#code#>
//	}
//
//	enum DataType {
//		case number
//		case custom
//	}
//
//	enum PropertyType {
//		case table
//		case function
//		case variable
//		case structure
//	}
//}
//
//struct Line: X {
//	func invalidate() {
//		<#code#>
//	}
//}
//
//protocol X {
//	func invalidate()
//}
//
//
