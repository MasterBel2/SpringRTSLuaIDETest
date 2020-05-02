//
//  Parser.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 23/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Foundation

final class GlobalContext {
	
}

/**
 An object that will parse Lua tokens, and identify attributes and errors.

 # Internal operation
 Privately, a parser parses forward sequentially from the given index, looking backwards only to identify documentation comments (although this could be modified to be handled sequentially in the future).
 
*/
final class ContextParser {
	
	// MARK: - Identity
	
	/// The context parser of which this parser is a child.
	weak var parent: ContextParser?
	/// The global context from which knowledge of global attributes will be retrieved.
	let globalContext: GlobalContext
	/// The index in the token list from which the parser will begin to parse.
	let startIndex: Int
	/// The keyword tokens which should indicate the conclusion of this context.
	let terminators: [Token.Keyword]
	
	// MARK: - Initialisation
	
	/**
	- parameter startIndex: The index of the token that begins the body of the context.
	- parameter parent: The parser handling the context that contains this parser. `nil` if the context is an entire file.
	- parameter globalContext: The global context from which knowledge of global attributes will be retrieved.
	- parameter terminators: The context keywords which signify the conclusion of the context.
	*/
	init(startIndex: Int, parent: ContextParser? = nil, globalContext: GlobalContext, terminators: [Token.Keyword]) {
		self.startIndex = startIndex
		self.parent = parent
		self.globalContext = globalContext
		self.terminators = terminators
	}
	
	// MARK: - Tools
	
	/// The child contexts handling local contexts within the bounds of this context.
	private(set) var children: [(ContextParser, endIndex: Int)] = []
	
	/// Removes all properties found by this context.
	@available(*, deprecated, message: "Replace with a method to remove only properties that will be affected by the new parse.")
	private func reset() {
		attributeDefinitions = []
		_comments = []
		_errors = []
	}

    /// The range in code that corresponds to the tokens.
	private func rangeOfTokens(in tokenRange: Range<Int>) -> Range<String.Index> {
		let lowerBound = tokens[tokenRange.lowerBound].range.lowerBound
		let upperBound = tokens[tokenRange.upperBound - 1].range.upperBound
		return lowerBound..<upperBound
	}
	
	// MARK: - Information used for parsing
	
	var tokens: [(token: Token, range: Range<String.Index>)] = []
	var code: String = ""
	
	// MARK: - Internal results of parsing
	
	/// Attributes defined in the context.
	private var attributeDefinitions: [ParserToken.AttributeDeclaration] = []
	/// Attributes referenced in the context.
	private var _attributeReferences: [ParserToken.AttributeReference] = []
	/// Comments describing tags found by the parser in this context.
	///
	/// For retrieving all comments in the context (including the child contexts), one should access the `comments` property.
	private var _comments: [NotableComment] = []
	/// Errors found by the parser in this context.
	///
	/// For retrieving all errors in the context (including the child contexts), one should access the `errors` property.
	private var _errors: [ParsingError] = []
	
	// MARK: - Accessing parsed properties
	
	/// The notable comments of this context and its children.
	var comments: [NotableComment] {
		return _comments + children.map({ (child: ContextParser, _) -> [NotableComment] in child.comments }).joined()
	}
	/// The errors found by this context and its children.
	var errors: [ParsingError] {
		return _errors + children.map({ (child: ContextParser, _) -> [ParsingError] in child.errors }).joined()
	}
	var attributeReferences: [ParserToken.AttributeReference] {
		return _attributeReferences + children.map({ (child: ContextParser, _) -> [ParserToken.AttributeReference] in child.attributeReferences }).joined()
	}

    /// Returns the description of the attribute referenced in a range, if it contains a single attribute token.
	func documentation(forAttributeIn range: Range<String.Index>) -> String? {
		// convert Range to a token index
		for (index, token) in tokens.enumerated() {
			if token.range.contains(range.upperBound) && token.range.contains(range.lowerBound) {
				return documentation(forAttributeTokenAt: index)
			}
		}
		return nil
	}

    /// Returns the description of the attribute referenced at the given index, if it exists.
	private func documentation(forAttributeTokenAt tokenIndex: Int) -> String? {
		// Check if the reference is in a child context, and delegate the request to them.
		for (child, endIndex) in children {
			if (child.startIndex..<endIndex).contains(tokenIndex) {
				return child.documentation(forAttributeTokenAt: tokenIndex)
			}
		}
		
		guard let reference = attributeReferencedInScope(at: tokenIndex),
			let declaration = attributeDefinedInScope(reference.components.filter { $0.index <= tokenIndex }.map { $0.name }) else {
				return nil
		}
		
		return declaration.description
	}

    /// Returns the full attribute reference containing the token at the given index.
	private func attributeReferencedInScope(at index: Int) -> ParserToken.AttributeReference? {
		return _attributeReferences.first(where: {
                return ($0.startIndex...$0.endIndex).contains(index)

        })
	}

	private func attributeDefinedInScope(_ components: [String]) -> ParserToken.AttributeDeclaration? {
		return attributeDefinitions.first(where: { $0.components.map { $0.name } == components }) ?? parent?.attributeDefinedInScope(components)
	}
	
	// MARK: - Main parsing loop
	
	/**
	Executes a parse operation.
	
	Portions of code not described by tokens will be ignored.
	
	- parameter tokens: The tokens and their ranges describing the code to be parsed.
	- parameter code: The code to be parsed.
	- parameter startIndex: The index in `tokens` at which the parser should begin parsing.
	- parameter lineIndex: The index of the line on which the token at `startIndex` is found.
	*/
	func parse(_ tokens: [(token: Token, range: Range<String.Index>)], from code: String, startingFrom startIndex: Int) -> Int {
		self.tokens = tokens
		self.code = code
		
		reset()
		
		var nextIndex: Int = startIndex
		
		// Begin the main parse loop.
		while nextIndex < tokens.count {
			let (token, _) = tokens[nextIndex]

			switch token {
			case .punctuation:
				break
			case .attribute:
				let (attributeReference, isFunctionSignature) = findAttributeChain(.at(nextIndex, in: tokens, code: code))
				guard let last = attributeReference.components.last else {
					break
				}
				let description = findDescription(.searchBefore(nextIndex, in: tokens, code: code))
				if !verifyAttributeReferenceForAttributeDeclaration(attributeReference) {
					if canFindPostfix(.operator(.assign), forTokenAt: last.index, in: tokens) {
						let range = rangeOfTokens(in: Range(attributeReference.startIndex...attributeReference.endIndex))
						attributeDefinitions.append(
							ParserToken.AttributeDeclaration(
								name: String(code[range]),
								description: description,
								startIndex: nextIndex,
								endIndex: nextIndex + 1,
								components: attributeReference.components
							)
						)
					} else {
						_errors.append(undefinedAttributeError(tokens[last.index].range))
					}
				}
				// TODO: - handle multi-component attribute references
				nextIndex += 1
				continue
			case .comment(let comment):
				// If prefixed by newline and starts with "-- # " it is a notable comment.
                if  nextIndex == 0 || Token.newlines.contains(tokens[nextIndex - 1].token),
					comment.hasPrefix("-- # ") {
					_comments.append(NotableComment(title: String(comment.dropFirst(5)), index: nextIndex))
				}
			case .keyword(let keyword):
				if terminators.contains(keyword) {
					return nextIndex
				}
				
				if ParserToken.contextKeywords.contains(where: { $0.declarator == keyword }) {
					nextIndex = processContextKeyword(keyword, .at(nextIndex, in: tokens, code: code)) + 1
					continue
				} else {
					nextIndex = process(keyword, .at(nextIndex, in: tokens, code: code)) + 1
				}
			default:
				break
			}
			
			nextIndex += 1
		}
		if parent == nil {
			print("Parsing complete, found \(errors.count) error\(errors.count == 1 ? "" : "s")!")
			print(errors.map({"\($0.description)"}).joined(separator: "\n"))
			print("\(attributeDefinitions.count) attributes:\n" + attributeDefinitions.map { $0.name }.joined(separator: "\n"))
			print("\(_comments.count) notable comments:\n" + _comments.map { $0.title }.joined(separator: "\n"))
			print("\(children.count) child parsers spawned.")
		}
		return nextIndex
	}
	
	// MARK: - Keywords
	
	private func process(_ keyword: Token.Keyword, _ searchDescription: SearchDescription) -> Int {
		switch keyword {
			case .local:
			let (attributeReference, isFunctionCall) = findAttributeChain(.searchAfter(searchDescription))
			guard let first = attributeReference.components.first,
				let last = attributeReference.components.last else {
					return searchDescription.startIndex
			}
			_ = verifyAttributeReferenceForAttributeDeclaration(attributeReference)
			let description = findDescription(.searchBefore(searchDescription))
			let range = rangeOfTokens(in: Range(attributeReference.startIndex...attributeReference.endIndex))
			attributeDefinitions.append(
				ParserToken.AttributeDeclaration(
					name: String(code[range]),
					description: description,
					startIndex: first.index, endIndex: last.index,
					components: attributeReference.components
				)
			)
			return last.index
		default:
			return searchDescription.startIndex
		}
	}
	
	/// Parses the tokens following a context keyword token, and returns control to the main parse loop when
	private func processContextKeyword(_ keyword: Token.Keyword, _ searchDescription: SearchDescription) -> Int {
		switch keyword {
		case .if, .elseif:
			guard let nextValue = evaluatable(.searchAfter(searchDescription)) else {
				_errors.append(expectationError(expected: "value", afterKeywordAt: searchDescription.rangeAtIndex))
				return searchDescription.startIndex
			}
		case .function:
			
			// 1.1 Function signature
			guard let (functionSignature) = functionDeclarationSignature(.searchAfter(searchDescription)) else {
				// Errors will be handled by `functionDeclarationSignature(_:)`.
				return searchDescription.startIndex
			}
				
			// 2. Function body. Delegate to a context parser.
			let childParser = ContextParser(
				startIndex: functionSignature.endIndex + 1,
				parent: self,
				globalContext: globalContext,
				terminators: ParserToken.ContextKeyword.function.terminators
			)
			let endIndex = childParser.parse(
				searchDescription.tokenList,
				from: searchDescription.code,
				startingFrom: functionSignature.endIndex
			)
			children.append((childParser, endIndex: endIndex))
			return endIndex
		//		case .
		default:
			break
		}
		return searchDescription.startIndex
	}
	
	// MARK: - Functions
	
	/// Describes the declaration of a function.
	struct FunctionSignature {
		/// The index of the first token of the declaration (usually a `function` keyword).
		let startIndex: Int
		/// The index of the last token of the declaration (usually a `)`).
		let endIndex: Int
		/// The components of the function declaration, and their indexes. The final component is the function's name, specifically.
		let components: [(name: String, index: Int)]
		/// The function arguments. The last one may be `...`.
		let arguments: [(name: String, index: Int)]
	}
	
	/// Parses a function signature. In the case of an error, what can be parsed will be returned, as well as the generated error.
	private func functionDeclarationSignature(_ searchDescription: SearchDescription) -> FunctionSignature? {
		// 1.1 Function attribute name
		let tokenList = searchDescription.tokenList
		var arguments: [(name: String, index: Int)] = []
		
		let (attributeReference, _) = findAttributeChain(searchDescription)
		guard let last = attributeReference.components.last else {
				_errors.append(expectationError(expected: "declaration", at: searchDescription.rangeAtIndex))
				return nil
		}
		
		// 1.2 Verify all attributes have been defined
		for component in attributeReference.components.dropLast() {
			if !verifyAttributeReferenceForAttributeDeclaration(attributeReference) {
				_errors.append( undefinedAttributeError(searchDescription.tokenList[component.index].range))
				return FunctionSignature(startIndex: searchDescription.startIndex, endIndex: last.index, components: attributeReference.components, arguments: arguments)
			}
		}
		
		// 2 Function Arguments
		let parenthesisIndex = last.index + 1
		if tokenList[parenthesisIndex].token == .punctuation(.openingParenthesis) {
			var localSearchDescription = SearchDescription(startIndex: parenthesisIndex + 1, tokenList: tokenList, code: searchDescription.code)
			loop: while localSearchDescription.startIndex < tokenList.count {
				guard let (token, index) = nextNotWhitespace(localSearchDescription) else {
					#warning("Should return partial value")
					return FunctionSignature(startIndex: localSearchDescription.startIndex, endIndex: last.index, components: attributeReference.components, arguments: arguments)
				}
				switch token {
				case .attribute(let name):
					arguments.append((name: name, index: index))
					#warning("Should check for elipsis also")
				default:
					break loop
				}
				localSearchDescription = .searchAfter(localSearchDescription)
				if !(nextNotWhitespace(localSearchDescription)?.token == Token.punctuation(.comma)) {
					break loop
				}
				localSearchDescription = .searchAfter(localSearchDescription)
			}
			
			let endIndex: Int
			if let (token, index) = nextNotWhitespace(localSearchDescription),
				token == .punctuation(.closingParenthesis) {
				endIndex = index
			} else {
				_errors.append(expectationError(expected: "closing parenthesis", at: localSearchDescription.rangeAtIndex))
				endIndex = localSearchDescription.startIndex
			}
			
			return FunctionSignature(startIndex: searchDescription.startIndex, endIndex: endIndex, components: attributeReference.components, arguments: arguments)
		} else {
			_errors.append(expectationError(expected: "function arguments", at: tokenList[parenthesisIndex].range))
			return FunctionSignature(startIndex: searchDescription.startIndex, endIndex: last.index, components: attributeReference.components, arguments: arguments)
		}
	}
	
	private func findFunctionArguments(_ startIndex: Int) -> (arguments: [ParserToken.AttributeReference], endIndex: Int) {
		if tokens[startIndex].token == .punctuation(.openingParenthesis) {
			var arguments: [ParserToken.AttributeReference] = []
			
			var localSearchDescription = SearchDescription(startIndex: startIndex + 1, tokenList: tokens, code: code)
			
			loop: while localSearchDescription.startIndex < tokens.count {
				let (reference, isFunctionCall) = findAttributeChain(localSearchDescription)
				guard let last = reference.components.last else {
					return (arguments, endIndex: startIndex + 1)
				}
				arguments.append(reference)
				
				localSearchDescription = .searchAfter(last.index, in: tokens, code: code)
				if !(nextNotWhitespace(localSearchDescription)?.token == Token.punctuation(.comma)) {
					return (arguments: arguments, endIndex: last.index)
				}
				localSearchDescription = .searchAfter(localSearchDescription)
			}
			// TODO: - Find closing parenthesis
			return (arguments: arguments, endIndex: localSearchDescription.startIndex)
		}
		return (arguments: [], endIndex: startIndex)
	}
	
	// MARK: - Evaluatables
	
	/// Finds the next evaluatable, searching from `searchDescription.startIndex`
	private func evaluatable(_ searchDescription: SearchDescription) -> Evaluatable? {
		guard let (nextToken, nextTokenIndex) = nextNotWhitespace(searchDescription) else {
			return nil
		}
		
		let evaluatable: Evaluatable
		
		switch nextToken {
		case .operator(let someOperator):
			if let unaryOperator = ParserToken.UnaryOperator(rawValue: someOperator.rawValue),
				let operatedOnValue = value(.searchAfter(nextTokenIndex, in: searchDescription.tokenList, code: searchDescription.code)) {
				evaluatable = ParserToken.Expression(
					unaryOperator: unaryOperator,
					value: operatedOnValue,
					startIndex: nextTokenIndex,
					endIndex: operatedOnValue.endIndex
				)
				break
			}
			_errors.append(floatingOperatorError(searchDescription.rangeAtIndex))
			return nil
		case .numberLiteral(let value):
			evaluatable = ParserToken.Value.numberLiteral((value: value, index: nextTokenIndex))
		case .stringLiteral(let value):
			evaluatable = ParserToken.Value.stringLiteral((value: value, index: nextTokenIndex))
		case .punctuation(.openingBrace):
			return nil
		case .attribute:
			return attributeValue(searchDescription)
		default:
			return nil
		}
		
		return evaluatable
	}
	
	private func attributeValue(_ searchDescription: SearchDescription) -> Evaluatable? {
		let (attributeReference, isFunctionSignature) = findAttributeChain(searchDescription)
		guard let first = attributeReference.components.first,
			let last = attributeReference.components.last else {
			return nil
		}
		if !verifyAttributeReference(attributeReference) {
			_errors.append(undefinedAttributeError(searchDescription.tokenList[last.index].range))
		}
		return ParserToken.Value.attribute((components: attributeReference.components, startIndex: first.index, endIndex: last.index))
	}

private func value(_ searchDescription: SearchDescription) -> Evaluatable? {
	guard let (nextToken, nextTokenIndex) = nextNotWhitespace(searchDescription) else {
		return nil
	}
	
		switch nextToken {
		case .attribute:
			return attributeValue(searchDescription)
		case .numberLiteral(let value):
			return ParserToken.Value.numberLiteral((value: value, index: nextTokenIndex))
		case .stringLiteral(let value):
			return ParserToken.Value.stringLiteral((value: value, index: nextTokenIndex))
		case .punctuation(.openingBrace):
			break
		case .punctuation(.openingBracket):
			guard let x = evaluatable(.at(nextTokenIndex + 1, in: searchDescription.tokenList, code: searchDescription.code)) else {
				return nil
			}
			
			break
		default:
			expectationError(expected: "value", at: searchDescription.tokenList[nextTokenIndex].range)
		}
		expectationError(expected: "value", at: searchDescription.rangeAtIndex)
		return nil
	}
	
	// MARK: - Attributes
	
	/// Finds all components of an attribute reference.
	private func findAttributeChain(_ searchDescription: SearchDescription) -> (reference: ParserToken.AttributeReference, isFunctionSignature: Bool) {
		
		var searchIndex = searchDescription.startIndex
		var isFunctionCall = false
		var components: [(name: String, index: Int)] = []
		
		var nextSearchDescription: SearchDescription {
			return SearchDescription(startIndex: searchIndex, tokenList: searchDescription.tokenList, code: searchDescription.code)
		}
		
		loop: while searchIndex < searchDescription.tokenList.count {
			let attributeOrNil = nextAttribute(nextSearchDescription)
			guard let (attribute, index) = attributeOrNil else {
				#warning("Need to send error here")
				break
			}
			components.append((name: attribute, index: index))
			searchIndex = index + 1
			
			if !isFunctionCall,
				let (token, index) = nextNotWhitespace(nextSearchDescription) {
				switch token {
				case .punctuation(.colon):
					isFunctionCall = true
				case .operator(.period):
					break
				default:
					break loop
				}
				searchIndex = index + 1
			} else {
				break loop
			}
		}
		let reference = ParserToken.AttributeReference(
			startIndex: searchDescription.startIndex,
			endIndex: searchIndex - 1,
			components: components
		)
		_attributeReferences.append(reference)

		return (reference: reference, isFunctionSignature: isFunctionCall)
	}
	
	private func verifyAttributeReferenceForAttributeDeclaration(_ attributeReference: ParserToken.AttributeReference) -> Bool {
		
		return verifyAttributeReference(
			ParserToken.AttributeReference(
				startIndex: attributeReference.startIndex,
				endIndex: attributeReference.components.last?.index ?? attributeReference.startIndex,
				components: attributeReference.components.dropLast()
			)
		)
	}
	
	private func verifyAttributeReference(_ attributeReference: ParserToken.AttributeReference) -> Bool {
		var allDefined = true
		for length in 0..<attributeReference.components.count {
			let components = Array(attributeReference.components.dropLast(length)).map( {$0.name })
			if attributeDefinedInScope(components) == nil {
				allDefined = false
			}
		}
		return allDefined
	}
	private func definedAttribute(_ attributeName: String) -> ParserToken.AttributeDeclaration? {
		return attributeDefinitions.filter({ $0.name == attributeName }).first ?? parent?.definedAttribute(attributeName)
	}
	
	private func findDescription(_ searchDescription: SearchDescription) -> String? {
		var searchIndex = searchDescription.startIndex
		var nextNewlineTerminatesDescription = false
		var description: String? = nil
		
		while searchIndex >= 0 {
			let token = searchDescription.tokenList[searchIndex].token
			switch token {
			case .comment(let comment):
				nextNewlineTerminatesDescription = false
				
				let textForDescription = removePrefix(ofCharactersIn: "-[=", from: comment)
				if description == nil {
					description = textForDescription
				} else {
					description?.append(textForDescription)
				}
			case .punctuation(.newline), .punctuation(.newline1), .punctuation(.newline2):
				if nextNewlineTerminatesDescription {
					return description
				} else {
					nextNewlineTerminatesDescription = true
				}
			case .punctuation(.space), .punctuation(.tab):
				break
			default:
				return description
			}
			searchIndex -= 1
		}
		
		return description
	}
	
	private func tableAttribute(_ searchDescription: SearchDescription) -> Evaluatable? {
		return nil
	}
	
	private func tableIndex(_ searchDescription: SearchDescription) -> Evaluatable? {
		return nil
	}
	
	// MARK: - Finding tokens
	
	/// Finds the next attribute reference directly following the token at `index`, ignoring any whitespace, returning `nil` if no reference was found.
	private func nextAttribute(_ searchDescription: SearchDescription) -> (attributeName: String, index: Int)? {
		guard let (followingToken, followingTokenIndex) = nextNotWhitespace(searchDescription) else {
			return nil
		}
		switch followingToken {
		case .attribute(let attributeName):
			return (attributeName, followingTokenIndex)
		default:
			return nil
		}
	}
	
	
	/// Returns the first token from `searchDescription.index` that does not represent whitespace.
	private func nextNotWhitespace(_ searchDescription: SearchDescription) -> (token: Token, index: Int)? {
		for searchIndex in (searchDescription.startIndex)..<searchDescription.tokenList.count {
			let token = searchDescription.tokenList[searchIndex].token
			if !Token.whitespace.contains(token) {
				return (token, searchIndex)
			}
		}
		return nil
	}
	
	/// Finds the next binary operator directly following `searchDescription.index`, ignoring any whitespace.
	private func binaryOperator(_ searchDescription: SearchDescription) -> ParserToken.BinaryOperator? {
		switch nextNotWhitespace(searchDescription)?.token {
		case .operator(let someOperator):
			return ParserToken.BinaryOperator(rawValue: someOperator.rawValue)
		default:
			return nil
		}
	}
	
	/// Returns true if the given token is found directly following the token at `index` in `tokenList`.
	private func canFindPostfix(_ postfix: Token, forTokenAt index: Int, in tokenList: [(token: Token, range: Range<String.Index>)]) -> Bool {
		var searchIndex = index + 1
		while tokenList[searchIndex].token != postfix {
			if tokenList[searchIndex].token != .punctuation(.space)
				&& tokenList[searchIndex].token != .punctuation(.tab) {
				return false
			}
			searchIndex += 1
			if searchIndex == tokenList.count {
				return false
			}
		}
		return true
	}
	
	/// Returns true if the given token is found directly before the token at `index` in `tokenList`.
	private func existsPrefix(_ prefix: Token, forTokenAt index: Int, in tokenList: [(token: Token, range: Range<String.Index>)]) -> Bool {
		var searchIndex = index - 1
		while tokenList[searchIndex].token != prefix {
			if tokenList[searchIndex].token != .punctuation(.space)
				&& tokenList[searchIndex].token != .punctuation(.tab) {
				return false
			}
			searchIndex -= 1
			if searchIndex == -1 {
				return false
			}
		}
		return true
	}
	
	// MARK: - Private helpers
	
	/// Removes characters at the start of a string, until the first character is not found in the restriction string.
	/// - parameter restrictionString: The string containing characters to be removed.
	/// - parameter string: The string from which the prefix is to be removed.
	private func removePrefix(ofCharactersIn restrictionString: String, from string: String) -> String {
		var outputString = string
		while let first = outputString.first,
			restrictionString.contains(first) {
				_ = outputString.removeFirst()
		}
		return outputString
	}
	
	// MARK: - Types
	
	/// Represents a comment that must be marked out to the user.
	struct NotableComment {
		let title: String
		let index: Int
	}
	
	// MARK: - Errors
	
	/// Represents an error
	struct ParsingError {
		let description: String
		let range: Range<String.Index>
	}
	
	/// Indicates an attribute that has not been defined in its scope.
	private func undefinedAttributeError(_ range: Range<String.Index>) -> ParsingError {
		return ParsingError(description: "Undefined attribute \(code[range])", range: range)
	}
	
	/// Indicates a binary operator that has no leading argument.
	private func floatingOperatorError(_ range: Range<String.Index>) -> ParsingError {
		return ParsingError(description: "Floating operator: Operators must be led by a value or an expression.", range: range)
	}
	
	/// Indicates the failure to locate an expected token following a keyword.
	/// - parameter expectation: A human-readable string describing the expected token.
	/// - parameter range: The range of the keyword that indicates the expectation.
	private func expectationError(expected expectation: String, afterKeywordAt range: Range<String.Index>) -> ParsingError {
		return ParsingError(description: "Expected \(expectation) to follow this keyword.", range: range)
	}
	
	/// Indicates the failure to locate an expected token.
	///
	/// - parameter expectation: A human-readable string describing the expected token.
	/// - parameter range: The range of the token found indstead of the expected token.
	private func expectationError(expected expectation: String, at range: Range<String.Index>) -> ParsingError {
		return ParsingError(description: "Expected \(expectation) to follow.", range: range)
	}
	
	// MARK: - Searching
	
	
	private struct SearchDescription {
		let startIndex: Int
		let tokenList: [(token: Token, range: Range<String.Index>)]
		let code: String
		
		var rangeAtIndex: Range<String.Index> {
			return tokenList[startIndex].range
		}
		
		static func at(_ index: Int, in tokenList: [(token: Token, range: Range<String.Index>)], code: String) -> SearchDescription {
			self.init(startIndex: index, tokenList: tokenList, code: code)
		}
		
		static func searchBefore(_ index: Int, in tokenList: [(token: Token, range: Range<String.Index>)], code: String) -> SearchDescription {
			self.init(startIndex: index - 1, tokenList: tokenList, code: code)
		}
		
		static func searchAfter(_ index: Int, in tokenList: [(token: Token, range: Range<String.Index>)], code: String) -> SearchDescription {
			self.init(startIndex: index + 1, tokenList: tokenList, code: code)
		}
		static func searchAfter(_ searchDescription: SearchDescription) -> SearchDescription {
			self.init(
				startIndex: searchDescription.startIndex + 1,
				tokenList: searchDescription.tokenList,
				code: searchDescription.code
			)
		}
		
		static func searchBefore(_ searchDescription: SearchDescription) -> SearchDescription {
			self.init(
				startIndex: searchDescription.startIndex - 1,
				tokenList: searchDescription.tokenList,
				code: searchDescription.code
			)
		}
	}
}
