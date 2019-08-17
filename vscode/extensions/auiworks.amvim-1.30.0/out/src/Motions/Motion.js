"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class Motion {
    constructor(args = {}) {
        this.lineDelta = 0;
        this.characterDelta = 0;
        this.isLinewise = args.isLinewise === undefined ? false : args.isLinewise;
        this.isCharacterUpdated = args.isCharacterUpdated === undefined ? true : args.isCharacterUpdated;
    }
    translate(lineDelta, characterDelta) {
        this.lineDelta += lineDelta;
        this.characterDelta += characterDelta;
    }
    apply(from, option) {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return from;
        }
        const document = activeTextEditor.document;
        let toLine = from.line + this.lineDelta;
        let toCharacter = from.character + this.characterDelta;
        if (toLine < 0) {
            toLine = 0;
            toCharacter = 0;
        }
        else if (toLine > document.lineCount - 1) {
            toLine = document.lineCount - 1;
            toCharacter = Infinity;
        }
        if (toCharacter === Infinity) {
            toCharacter = document.lineAt(toLine).text.length;
        }
        const preferredColumn = !this.isCharacterUpdated && option
            ? option.preferredColumn : null;
        if (preferredColumn) {
            const tabSize = activeTextEditor.options.tabSize;
            const toLineText = document.lineAt(toLine).text;
            let lastColumn = -1;
            let thisColumn = 0;
            let i;
            for (i = 0; i < toLineText.length && thisColumn <= preferredColumn; i++) {
                lastColumn = thisColumn;
                thisColumn += toLineText.charAt(i) === '\t' ? tabSize : 1;
            }
            // Choose the closest
            const thisColumnDiff = Math.abs(preferredColumn - thisColumn);
            const lastColumnDiff = Math.abs(preferredColumn - lastColumn);
            toCharacter = thisColumnDiff < lastColumnDiff ? i : i - 1;
        }
        toCharacter = Math.max(toCharacter, 0);
        return activeTextEditor.document.validatePosition(new vscode_1.Position(toLine, toCharacter));
    }
}
exports.Motion = Motion;
//# sourceMappingURL=Motion.js.map