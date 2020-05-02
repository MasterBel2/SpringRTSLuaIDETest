//
//  Document.swift
//  SpringRTSLuaIDETest
//
//  Created by MasterBel2 on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Cocoa

final class Document: NSDocument, NSTextViewDelegate, NSTextStorageDelegate {

    enum Error: Swift.Error {
        case encodingError
    }

    var plainCode: String {
        return presentationCode.string
    }
	
	// MARK: - Workers
	
	let lexer = BaseLexer()
	let parser = ContextParser(startIndex: 0, parent: nil, globalContext: GlobalContext(), terminators: [])
	let presenter = CodePresenter()
	
	// MARK: - Outlets
	
    @objc dynamic var presentationCode = NSAttributedString()
    @IBOutlet var codeView: NSTextView!
	@objc dynamic var documentation = NSAttributedString()
	@IBOutlet var documentationView: NSTextView!
	
	// MARK: -
	
	// MARK: - Cocoa

    override init() {
        super.init()
    }
	
	// MARK: - Data

    override class var autosavesInPlace: Bool {
        return true
    }

    override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return NSNib.Name("Document")
    }

    override func data(ofType typeName: String) throws -> Data {
        guard let data = plainCode.data(using: .utf8) else {
            throw Error.encodingError
        }

        return data
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let fileContent = String(data: data, encoding: .utf8) else {
            throw Error.encodingError
        }
        presentationCode = NSMutableAttributedString(string: fileContent)
    }

    // MARK: - NSTextViewDelegate
	
	func textViewDidChangeSelection(_ notification: Notification) {
		guard let rangeInCode = Range(codeView.selectedRange(), in: plainCode),
		let documentationString = parser.documentation(forAttributeIn: rangeInCode) else {
			documentation = NSAttributedString(string: "")
			return
		}
		
		documentation = NSAttributedString(string: documentationString)
	}
	
	func textDidChange(_ notification: Notification) {
		Swift.print("textDidChange")
		update()
	}
	
	private func update() {
		guard let code = codeView.textStorage?.string else { return }
		var tokens: [(token: Token, range: Range<String.Index>)] = []
		_ = lexer.lex(code, into: &tokens, startingFrom: code.startIndex, resignAt: code.endIndex)
		presenter.update(code, shownIn: NSRange(code.startIndex..<code.endIndex, in: code), in: codeView, with: tokens)
		benchmarker.benchmark("Parsing", shouldResetClock: true) {
			_ = parser.parse(tokens, from: code, startingFrom: 0)
		}
		benchmarker.printReport()
		presenter.update(code, shownIn: NSRange(code.startIndex..<code.endIndex, in: code), in: codeView, with: parser.errors)
		presenter.update(code, describedBy: tokens, shownIn: NSRange(code.startIndex..<code.endIndex, in: code), in: codeView, with: parser.attributeReferences)
	}
	
	// MARK: - NSTextStorageDelegate
}
