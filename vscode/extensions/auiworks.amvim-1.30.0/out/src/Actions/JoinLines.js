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
class ActionJoinLines {
    static onSelections() {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        return activeTextEditor.edit((editBuilder) => {
            const rangeByLine = (line) => {
                if (line >= activeTextEditor.document.lineCount - 1) {
                    return null;
                }
                const thisLine = activeTextEditor.document.lineAt(line).text;
                const nextLine = activeTextEditor.document.lineAt(line + 1).text;
                const thisLineTrimLength = (() => {
                    const matches = thisLine.match(/\s+$/);
                    return matches ? matches[0].length : 0;
                })();
                const nextLineTrimLength = (() => {
                    const matches = nextLine.match(/^\s+/);
                    return matches ? matches[0].length : 0;
                })();
                return new vscode_1.Range(line, thisLine.length - thisLineTrimLength, line + 1, nextLineTrimLength);
            };
            const targetPositions = [];
            const linesToJoin = [];
            activeTextEditor.selections.forEach(selection => {
                if (selection.isSingleLine) {
                    const line = activeTextEditor.document.lineAt(selection.active.line);
                    targetPositions.push(new vscode_1.Position(line.lineNumber, line.text.length));
                    linesToJoin.push(line.lineNumber);
                }
                else {
                    const line = activeTextEditor.document.lineAt(selection.end.line - 1);
                    targetPositions.push(new vscode_1.Position(line.lineNumber, line.text.length));
                    for (let lineNumber = selection.start.line; lineNumber <= line.lineNumber; lineNumber++) {
                        linesToJoin.push(lineNumber);
                    }
                }
            });
            activeTextEditor.selections = targetPositions.map((position) => new vscode_1.Selection(position, position));
            let ranges = [];
            linesToJoin.forEach(line => {
                const range = rangeByLine(line);
                if (range) {
                    ranges.push(range);
                }
            });
            ranges = Range_1.UtilRange.unionOverlaps(ranges);
            ranges.forEach(range => {
                editBuilder.replace(range, ' ');
            });
        })
            .then(() => Reveal_1.ActionReveal.primaryCursor());
    }
}
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionJoinLines, "onSelections", null);
exports.ActionJoinLines = ActionJoinLines;
//# sourceMappingURL=JoinLines.js.map