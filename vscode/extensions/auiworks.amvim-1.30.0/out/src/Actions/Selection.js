"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const extension_1 = require("../extension");
const Mode_1 = require("../Modes/Mode");
const Selection_1 = require("../Utils/Selection");
const Range_1 = require("../Utils/Range");
class ActionSelection {
    static validateSelections() {
        const currentMode = extension_1.getCurrentMode();
        if (currentMode !== null && currentMode.id === Mode_1.ModeID.INSERT) {
            return Promise.resolve(true);
        }
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const document = activeTextEditor.document;
        let isChanged = false;
        const validatedSelections = activeTextEditor.selections.map(selection => {
            if (!selection.isEmpty) {
                return selection;
            }
            const position = selection.active;
            const endCharacter = document.lineAt(position).range.end.character;
            const maxCharacter = endCharacter > 0 ? endCharacter - 1 : endCharacter;
            if (position.character > maxCharacter) {
                isChanged = true;
                return new vscode_1.Selection(position.line, maxCharacter, position.line, maxCharacter);
            }
            else {
                return selection;
            }
        });
        if (isChanged) {
            activeTextEditor.selections = validatedSelections;
        }
        return Promise.resolve(true);
    }
    static shrinkToPrimaryActive() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        activeTextEditor.selection = Selection_1.UtilSelection.shrinkToActive(activeTextEditor.selection);
        return Promise.resolve(true);
    }
    static shrinkToActives() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        if (activeTextEditor.selections.every(selection => selection.isEmpty)) {
            return Promise.resolve(false);
        }
        activeTextEditor.selections = Selection_1.UtilSelection.shrinkToActives(activeTextEditor.selections);
        return Promise.resolve(true);
    }
    static shrinkToStarts() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        activeTextEditor.selections = activeTextEditor.selections.map(selection => {
            return new vscode_1.Selection(selection.start, selection.start);
        });
        return Promise.resolve(true);
    }
    static shrinkToEnds() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        activeTextEditor.selections = activeTextEditor.selections.map(selection => {
            return new vscode_1.Selection(selection.end, selection.end);
        });
        return Promise.resolve(true);
    }
    static expandToOne() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        activeTextEditor.selections = activeTextEditor.selections.map(selection => {
            return selection.isEmpty
                ? new vscode_1.Selection(selection.anchor, selection.anchor.translate(0, +1))
                : selection;
        });
        return Promise.resolve(true);
    }
    static expandByTextObject(args) {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        let selections = [];
        activeTextEditor.selections.forEach(selection => {
            let positionToApply;
            if (selection.isEmpty || Range_1.UtilRange.isSingleCharacter(selection)) {
                positionToApply = selection.start;
            }
            else {
                positionToApply = Selection_1.UtilSelection.getActiveInVisualMode(selection);
                if (selection.isReversed && positionToApply.character > 0) {
                    positionToApply = positionToApply.translate(0, -1);
                }
                else if (!selection.isReversed) {
                    positionToApply = positionToApply.translate(0, +1);
                }
            }
            const match = args.textObject.apply(positionToApply);
            if (match) {
                const intersection = selection.intersection(match);
                const range = args.textObject.willFindForward && (!intersection || intersection.isEmpty)
                    ? match : selection.union(match);
                selection = selection.isReversed
                    ? new vscode_1.Selection(range.end, range.start)
                    : new vscode_1.Selection(range.start, range.end);
            }
            selections.push(selection);
        });
        if (selections.length === 0) {
            return Promise.reject(false);
        }
        selections = Selection_1.UtilSelection.unionOverlaps(selections);
        activeTextEditor.selections = selections;
        return Promise.resolve(true);
    }
    static expandToLine() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        activeTextEditor.selections = activeTextEditor.selections.map(selection => {
            const start = selection.start.with(undefined, 0);
            const end = selection.end.with(undefined, activeTextEditor.document.lineAt(selection.end.line).text.length);
            return selection.isReversed
                ? new vscode_1.Selection(end, start)
                : new vscode_1.Selection(start, end);
        });
        return Promise.resolve(true);
    }
}
exports.ActionSelection = ActionSelection;
//# sourceMappingURL=Selection.js.map