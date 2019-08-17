"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const Base_1 = require("./Base");
class WriteQuitCommand extends Base_1.Command {
    execute() {
        if (!vscode.window.activeTextEditor) {
            return Promise.resolve(false);
        }
        return vscode.window.activeTextEditor.document.save()
            .then(() => vscode.commands.executeCommand('workbench.action.closeActiveEditor'));
    }
}
exports.WriteQuitCommand = WriteQuitCommand;
//# sourceMappingURL=WriteQuit.js.map