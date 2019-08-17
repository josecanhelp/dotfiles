"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const Base_1 = require("./Base");
class WriteQuitAllCommand extends Base_1.Command {
    execute() {
        return vscode.workspace.saveAll(true)
            .then(() => vscode.commands.executeCommand('workbench.action.closeAllEditors'));
    }
}
exports.WriteQuitAllCommand = WriteQuitAllCommand;
//# sourceMappingURL=WriteQuitAll.js.map