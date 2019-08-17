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
const Register_1 = require("./Register");
const Selection_1 = require("./Selection");
const Reveal_1 = require("./Reveal");
const Range_1 = require("../Utils/Range");
class ActionReplace {
    static selectionsWithRegister(args) {
        args.shouldYank = args.shouldYank === undefined ? false : args.shouldYank;
        args.isLinewise = args.isLinewise === undefined ? false : args.isLinewise;
        const stash = Register_1.ActionRegister.GetStash();
        if (!stash) {
            return Promise.resolve(false);
        }
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const document = activeTextEditor.document;
        let ranges = activeTextEditor.selections;
        if (args.isLinewise) {
            ranges = ranges.map(range => Range_1.UtilRange.toLinewise(range, document));
        }
        return (args.shouldYank ? Register_1.ActionRegister.yankSelections({
            isLinewise: args.isLinewise,
        }) : Promise.resolve(true))
            .then(() => activeTextEditor.edit((editBuilder) => {
            ranges.forEach(selection => {
                editBuilder.replace(selection, stash.text);
            });
        }))
            .then(() => Selection_1.ActionSelection.shrinkToActives())
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static selectionsWithCharacter(args) {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        return activeTextEditor.edit((editBuilder) => {
            activeTextEditor.selections.forEach(selection => {
                let text = activeTextEditor.document.getText(selection);
                editBuilder.replace(selection, text.replace(/[^\n]/g, args.character));
            });
        })
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static charactersWithCharacter(args) {
        args.n = args.n === undefined ? 1 : args.n;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        let ranges = activeTextEditor.selections.map(selection => {
            return new vscode_1.Range(selection.active, selection.active.translate(0, args.n));
        });
        ranges = Range_1.UtilRange.unionOverlaps(ranges);
        return activeTextEditor.edit((editBuilder) => {
            ranges.forEach(range => {
                let text = activeTextEditor.document.getText(range);
                editBuilder.replace(range, text.replace(/[^\n]/g, args.character));
            });
        })
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
}
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionReplace, "selectionsWithRegister", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionReplace, "selectionsWithCharacter", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionReplace, "charactersWithCharacter", null);
exports.ActionReplace = ActionReplace;
//# sourceMappingURL=Replace.js.map