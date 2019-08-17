"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class ActionFold {
    static fold() {
        return vscode_1.commands.executeCommand('editor.fold');
    }
    static unfold() {
        return vscode_1.commands.executeCommand('editor.unfold');
    }
    static foldAll() {
        return vscode_1.commands.executeCommand('editor.foldAll');
    }
    static unfoldAll() {
        return vscode_1.commands.executeCommand('editor.unfoldAll');
    }
}
exports.ActionFold = ActionFold;
//# sourceMappingURL=Fold.js.map