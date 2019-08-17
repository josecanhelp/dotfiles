"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class ActionBlockCursor {
    static on() {
        return new Promise((resolve) => {
            setTimeout(() => {
                const activeTextEditor = vscode_1.window.activeTextEditor;
                if (!activeTextEditor) {
                    return Promise.resolve(false);
                }
                activeTextEditor.options.cursorStyle = vscode_1.TextEditorCursorStyle.Block;
                resolve(true);
            }, 0);
        });
    }
    static off() {
        return new Promise((resolve) => {
            setTimeout(() => {
                const activeTextEditor = vscode_1.window.activeTextEditor;
                if (!activeTextEditor) {
                    return Promise.resolve(false);
                }
                activeTextEditor.options.cursorStyle = vscode_1.TextEditorCursorStyle.Line;
                resolve(true);
            }, 0);
        });
    }
}
exports.ActionBlockCursor = ActionBlockCursor;
//# sourceMappingURL=BlockCursor.js.map