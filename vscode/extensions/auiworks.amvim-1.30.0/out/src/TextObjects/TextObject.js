"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Range_1 = require("../Utils/Range");
class TextObject {
    constructor() {
        this.shouldExpandToLinewise = false;
        this.willFindForward = false;
        this._isLinewise = false;
    }
    get isLinewise() { return this._isLinewise; }
    /**
     * Override this to return start range of text object or null if not found.
     */
    findStartRange(document, anchor) {
        throw new Error('findStartPosition is not implemented.');
    }
    /**
     * Override this to return end range of text object or null if not found.
     */
    findEndRange(document, anchor) {
        throw new Error('findEndPosition is not implemented.');
    }
    apply(anchor) {
        if (this.isInclusive === undefined) {
            throw new Error('isInclusive is not set.');
        }
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return null;
        }
        const document = activeTextEditor.document;
        const startRange = this.findStartRange(document, anchor);
        if (startRange === null) {
            return null;
        }
        const endRange = this.findEndRange(document, anchor);
        if (endRange === null) {
            return null;
        }
        let range = this.createRangeDueToIsInclusive(startRange, endRange);
        if (this.shouldExpandToLinewise) {
            range = this.tryExpandToLinewise(range, document);
        }
        return range;
    }
    createRangeDueToIsInclusive(startRange, endRange) {
        return this.isInclusive
            ? new vscode_1.Range(startRange.start, endRange.end)
            : new vscode_1.Range(startRange.end, endRange.start);
    }
    tryExpandToLinewise(range, document) {
        if (range.isSingleLine) {
            return range;
        }
        const startLine = document.lineAt(range.start.line);
        const endLine = document.lineAt(range.start.line);
        if (this.isInclusive) {
            if (range.start.character === startLine.firstNonWhitespaceCharacterIndex
                && range.end.character === endLine.text.length) {
                range = Range_1.UtilRange.toLinewise(range, document);
                this._isLinewise = true;
            }
        }
        else {
            if (range.start.character === startLine.text.length
                && range.end.character === endLine.firstNonWhitespaceCharacterIndex) {
                range = new vscode_1.Range(range.start.line + 1, 0, range.end.line, 0);
                this._isLinewise = true;
            }
        }
        return range;
    }
}
exports.TextObject = TextObject;
//# sourceMappingURL=TextObject.js.map