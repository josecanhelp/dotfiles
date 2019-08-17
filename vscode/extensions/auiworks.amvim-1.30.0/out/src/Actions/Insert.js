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
class ActionInsert {
    static textAtSelections(args) {
        if (args.replaceCharCnt !== undefined) {
            return vscode_1.commands.executeCommand('default:replacePreviousChar', {
                text: args.text,
                replaceCharCnt: args.replaceCharCnt,
            });
        }
        return vscode_1.commands.executeCommand('default:type', { text: args.text });
    }
    static newLineBefore() {
        return vscode_1.commands.executeCommand('editor.action.insertLineBefore');
    }
    static newLineAfter() {
        return vscode_1.commands.executeCommand('editor.action.insertLineAfter');
    }
}
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionInsert, "textAtSelections", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionInsert, "newLineBefore", null);
__decorate([
    StaticReflect_1.StaticReflect.metadata(Metadata_1.SymbolMetadata.Action.isChange, true)
], ActionInsert, "newLineAfter", null);
exports.ActionInsert = ActionInsert;
//# sourceMappingURL=Insert.js.map