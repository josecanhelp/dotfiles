"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const StaticReflect_1 = require("../LanguageExtensions/StaticReflect");
const Metadata_1 = require("../Symbols/Metadata");
const MoveCursor_1 = require("./MoveCursor");
const Selection_1 = require("./Selection");
const Character_1 = require("../Motions/Character");
const Direction_1 = require("../Motions/Direction");
const Line_1 = require("../Motions/Line");
const Range_1 = require("../Utils/Range");
const Text_1 = require("../Utils/Text");
class Register {
    constructor(args) {
        this._lineCount = undefined;
        this.text = args.text;
        this.isLinewise = args.isLinewise === undefined ? false : args.isLinewise;
    }
    get lineCount() {
        if (this._lineCount === undefined) {
            this._lineCount = Text_1.UtilText.getLineCount(this.text);
        }
        return this._lineCount;
    }
}
exports.Register = Register;
class ActionRegister {
    static GetStash() {
        return ActionRegister.stash;
    }
    static yankRanges(args) {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const document = activeTextEditor.document;
        if (args.isLinewise) {
            args.ranges = args.ranges.map(range => Range_1.UtilRange.toLinewise(range, document));
        }
        args.ranges = Range_1.UtilRange.unionOverlaps(args.ranges);
        const text = args.ranges.map(range => {
            return document.getText(document.validateRange(range));
        }).join('');
        ActionRegister.stash = new Register({
            text: text,
            isLinewise: args.isLinewise,
        });
        return Promise.resolve(true);
    }
    static yankByMotions(args) {
        args.isChangeAction = args.isChangeAction === undefined ? false : args.isChangeAction;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const isLinewise = args.motions.some(motion => motion.isLinewise);
        const ranges = activeTextEditor.selections.map(selection => {
            const start = selection.active;
            const end = args.motions.reduce((position, motion) => {
                return motion.apply(position, {
                    isInclusive: true,
                    shouldCrossLines: false,
                    isChangeAction: args.isChangeAction,
                });
            }, start);
            return new vscode_1.Range(start, end);
        });
        return ActionRegister.yankRanges({
            ranges: ranges,
            isLinewise: isLinewise,
        });
    }
    static yankByTextObject(args) {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const document = activeTextEditor.document;
        let ranges = [];
        activeTextEditor.selections.forEach(selection => {
            const match = args.textObject.apply(selection.active);
            if (match) {
                ranges.push(match);
            }
        });
        // `ranges` is already line-wise so yankRanges is not suitable.
        ranges = Range_1.UtilRange.unionOverlaps(ranges);
        const text = ranges.map(range => {
            return document.getText(document.validateRange(range));
        }).join('');
        ActionRegister.stash = new Register({
            text: text,
            isLinewise: args.textObject.isLinewise,
        });
        return Promise.resolve(true);
    }
    static yankSelections(args) {
        args.isLinewise = args.isLinewise === undefined ? false : args.isLinewise;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        return ActionRegister.yankRanges({
            ranges: activeTextEditor.selections,
            isLinewise: args.isLinewise,
        });
    }
    static yankLines(args) {
        args.n = args.n === undefined ? 1 : args.n;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const ranges = args.n === 1
            ? activeTextEditor.selections
            : activeTextEditor.selections.map(selection => selection.with({
                end: selection.end.translate(args.n - 1),
            }));
        return ActionRegister.yankRanges({
            ranges: ranges,
            isLinewise: true,
        });
    }
    static putAfter(args) {
        args.n = args.n === undefined ? 1 : args.n;
        if (!ActionRegister.stash) {
            return Promise.resolve(false);
        }
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const stash = ActionRegister.stash;
        const putPositions = activeTextEditor.selections.map(selection => {
            return stash.isLinewise
                ? new vscode_1.Position(selection.active.line + 1, 0)
                : selection.active.translate(0, +1);
        });
        const textToPut = stash.text.repeat(args.n);
        return Selection_1.ActionSelection.shrinkToActives()
            .then(() => {
            return activeTextEditor.edit((editBuilder) => {
                putPositions.forEach(position => {
                    editBuilder.insert(position, textToPut);
                });
            });
        })
            .then(() => {
            if (stash.isLinewise) {
                return MoveCursor_1.ActionMoveCursor.byMotions({ motions: [
                        Character_1.MotionCharacter.down(),
                        Line_1.MotionLine.firstNonBlank(),
                    ] });
            }
            else if (stash.lineCount > 1) {
                return MoveCursor_1.ActionMoveCursor.byMotions({ motions: [
                        Character_1.MotionCharacter.right(),
                    ] });
            }
            else {
                const characters = textToPut.length;
                return MoveCursor_1.ActionMoveCursor.byMotions({ motions: [
                        Character_1.MotionCharacter.right({ n: characters }),
                    ] });
            }
        });
    }
    static putBefore(args) {
        args.n = args.n === undefined ? 1 : args.n;
        if (!ActionRegister.stash) {
            return Promise.resolve(false);
        }
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const stash = ActionRegister.stash;
        const putPositions = activeTextEditor.selections.map(selection => {
            return stash.isLinewise
                ? selection.active.with(undefined, 0)
                : selection.active;
        });
        const textToPut = stash.text.repeat(args.n);
        return Selection_1.ActionSelection.shrinkToActives()
            .then(() => {
            return activeTextEditor.edit((editBuilder) => {
                putPositions.forEach(position => {
                    editBuilder.insert(position, textToPut);
                });
            });
        })
            .then(() => {
            if (stash.isLinewise) {
                return MoveCursor_1.ActionMoveCursor.byMotions({ motions: [
                        Character_1.MotionCharacter.up({ n: Text_1.UtilText.getLineCount(textToPut) - 1 }),
                        Line_1.MotionLine.firstNonBlank(),
                    ] });
            }
            else if (stash.lineCount > 1) {
                return MoveCursor_1.ActionMoveCursor.byMotions({ motions: [
                        Direction_1.MotionDirection.prev({ n: textToPut.length - args.n }),
                    ] });
            }
            else {
                return MoveCursor_1.ActionMoveCursor.byMotions({ motions: [
                        Character_1.MotionCharacter.left(),
                    ] });
            }
        });
    }
}
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionRegister, "putAfter", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionRegister, "putBefore", null);
exports.ActionRegister = ActionRegister;
//# sourceMappingURL=Register.js.map