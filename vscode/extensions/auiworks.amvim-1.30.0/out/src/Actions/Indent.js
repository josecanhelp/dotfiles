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
const Configuration_1 = require("../Configuration");
const Selection_1 = require("./Selection");
const MoveCursor_1 = require("./MoveCursor");
const Reveal_1 = require("./Reveal");
const Line_1 = require("../Motions/Line");
const Text_1 = require("../Utils/Text");
class ActionIndent {
    static getIndentUnit() {
        if (Configuration_1.Configuration.getInsertSpace()) {
            return ' '.repeat(Configuration_1.Configuration.getTabSize());
        }
        else {
            return '\t';
        }
    }
    static getIndentLevel(lineNumber, document) {
        if (lineNumber >= document.lineCount) {
            return 0;
        }
        const tabSize = Configuration_1.Configuration.getTabSize();
        const line = document.lineAt(lineNumber);
        const indentText = line.text.substr(0, line.firstNonWhitespaceCharacterIndex);
        const tabCount = Text_1.UtilText.countStringAppearance('\t', indentText);
        let indentLength = tabCount > 0
            ? indentText.length + tabCount * (tabSize - 1)
            : indentText.length;
        return indentLength / tabSize;
    }
    static changeIndentLevel(args) {
        args.isVisualMode = args.isVisualMode === undefined ? false : args.isVisualMode;
        args.isVisualLineMode = args.isVisualLineMode === undefined ? false : args.isVisualLineMode;
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        const document = activeTextEditor.document;
        const indentUnit = ActionIndent.getIndentUnit();
        const lineNumbers = {};
        if (args.preferredRelativeRange) {
            activeTextEditor.selections.forEach(selection => {
                for (let i = selection.active.line; i <= selection.active.line + args.preferredRelativeRange.lineOffset; i++) {
                    lineNumbers[i] = true;
                }
            });
        }
        else {
            activeTextEditor.selections.forEach(selection => {
                for (let i = selection.start.line; i <= selection.end.line; i++) {
                    lineNumbers[i] = true;
                }
            });
        }
        return activeTextEditor.edit((editBuilder) => {
            Object.keys(lineNumbers).forEach(key => {
                const lineNumber = parseInt(key, 10);
                if (lineNumber < 0 || lineNumber >= document.lineCount) {
                    return;
                }
                const line = document.lineAt(lineNumber);
                const currentIndentLevel = ActionIndent.getIndentLevel(lineNumber, document);
                let toIndentLevel = args.indentLevelOffset > 0
                    ? Math.floor(currentIndentLevel + args.indentLevelOffset)
                    : Math.ceil(currentIndentLevel + args.indentLevelOffset);
                if (toIndentLevel < 0) {
                    toIndentLevel = 0;
                }
                const indentText = indentUnit.repeat(toIndentLevel);
                editBuilder.replace(new vscode_1.Range(lineNumber, 0, lineNumber, line.firstNonWhitespaceCharacterIndex), indentText);
            });
        })
            .then(() => {
            if (args.isVisualMode || args.isVisualLineMode) {
                return Selection_1.ActionSelection.shrinkToStarts()
                    .then(() => MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Line_1.MotionLine.firstNonBlank()] }));
            }
            else {
                return Selection_1.ActionSelection.shrinkToEnds();
            }
        })
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
    static increase(args) {
        return ActionIndent.changeIndentLevel(Object.assign({
            indentLevelOffset: +1,
        }, args));
    }
    static decrease(args) {
        return ActionIndent.changeIndentLevel(Object.assign({
            indentLevelOffset: -1,
        }, args));
    }
}
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionIndent, "increase", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionIndent, "decrease", null);
exports.ActionIndent = ActionIndent;
//# sourceMappingURL=Indent.js.map