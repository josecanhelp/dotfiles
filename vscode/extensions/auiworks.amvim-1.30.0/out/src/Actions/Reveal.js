"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class ActionReveal {
    static primaryCursor(args = {}) {
        args.revealType = args.revealType === undefined ? vscode_1.TextEditorRevealType.Default : args.revealType;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const activePosition = activeTextEditor.selection.active;
        activeTextEditor.revealRange(new vscode_1.Range(activePosition, activePosition), args.revealType);
        return Promise.resolve(true);
    }
}
exports.ActionReveal = ActionReveal;
//# sourceMappingURL=Reveal.js.map