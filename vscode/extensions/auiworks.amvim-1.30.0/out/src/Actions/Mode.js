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
const Mode_1 = require("../Modes/Mode");
const Selection_1 = require("../Actions/Selection");
class ActionMode {
    static toNormal() {
        return vscode_1.commands.executeCommand(`amVim.mode.${Mode_1.ModeID.NORMAL}`)
            .then(() => Selection_1.ActionSelection.validateSelections());
    }
    static toVisual() {
        return vscode_1.commands.executeCommand(`amVim.mode.${Mode_1.ModeID.VISUAL}`);
    }
    static toVisualLine() {
        return vscode_1.commands.executeCommand(`amVim.mode.${Mode_1.ModeID.VISUAL_LINE}`);
    }
    static toInsert() {
        return vscode_1.commands.executeCommand(`amVim.mode.${Mode_1.ModeID.INSERT}`);
    }
    static switchByActiveSelections(currentMode) {
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return Promise.resolve(false);
        }
        if (currentMode === Mode_1.ModeID.INSERT) {
            return Promise.resolve(true);
        }
        const selections = activeTextEditor.selections;
        let mode;
        if (selections.every(selection => selection.isEmpty)) {
            mode = Mode_1.ModeID.NORMAL;
        }
        else {
            mode = Mode_1.ModeID.VISUAL;
        }
        if (mode === currentMode) {
            if (mode === Mode_1.ModeID.NORMAL) {
                return Selection_1.ActionSelection.validateSelections();
            }
            else {
                return Promise.resolve(true);
            }
        }
        else if (mode === Mode_1.ModeID.VISUAL && currentMode === Mode_1.ModeID.VISUAL_LINE) {
            return Promise.resolve(true);
        }
        else {
            return vscode_1.commands.executeCommand(`amVim.mode.${mode}`)
                .then(() => Selection_1.ActionSelection.validateSelections());
        }
    }
}
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.shouldSkipOnRepeat, true)
], ActionMode, "toNormal", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.shouldSkipOnRepeat, true)
], ActionMode, "toVisual", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.shouldSkipOnRepeat, true)
], ActionMode, "toVisualLine", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true),
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.shouldSkipOnRepeat, true)
], ActionMode, "toInsert", null);
exports.ActionMode = ActionMode;
//# sourceMappingURL=Mode.js.map