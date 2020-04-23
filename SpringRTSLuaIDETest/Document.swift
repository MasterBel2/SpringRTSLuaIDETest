//
//  Document.swift
//  SpringRTSLuaIDETest
//
//  Created by Derek Bel on 22/4/20.
//  Copyright © 2020 MasterBel2. All rights reserved.
//

import Cocoa

class Document: NSDocument, NSTextViewDelegate, NSTextStorageDelegate {

    enum Error: Swift.Error {
        case encodingError
    }

    var plainCode: String {
        return presentationCode.string
    }
	
	// MARK: - Workers
	
	let lexer = BaseLexer()
	let presenter = CodePresenter()
	
	// MARK: - Outlets
	
    @objc dynamic var presentationCode = NSAttributedString()
    @IBOutlet var textView: NSTextView!
	
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

//    func process() {
//        do {
//            let lexer = try Lexer(code: presentationCode.string)
//            let tokenRangePairs = try lexer.tokenRangePairs2()
//            guard let mutableString = presentationCode.mutableCopy() as? NSMutableAttributedString else {
//                return
//            }
//            Highlighter().highlight(mutableString, with: tokenRangePairs)
//            presentationCode = mutableString
//        } catch {
//            Swift.print(error)
//        }
//    }

    // MARK: - NSTextViewDelegate
	
	func textDidChange(_ notification: Notification) {
		Swift.print("textDidChange")
		update()
	}
	
	private func update() {
		guard let code = textView.textStorage?.string else { return }
		let tokens = lexer.lex(code)
		presenter.updateCode(code, shownIn: textView, with: tokens)
	}
	
	// MARK: - NSTextStorageDelegate
	
//	func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
//		Swift.print("didProcessEditing")
//		update()
//	}
}

