"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const TextObject_1 = require("./TextObject");
class TextObjectQuotedString extends TextObject_1.TextObject {
    constructor() {
        super(...arguments);
        this.willFindForward = true;
    }
    static bySingle(args) {
        const obj = new TextObjectQuotedString();
        obj.isInclusive = args.isInclusive;
        obj.quoteCharacter = '\'';
        return obj;
    }
    static byDouble(args) {
        const obj = new TextObjectQuotedString();
        obj.isInclusive = args.isInclusive;
        obj.quoteCharacter = '"';
        return obj;
    }
    static byBackward(args) {
        const obj = new TextObjectQuotedString();
        obj.isInclusive = args.isInclusive;
        obj.quoteCharacter = '`';
        return obj;
    }
    findStartRange(document, anchor) {
        const lineIndex = anchor.line;
        const lineText = document.lineAt(lineIndex).text;
        let characterIndex = anchor.character - 1;
        while (characterIndex >= 0) {
            const characterEscaped = lineText[characterIndex - 1] === TextObjectQuotedString.escapeCharacter;
            if (lineText[characterIndex] === this.quoteCharacter && !characterEscaped) {
                this.adjustedAnchor = new vscode_1.Position(lineIndex, anchor.character);
                return new vscode_1.Range(lineIndex, characterIndex, lineIndex, characterIndex + 1);
            }
            characterIndex--;
        }
        characterIndex = anchor.character;
        while (characterIndex < lineText.length) {
            const characterEscaped = lineText[characterIndex - 1] === TextObjectQuotedString.escapeCharacter;
            if (lineText[characterIndex] === this.quoteCharacter && !characterEscaped) {
                this.adjustedAnchor = new vscode_1.Position(lineIndex, characterIndex + 1);
                return new vscode_1.Range(lineIndex, characterIndex, lineIndex, characterIndex + 1);
            }
            characterIndex++;
        }
        return null;
    }
    findEndRange(document, anchor) {
        if (this.adjustedAnchor !== undefined) {
            anchor = this.adjustedAnchor;
        }
        const lineIndex = anchor.line;
        const lineText = document.lineAt(lineIndex).text;
        let characterIndex = anchor.character;
        while (characterIndex < lineText.length) {
            const characterEscaped = lineText[characterIndex - 1] === TextObjectQuotedString.escapeCharacter;
            if (lineText[characterIndex] === this.quoteCharacter && !characterEscaped) {
                return new vscode_1.Range(lineIndex, characterIndex, lineIndex, characterIndex + 1);
            }
            characterIndex++;
        }
        return null;
    }
}
TextObjectQuotedString.escapeCharacter = '\\';
exports.TextObjectQuotedString = TextObjectQuotedString;
//# sourceMappingURL=QuotedString.js.map