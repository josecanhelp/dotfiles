"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class UtilPosition {
    /**
     * Get visual column from position.
     */
    static getColumn(textEditor, position) {
        const text = textEditor.document.lineAt(position.line).text;
        const tabSize = textEditor.options.tabSize;
        let column = 0;
        for (let character = 0; character < position.character; character++) {
            column += text.charAt(character) === '\t' ? tabSize : 1;
        }
        return column;
    }
}
exports.UtilPosition = UtilPosition;
//# sourceMappingURL=Position.js.map