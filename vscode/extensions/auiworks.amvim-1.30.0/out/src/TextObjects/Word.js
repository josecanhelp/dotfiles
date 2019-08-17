"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const TextObject_1 = require("./TextObject");
const Word_1 = require("../Utils/Word");
class TextObjectWord extends TextObject_1.TextObject {
    static byWord(args) {
        const obj = new TextObjectWord();
        obj.isInclusive = args.isInclusive;
        obj.useBlankSeparatedStyle = args.useBlankSeparatedStyle;
        return obj;
    }
    findStartRange(document, anchor) {
        const lineIndex = anchor.line;
        const lineText = document.lineAt(lineIndex).text;
        const anchorCharacterKind = Word_1.UtilWord.getCharacterKind(lineText.charCodeAt(anchor.character), this.useBlankSeparatedStyle);
        let exclusiveCharacterIndex = 0;
        for (let characterIndex = anchor.character - 1; characterIndex >= 0; characterIndex--) {
            const characterKind = Word_1.UtilWord.getCharacterKind(lineText.charCodeAt(characterIndex), this.useBlankSeparatedStyle);
            if (characterKind !== anchorCharacterKind) {
                exclusiveCharacterIndex = characterIndex + 1;
                break;
            }
        }
        let inclusiveCharacterIndex = 0;
        for (let characterIndex = exclusiveCharacterIndex - 1; characterIndex >= 0; characterIndex--) {
            const characterKind = Word_1.UtilWord.getCharacterKind(lineText.charCodeAt(characterIndex), this.useBlankSeparatedStyle);
            if (characterKind !== Word_1.WordCharacterKind.Blank) {
                inclusiveCharacterIndex = characterIndex + 1;
                break;
            }
        }
        return new vscode_1.Range(lineIndex, inclusiveCharacterIndex, lineIndex, exclusiveCharacterIndex);
    }
    findEndRange(document, anchor) {
        const lineIndex = anchor.line;
        const lineText = document.lineAt(lineIndex).text;
        const anchorCharacterKind = Word_1.UtilWord.getCharacterKind(lineText.charCodeAt(anchor.character), this.useBlankSeparatedStyle);
        let exclusiveCharacterIndex = lineText.length - 1;
        for (let characterIndex = anchor.character + 1; characterIndex < lineText.length; characterIndex++) {
            const characterKind = Word_1.UtilWord.getCharacterKind(lineText.charCodeAt(characterIndex), this.useBlankSeparatedStyle);
            if (characterKind !== anchorCharacterKind) {
                exclusiveCharacterIndex = characterIndex - 1;
                break;
            }
        }
        let inclusiveCharacterIndex = lineText.length - 1;
        if (exclusiveCharacterIndex < lineText.length - 1) {
            const includeCharacterKind = anchorCharacterKind === Word_1.WordCharacterKind.Blank
                ? Word_1.UtilWord.getCharacterKind(lineText.charCodeAt(exclusiveCharacterIndex + 1), this.useBlankSeparatedStyle)
                : Word_1.WordCharacterKind.Blank;
            for (let characterIndex = exclusiveCharacterIndex + 1; characterIndex < lineText.length; characterIndex++) {
                const characterKind = Word_1.UtilWord.getCharacterKind(lineText.charCodeAt(characterIndex), this.useBlankSeparatedStyle);
                if (characterKind !== includeCharacterKind) {
                    inclusiveCharacterIndex = characterIndex - 1;
                    break;
                }
            }
        }
        return new vscode_1.Range(lineIndex, exclusiveCharacterIndex + 1, lineIndex, inclusiveCharacterIndex + 1);
    }
    createRangeDueToIsInclusive(startRange, endRange) {
        if (this.isInclusive) {
            // From Vim documentation:
            // "Any trailing white space is included, unless there is none, then leading white space is included."
            if (!endRange.isEmpty) {
                return new vscode_1.Range(startRange.end, endRange.end);
            }
            else {
                return new vscode_1.Range(startRange.start, endRange.start);
            }
        }
        else {
            return new vscode_1.Range(startRange.end, endRange.start);
        }
    }
}
exports.TextObjectWord = TextObjectWord;
//# sourceMappingURL=Word.js.map