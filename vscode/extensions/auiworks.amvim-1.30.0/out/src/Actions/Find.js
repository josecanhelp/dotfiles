"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Selection_1 = require("./Selection");
class ActionFind {
    static focusFindWidget() {
        return vscode_1.commands.executeCommand('actions.find');
    }
    static executeNativeFind() {
        return vscode_1.commands.executeCommand('workbench.action.focusActiveEditorGroup')
            .then(Selection_1.ActionSelection.shrinkToEnds);
    }
    // TODO: Implement independent find function to avoid incorrect cursor position after `next()`
    static byIndicator() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        activeTextEditor.selection = new vscode_1.Selection(activeTextEditor.selection.active, activeTextEditor.selection.active);
        return vscode_1.commands.executeCommand('editor.action.addSelectionToNextFindMatch');
    }
    static next() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        return vscode_1.commands.executeCommand('editor.action.nextMatchFindAction')
            .then(() => {
            vscode_1.window.showTextDocument(activeTextEditor.document, activeTextEditor.viewColumn);
            activeTextEditor.selection = new vscode_1.Selection(activeTextEditor.selection.end, activeTextEditor.selection.end);
            return Promise.resolve(true);
        });
    }
    static prev() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        return vscode_1.commands.executeCommand('editor.action.previousMatchFindAction')
            .then(() => {
            vscode_1.window.showTextDocument(activeTextEditor.document, activeTextEditor.viewColumn);
            activeTextEditor.selection = new vscode_1.Selection(activeTextEditor.selection.start, activeTextEditor.selection.start);
            return Promise.resolve(true);
        });
    }
}
exports.ActionFind = ActionFind;
//# sourceMappingURL=Find.js.map