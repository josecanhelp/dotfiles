"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Motion_1 = require("./Motion");
class MotionLine extends Motion_1.Motion {
    constructor() {
        super(...arguments);
        this.shouldToFirstNonBlank = false;
    }
    static firstNonBlank() {
        const obj = new MotionLine();
        obj.shouldToFirstNonBlank = true;
        return obj;
    }
    static start() {
        const obj = new MotionLine();
        obj.translate(0, -Infinity);
        return obj;
    }
    static end() {
        const obj = new MotionLine();
        obj.translate(0, +Infinity);
        return obj;
    }
    apply(from) {
        from = super.apply(from);
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor || !this.shouldToFirstNonBlank) {
            return from;
        }
        const document = activeTextEditor.document;
        const line = document.lineAt(from.line);
        return from.with(undefined, line.firstNonWhitespaceCharacterIndex);
    }
}
exports.MotionLine = MotionLine;
//# sourceMappingURL=Line.js.map