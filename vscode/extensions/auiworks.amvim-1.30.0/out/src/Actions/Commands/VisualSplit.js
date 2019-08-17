"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const Base_1 = require("./Base");
class VerticalSplitCommand extends Base_1.Command {
    execute() {
        return vscode.commands.executeCommand('workbench.action.splitEditor');
    }
}
exports.VerticalSplitCommand = VerticalSplitCommand;
//# sourceMappingURL=VisualSplit.js.map