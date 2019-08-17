"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const Base_1 = require("./Base");
class NewFileCommand extends Base_1.Command {
    execute() {
        return vscode.commands.executeCommand('workbench.action.files.newUntitledFile');
    }
}
exports.NewFileCommand = NewFileCommand;
//# sourceMappingURL=NewFile.js.map