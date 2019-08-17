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
const Selection_1 = require("./Selection");
const Register_1 = require("./Register");
const Reveal_1 = require("./Reveal");
const Range_1 = require("../Utils/Range");
class ActionDelete {
    static byMotions(args) {
        args.isChangeAction = args.isChangeAction === undefined ? false : args.isChangeAction;
        args.shouldYank = args.shouldYank === undefined ? false : args.shouldYank;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const document = activeTextEditor.document;
        let ranges = activeTextEditor.selections.map(selection => {
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
        if (args.motions.some(motion => motion.isLinewise)) {
            ranges = ranges.map(range => Range_1.UtilRange.toLinewise(range, document));
        }
        ranges = Range_1.UtilRange.unionOverlaps(ranges);
        // TODO: Move cursor to first non-space if needed
        return (args.shouldYank ? Register_1.ActionRegister.yankByMotions({
            motions: args.motions,
            isChangeAction: args.isChangeAction,
        }) : Promise.resolve(true))
            .then(() => {
            return activeTextEditor.edit((editBuilder) => {
                ranges.forEach((range) => editBuilder.delete(range));
            });
        })
            .then(() => Selection_1.ActionSelection.shrinkToStarts())
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static byTextObject(args) {
        args.shouldYank = args.shouldYank === undefined ? false : args.shouldYank;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        let ranges = [];
        activeTextEditor.selections.forEach(selection => {
            const match = args.textObject.apply(selection.active);
            if (match) {
                ranges.push(match);
            }
        });
        ranges = Range_1.UtilRange.unionOverlaps(ranges);
        if (ranges.length === 0) {
            return Promise.reject(false);
        }
        return (args.shouldYank ? Register_1.ActionRegister.yankByTextObject({
            textObject: args.textObject,
        }) : Promise.resolve(true))
            .then(() => {
            // Selections will be adjust to matched ranges' start.
            activeTextEditor.selections = ranges.map(range => new vscode_1.Selection(range.start, range.start));
            return activeTextEditor.edit((editBuilder) => {
                ranges.forEach((range) => editBuilder.delete(range));
            });
        })
            .then(() => Selection_1.ActionSelection.shrinkToStarts())
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static selectionsOrLeft(args = {}) {
        args.n = args.n === undefined ? 1 : args.n;
        args.shouldYank = args.shouldYank === undefined ? false : args.shouldYank;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        let ranges = activeTextEditor.selections.map(selection => {
            let n = Math.min(selection.active.character, args.n);
            return selection.isEmpty && selection.active.character !== 0
                ? new vscode_1.Range(selection.active, selection.active.translate(0, -n))
                : selection;
        });
        ranges = Range_1.UtilRange.unionOverlaps(ranges);
        return (args.shouldYank ? Register_1.ActionRegister.yankRanges({
            ranges: ranges,
            isLinewise: false,
        }) : Promise.resolve(true))
            .then(() => {
            return activeTextEditor.edit((editBuilder) => {
                ranges.forEach((range) => editBuilder.delete(range));
            });
        })
            .then(() => Selection_1.ActionSelection.shrinkToStarts())
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static selectionsOrRight(args = {}) {
        args.n = args.n === undefined ? 1 : args.n;
        args.shouldYank = args.shouldYank === undefined ? false : args.shouldYank;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        let ranges = activeTextEditor.selections.map(selection => {
            return selection.isEmpty
                ? new vscode_1.Range(selection.active, selection.active.translate(0, +args.n))
                : selection;
        });
        ranges = Range_1.UtilRange.unionOverlaps(ranges);
        return (args.shouldYank ? Register_1.ActionRegister.yankRanges({
            ranges: ranges,
            isLinewise: false,
        }) : Promise.resolve(true))
            .then(() => {
            return activeTextEditor.edit((editBuilder) => {
                ranges.forEach((range) => editBuilder.delete(range));
            });
        })
            .then(() => Selection_1.ActionSelection.shrinkToStarts())
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static byLines(args) {
        args.n = args.n === undefined ? 1 : args.n;
        args.shouldYank = args.shouldYank === undefined ? false : args.shouldYank;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const document = activeTextEditor.document;
        let ranges = activeTextEditor.selections.map(selection => {
            const range = args.n === 1
                ? selection
                : selection.with({
                    end: selection.end.translate(args.n - 1),
                });
            return Range_1.UtilRange.toLinewise(range, document);
        });
        ranges = Range_1.UtilRange.unionOverlaps(ranges);
        return (args.shouldYank ? Register_1.ActionRegister.yankLines({ n: args.n }) : Promise.resolve(true))
            .then(() => {
            return activeTextEditor.edit((editBuilder) => {
                ranges.forEach((range) => editBuilder.delete(range));
            });
        })
            .then(() => Selection_1.ActionSelection.shrinkToStarts())
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
}
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionDelete, "byMotions", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionDelete, "byTextObject", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionDelete, "selectionsOrLeft", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionDelete, "selectionsOrRight", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionDelete, "byLines", null);
exports.ActionDelete = ActionDelete;
//# sourceMappingURL=Delete.js.map