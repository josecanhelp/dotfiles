"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const Base_1 = require("./Base");
class VerticalNewFileCommand extends Base_1.Command {
    execute() {
        return vscode.commands.executeCommand('workbench.action.files.newUntitledFile')
            .then(() => vscode.commands.executeCommand('workbench.action.moveEditorToNextGroup'));
    }
}
exports.VerticalNewFileCommand = VerticalNewFileCommand;
//# sourceMappingURL=VerticalNewFile.js.map