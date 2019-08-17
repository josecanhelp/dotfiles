"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const Base_1 = require("./Base");
class QuitAllCommand extends Base_1.Command {
    execute() {
        return vscode.commands.executeCommand('workbench.action.closeAllEditors');
    }
}
exports.QuitAllCommand = QuitAllCommand;
//# sourceMappingURL=QuitAll.js.map