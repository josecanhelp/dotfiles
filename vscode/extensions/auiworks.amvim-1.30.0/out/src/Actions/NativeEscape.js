"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class ActionNativeEscape {
    static press() {
        return Promise.resolve(true)
            .then(() => vscode_1.commands.executeCommand('leaveSnippet'))
            .then(() => vscode_1.commands.executeCommand('closeParameterHints'))
            .then(() => vscode_1.commands.executeCommand('hideSuggestWidget'));
    }
}
exports.ActionNativeEscape = ActionNativeEscape;
//# sourceMappingURL=NativeEscape.js.map