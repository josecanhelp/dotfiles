"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Motion_1 = require("./Motion");
const Block_1 = require("../TextObjects/Block");
class MotionMatchPair extends Motion_1.Motion {
    static matchPair() {
        return new MotionMatchPair();
    }
    apply(from, option = {}) {
        option.isInclusive = option.isInclusive === undefined ? false : option.isInclusive;
        from = super.apply(from);
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return from;
        }
        const document = activeTextEditor.document;
        const targetText = document.lineAt(from.line).text;
        for (let character = from.character; character < targetText.length; character++) {
            const currentCharacterString = targetText[character];
            if (MotionMatchPair.matchCharacters.indexOf(currentCharacterString) < 0) {
                continue;
            }
            const textObject = MotionMatchPair.characterMap[currentCharacterString]({});
            if (MotionMatchPair.openingCharacters.indexOf(currentCharacterString) < 0) {
                const startRange = textObject.findStartRange(document, new vscode_1.Position(from.line, character));
                if (startRange !== null) {
                    return startRange.start;
                }
            }
            else {
                const endRange = textObject.findEndRange(document, new vscode_1.Position(from.line, character));
                if (endRange !== null) {
                    return option.isInclusive ? endRange.end : endRange.start;
                }
            }
            return from;
        }
        return from;
    }
}
// TODO: C-style comments (/* */) and C preprocessor conditionals are not supported for now
MotionMatchPair.openingCharacterMap = {
    '(': Block_1.TextObjectBlock.byParentheses,
    '{': Block_1.TextObjectBlock.byBraces,
    '[': Block_1.TextObjectBlock.byBrackets,
};
MotionMatchPair.openingCharacters = Object.keys(MotionMatchPair.openingCharacterMap);
MotionMatchPair.closingCharacterMap = {
    ')': Block_1.TextObjectBlock.byParentheses,
    '}': Block_1.TextObjectBlock.byBraces,
    ']': Block_1.TextObjectBlock.byBrackets,
};
MotionMatchPair.characterMap = Object.assign({}, MotionMatchPair.openingCharacterMap, MotionMatchPair.closingCharacterMap);
MotionMatchPair.matchCharacters = Object.keys(MotionMatchPair.characterMap);
exports.MotionMatchPair = MotionMatchPair;
//# sourceMappingURL=MatchPair.js.map