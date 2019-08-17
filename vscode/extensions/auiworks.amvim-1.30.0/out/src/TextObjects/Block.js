"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const TextObject_1 = require("./TextObject");
class TextObjectBlock extends TextObject_1.TextObject {
    constructor() {
        super(...arguments);
        this.shouldExpandToLinewise = true;
    }
    static byParentheses(args) {
        const obj = new TextObjectBlock();
        obj.isInclusive = args.isInclusive;
        obj.openingCharacter = '(';
        obj.closingCharacter = ')';
        return obj;
    }
    static byBrackets(args) {
        const obj = new TextObjectBlock();
        obj.isInclusive = args.isInclusive;
        obj.openingCharacter = '[';
        obj.closingCharacter = ']';
        return obj;
    }
    static byBraces(args) {
        const obj = new TextObjectBlock();
        obj.isInclusive = args.isInclusive;
        obj.openingCharacter = '{';
        obj.closingCharacter = '}';
        return obj;
    }
    static byChevrons(args) {
        const obj = new TextObjectBlock();
        obj.isInclusive = args.isInclusive;
        obj.openingCharacter = '<';
        obj.closingCharacter = '>';
        return obj;
    }
    findStartRange(document, anchor) {
        let matchingCount = 0;
        let lineIndex = anchor.line;
        do {
            const lineText = document.lineAt(lineIndex).text;
            let characterIndex = lineIndex === anchor.line ? anchor.character : lineText.length - 1;
            while (characterIndex >= 0) {
                if (lineText[characterIndex] === this.closingCharacter) {
                    // Don't count closing character on anchor.
                    if (!anchor.isEqual(new vscode_1.Position(lineIndex, characterIndex))) {
                        matchingCount++;
                    }
                }
                else if (lineText[characterIndex] === this.openingCharacter) {
                    if (matchingCount === 0) {
                        return new vscode_1.Range(lineIndex, characterIndex, lineIndex, characterIndex + 1);
                    }
                    else {
                        matchingCount--;
                    }
                }
                characterIndex--;
            }
            lineIndex--;
        } while (lineIndex >= 0);
        return null;
    }
    findEndRange(document, anchor) {
        let matchingCount = 0;
        let lineIndex = anchor.line;
        do {
            const line = document.lineAt(lineIndex);
            const lineText = line.text;
            let characterIndex = lineIndex === anchor.line ? anchor.character : 0;
            while (characterIndex < lineText.length) {
                if (lineText[characterIndex] === this.openingCharacter) {
                    // Don't count opening character on anchor.
                    if (!anchor.isEqual(new vscode_1.Position(lineIndex, characterIndex))) {
                        matchingCount++;
                    }
                }
                else if (lineText[characterIndex] === this.closingCharacter) {
                    if (matchingCount === 0) {
                        return new vscode_1.Range(lineIndex, characterIndex, lineIndex, characterIndex + 1);
                    }
                    else {
                        matchingCount--;
                    }
                }
                characterIndex++;
            }
            lineIndex++;
        } while (lineIndex < document.lineCount);
        return null;
    }
}
exports.TextObjectBlock = TextObjectBlock;
//# sourceMappingURL=Block.js.map