"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Reveal_1 = require("./Reveal");
const Position_1 = require("../Utils/Position");
const Selection_1 = require("../Utils/Selection");
class ActionMoveCursor {
    static blockUpdatePreferredColumn() {
        if (ActionMoveCursor.preferredColumnBlockTimer) {
            clearTimeout(ActionMoveCursor.preferredColumnBlockTimer);
        }
        ActionMoveCursor.isUpdatePreferredColumnBlocked = true;
        ActionMoveCursor.preferredColumnBlockTimer = setTimeout(function () {
            ActionMoveCursor.isUpdatePreferredColumnBlocked = false;
            ActionMoveCursor.preferredColumnBlockTimer = undefined;
        }, 100);
    }
    static updatePreferredColumn() {
        if (ActionMoveCursor.isUpdatePreferredColumnBlocked) {
            return Promise.resolve(false);
        }
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        ActionMoveCursor.preferredColumnBySelectionIndex =
            activeTextEditor.selections.map(selection => Position_1.UtilPosition.getColumn(activeTextEditor, selection.active));
        return Promise.resolve(true);
    }
    static byMotions(args) {
        args.isVisualMode = args.isVisualMode === undefined ? false : args.isVisualMode;
        args.isVisualLineMode = args.isVisualLineMode === undefined ? false : args.isVisualLineMode;
        args.noEmptyAtLineEnd = args.noEmptyAtLineEnd === undefined ? false : args.noEmptyAtLineEnd;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        // Prevent preferred character update if no motion updates character.
        if (args.motions.every(motion => !motion.isCharacterUpdated)) {
            ActionMoveCursor.blockUpdatePreferredColumn();
        }
        const document = activeTextEditor.document;
        activeTextEditor.selections = activeTextEditor.selections.map((selection, i) => {
            let anchor;
            let active = args.motions.reduce((position, motion) => {
                return motion.apply(position, {
                    preferredColumn: ActionMoveCursor.preferredColumnBySelectionIndex[i]
                });
            }, args.isVisualMode
                ? Selection_1.UtilSelection.getActiveInVisualMode(selection)
                : selection.active);
            if (args.isVisualMode) {
                anchor = selection.anchor;
                const anchorLineLength = activeTextEditor.document.lineAt(anchor.line).text.length;
                const activeLineLength = activeTextEditor.document.lineAt(active.line).text.length;
                if (active.isAfterOrEqual(anchor) && active.character < activeLineLength) {
                    active = active.translate(0, +1);
                }
                if (active.isEqual(anchor) && anchor.character > 0) {
                    anchor = anchor.translate(0, -1);
                }
                else if (active.isAfter(anchor) && selection.isReversed && anchor.character > 0) {
                    anchor = anchor.translate(0, -1);
                }
                else if (active.isBefore(anchor) && !selection.isReversed && anchor.character < anchorLineLength) {
                    anchor = anchor.translate(0, +1);
                }
            }
            else if (args.isVisualLineMode) {
                anchor = selection.anchor;
                if (anchor.isBefore(active)) {
                    anchor = anchor.with(undefined, 0);
                    active = active.with(undefined, activeTextEditor.document.lineAt(active.line).text.length);
                }
                else {
                    anchor = anchor.with(undefined, activeTextEditor.document.lineAt(anchor.line).text.length);
                    active = active.with(undefined, 0);
                }
            }
            else {
                if (args.noEmptyAtLineEnd) {
                    const lineEndCharacter = document.lineAt(active.line).text.length;
                    if (lineEndCharacter !== 0 && active.character === lineEndCharacter) {
                        active = active.translate(0, -1);
                    }
                }
                anchor = active;
            }
            return new vscode_1.Selection(anchor, active);
        });
        return Reveal_1.ActionReveal.primaryCursor();
    }
}
ActionMoveCursor.preferredColumnBySelectionIndex = [];
ActionMoveCursor.isUpdatePreferredColumnBlocked = false;
exports.ActionMoveCursor = ActionMoveCursor;
//# sourceMappingURL=MoveCursor.js.map