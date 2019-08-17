"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const Base_1 = require("./Base");
class QuitCommand extends Base_1.Command {
    execute() {
        return vscode.commands.executeCommand('workbench.action.closeActiveEditor');
    }
}
exports.QuitCommand = QuitCommand;
//# sourceMappingURL=Quit.js.map