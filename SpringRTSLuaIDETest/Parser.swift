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
	
	func lex(_ string: String) -> [(token: Token, rangeOfToken: Range<String.Index>)]
}

//class CommentLexer: Lexer {
//	weak var resignControlTarget: Lexer?
//
//	func lex(_ string: String) -> [(token: Token, rangeOfToken: Range<String.Index>)] {
//		for character in string {
//			switch character {
//			case "=":
//				if commentDepthMax == nil {
//					commentDepth += 1
//				} else if commentDepth != commentDepthMax {
//					commentDepth -= 1
//				}
//			case "[":
//				if commentDepthMax == nil {
//					if commentDepth == 0 {
//						commentDepth += 1
//					} else {
//						commentDepthMax = commentDepth
//					}
//				}
//			case "]":
//				if commentDepth == commentDepthMax {
//					commentDepth -= 1
//				} else if commentDepthMax != nil && commentDepth == 0 {
//					inComment = false
//					temp.append(character)
//					// We can't use `rangeOfTemp` because we've increased the length of `temp` without moving the index.
//					tokens.append((.comment(temp), rangeOfToken: range(length: temp.count, offsetRelativeToIndex: 1)))
//					temp = ""
//					continue
//				}
//			case "\n", "\r\n", "\r":
//				if !(commentDepthMax ?? 0 > 0) {
//					tokens.append((.comment(temp), rangeOfTemp))
//					inComment = false
//					tokens.append((.punctuation(.newline), rangeOfToken: rangeOfCurrentCharacter))
//					temp = ""
//					continue
//				}
//			default:
//				if commentDepthMax == nil {
//					commentDepthMax = 0
//				}
//				commentDepth = commentDepthMax!
//				temp.append(character)
//			}
//			continue
//		}
//	}
//}

//class StringLiteralLexer: Lexer {
//
//	init(startIndex: Int) {
//		self.index = startIndex
//	}
//
//	var index: Int
//
//	func lex(_ string: String) -> [(token: Token, rangeOfToken: Range<String.Index>)] {
//		return []
//	}
//}

class BaseLexer: Lexer {
	let benchmarker = Benchmarker()
	// The string must end in a space to be handled correctly.
	func lex(_ string: String) -> [(token: Token, rangeOfToken: Range<String.Index>)] {
		
		var tempStartIndex = string.startIndex
		var currentIndex = string.startIndex
		var nextIndex = string.startIndex
		
		var tokens: [(token: Token, rangeOfToken: Range<String.Index>)] = []
		var temp: String = "" {
			didSet {
				if temp == "" {
					tempStartIndex = nextIndex
				}
			}
		}
		
		var commentDepth: Int = 0
		var commentDepthMax: Int?
		var inComment: Bool = false
		
		var stringLiteralEndCharacter: Character?
		var escaped: Bool = false
		
		var shouldContinue: Bool = false
		
		benchmarker.reset()
		
		for (index, character) in Array(string).enumerated() {
			benchmarker.benchmark("Range calculations (updating index)", shouldResetClock: false) {
				currentIndex = nextIndex
				nextIndex = string.index(after: currentIndex)
			}
			
			shouldContinue = false
			var indexInString: String.Index {
				return string.index(string.startIndex, offsetBy: index)
			}
			
			func range(length: Int, offsetRelativeToIndex: Int) -> Range<String.Index> {
//				return benchmarker.benchmark("Range calculations", shouldResetClock: false) {
					let endIndex = string.index(currentIndex, offsetBy: offsetRelativeToIndex)
					let beginIndex = string.index(endIndex, offsetBy:  -length)
					return Range<String.Index>(uncheckedBounds: (lower: beginIndex, upper: endIndex))
//				}
			}
			var rangeOfTemp: Range<String.Index> {
				_ = benchmarker.benchmark("Range calculations (\"temp\" 1)", shouldResetClock: false) {
					return range(length: temp.count, offsetRelativeToIndex: 0)
				}
				_ = benchmarker.benchmark("Range calculations (\"temp\" 2)", shouldResetClock: false) { () -> Range<String.Index> in
					let beginIndex = string.index(currentIndex, offsetBy:  -temp.count)
					return Range<String.Index>(uncheckedBounds: (lower: beginIndex, upper: currentIndex))
				}
				return benchmarker.benchmark("Range calculations (\"temp\" 3)", shouldResetClock: false) {
					return Range<String.Index>(uncheckedBounds: (lower: tempStartIndex, upper: currentIndex))
				}
			}
			var rangeOfCurrentCharacter: Range<String.Index> {
				_ = benchmarker.benchmark("Range calculations (current character 1)", shouldResetClock: false) {
					return range(length: 1, offsetRelativeToIndex: 1)
				}
				_ = benchmarker.benchmark("Range calculations (current character 2)", shouldResetClock: false) { () -> Range<String.Index> in
					let endIndex = string.index(currentIndex, offsetBy: 1)
					return Range<String.Index>(uncheckedBounds: (lower: currentIndex, upper: endIndex))
				}
				return benchmarker.benchmark("Range calculations (current character 3)", shouldResetClock: false) {
					return Range<String.Index>(uncheckedBounds: (lower: currentIndex, upper: nextIndex))
				}
			}
			
			benchmarker.benchmark("Comments", shouldResetClock: false) {
				// Check if in comment
				if temp == Token.Comment.open.rawValue,
					!inComment {
					inComment = true
					commentDepth = 0
					commentDepthMax = nil
				}
				
				// first process comments
				if inComment {
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
							inComment = false
							temp.append(character)
							// We can't use `rangeOfTemp` because we've increased the length of `temp` without moving the index.
							let tokenRange = benchmarker.benchmark("Range calculations (updated temp)", shouldResetClock: false) {
								return Range<String.Index>(uncheckedBounds: (lower: tempStartIndex, upper: nextIndex))
							}
							tokens.append((.comment(temp), rangeOfToken: tokenRange))
							temp = ""
						}
					case "\n", "\r\n", "\r":
						if !(commentDepthMax ?? 0 > 0) {
							tokens.append((.comment(temp), rangeOfTemp))
							inComment = false
							tokens.append((.punctuation(.newline), rangeOfToken: rangeOfCurrentCharacter))
							temp = ""
						}
					default:
						if commentDepthMax == nil {
							commentDepthMax = 0
						}
						commentDepth = commentDepthMax!
						temp.append(character)
					}
					shouldContinue = true
				}
			}
			if shouldContinue {
				continue
			}
			benchmarker.benchmark("String literals", shouldResetClock: false) {
				if let definiteStringLiteralEndCharacter = stringLiteralEndCharacter {
					temp.append(character)
					switch character {
					case "\\":
						escaped = !escaped
					case definiteStringLiteralEndCharacter:
						if !escaped {
							// We can't use `rangeOfTemp` because we've increased the lenght of `temp` without moving the index.
							let tokenRange = benchmarker.benchmark("Range calculations (updated temp)", shouldResetClock: false) {
								return Range<String.Index>(uncheckedBounds: (lower: tempStartIndex, upper: nextIndex))
							}
							tokens.append((.stringLiteral(temp), tokenRange))
							temp = ""
							stringLiteralEndCharacter = nil
						}
					default:
						escaped = false
					}
					shouldContinue = true
				}
			}
			if shouldContinue {
				continue
			}
			benchmarker.benchmark("String literals", shouldResetClock: false) {
				if character == Token.Punctuation.singleQuote.rawValue || character == Token.Punctuation.doubleQuote.rawValue {
					stringLiteralEndCharacter = character
					temp.append(character)
					shouldContinue = true
				}
			}
			if shouldContinue {
				continue
			}
			
			// Punctuation signifies the end of a token. Process it first
			
			if let token = Token.Punctuation(rawValue: character) {
				benchmarker.benchmark("Punctuation", shouldResetClock: false) {
					if !(temp.count > 0) {
						tokens.append((.punctuation(token), rangeOfToken: rangeOfCurrentCharacter))
					} else {
						let completedTempToken: Token
						// close of a previous word:
						//  1. check for keyword (only if space)
						if token == .space,
							let keyword = Token.Keyword(rawValue: temp) {
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
						
						tokens.append((completedTempToken, rangeOfToken: rangeOfTemp))
						tokens.append((.punctuation(token), rangeOfToken: rangeOfCurrentCharacter))
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
					validFirstLetters.contains(character.unicodeScalars.first!) {
					tokens.append((.unaryOperator(unaryOperator), rangeOfTemp))
					temp = ""
				}
			}
				
			// If this hasn't been recognised yet, we'll move on.
			temp.append(character)
		}
		
		benchmarker.printReport()
		return tokens
	}
	
	func numberToken(from text: String) -> Token? {
		return benchmarker.benchmark("Numbers", shouldResetClock: false) {
			for unicodeScalar in text.unicodeScalars {
				if !CharacterSet.decimalDigits.contains(unicodeScalar) {
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
var validFirstLetters: CharacterSet {
	var temp = CharacterSet.letters
	temp.insert(charactersIn: "_")
	return temp
}
var validLetters: CharacterSet {
	var temp = CharacterSet.alphanumerics
	temp.insert(charactersIn: "_")
	return temp
}

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
