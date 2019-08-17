"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class ActionRelativeLineNumbers {
    static on() {
        return new Promise((resolve) => {
            setTimeout(() => {
                const activeTextEditor = vscode_1.window.activeTextEditor;
                if (!activeTextEditor) {
                    return resolve(false);
                }
                if (activeTextEditor.options.lineNumbers === vscode_1.TextEditorLineNumbersStyle.Off) {
                    return resolve(false);
                }
                activeTextEditor.options.lineNumbers = vscode_1.TextEditorLineNumbersStyle.Relative;
                resolve(true);
            }, 0);
        });
    }
    static off() {
        return new Promise((resolve) => {
            setTimeout(() => {
                const activeTextEditor = vscode_1.window.activeTextEditor;
                if (!activeTextEditor) {
                    return resolve(false);
                }
                if (activeTextEditor.options.lineNumbers === vscode_1.TextEditorLineNumbersStyle.Off) {
                    return resolve(false);
                }
                activeTextEditor.options.lineNumbers = vscode_1.TextEditorLineNumbersStyle.On;
                resolve(true);
            }, 0);
        });
    }
}
exports.ActionRelativeLineNumbers = ActionRelativeLineNumbers;
//# sourceMappingURL=RelativeLineNumbers.js.map