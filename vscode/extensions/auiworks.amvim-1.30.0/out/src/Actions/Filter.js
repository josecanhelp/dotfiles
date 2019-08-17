"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const MoveCursor_1 = require("./MoveCursor");
const Selection_1 = require("./Selection");
const Reveal_1 = require("./Reveal");
class Format {
    static bySelections() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        if (activeTextEditor.selections.length === 0
            || activeTextEditor.selections.every((selection) => selection.isEmpty)) {
            return Promise.resolve(false);
        }
        return vscode_1.commands.executeCommand('editor.action.formatSelection');
    }
    static byCursors() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const originalSelections = activeTextEditor.selections;
        return Selection_1.ActionSelection.expandToLine()
            .then(() => {
            return vscode_1.commands.executeCommand('editor.action.formatSelection');
        })
            .then(() => {
            activeTextEditor.selections = originalSelections;
            return Promise.resolve(true);
        })
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static byMotions(args) {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const originalSelections = activeTextEditor.selections;
        return MoveCursor_1.ActionMoveCursor.byMotions({
            motions: args.motions,
            isVisualLineMode: true,
        })
            .then(() => {
            return vscode_1.commands.executeCommand('editor.action.formatSelection');
        })
            .then(() => {
            activeTextEditor.selections = originalSelections;
            return Promise.resolve(true);
        })
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
}
exports.ActionFilter = {
    Format: Format
};
//# sourceMappingURL=Filter.js.map