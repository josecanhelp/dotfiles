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
const Reveal_1 = require("./Reveal");
const Range_1 = require("../Utils/Range");
const Text_1 = require("../Utils/Text");
class ActionCase {
    static switchSelections() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        return activeTextEditor.edit((editBuilder) => {
            activeTextEditor.selections.forEach(selection => {
                const text = activeTextEditor.document.getText(selection);
                editBuilder.replace(selection, Text_1.UtilText.switchCase(text));
            });
        })
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static lowercaseSelections() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        return vscode_1.commands.executeCommand('editor.action.transformToLowercase')
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static uppercaseSelections() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        return vscode_1.commands.executeCommand('editor.action.transformToUppercase')
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static switchActives(args) {
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
                const text = activeTextEditor.document.getText(range);
                editBuilder.replace(range, Text_1.UtilText.switchCase(text));
            });
        })
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
}
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionCase, "switchSelections", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionCase, "lowercaseSelections", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionCase, "uppercaseSelections", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionCase, "switchActives", null);
exports.ActionCase = ActionCase;
//# sourceMappingURL=Case.js.map