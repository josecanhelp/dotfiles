"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Selection_1 = require("./Selection");
class ActionHistory {
    static undo() {
        return vscode_1.commands.executeCommand('undo')
            .then(() => Selection_1.ActionSelection.shrinkToActives());
    }
    static redo() {
        return vscode_1.commands.executeCommand('redo')
            .then(() => Selection_1.ActionSelection.shrinkToActives());
    }
}
exports.ActionHistory = ActionHistory;
//# sourceMappingURL=History.js.map