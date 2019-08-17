"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const StaticReflect_1 = require("../LanguageExtensions/StaticReflect");
const Metadata_1 = require("../Symbols/Metadata");
const RangeOffset_1 = require("../Types/RangeOffset");
const Mode_1 = require("./Mode");
const Configuration_1 = require("../Configuration");
const RelativeLineNumbers_1 = require("../Actions/RelativeLineNumbers");
const MoveCursor_1 = require("../Actions/MoveCursor");
const Page_1 = require("../Actions/Page");
const Selection_1 = require("../Actions/Selection");
const Register_1 = require("../Actions/Register");
const Delete_1 = require("../Actions/Delete");
const Insert_1 = require("../Actions/Insert");
const Case_1 = require("../Actions/Case");
const Replace_1 = require("../Actions/Replace");
const Indent_1 = require("../Actions/Indent");
const JoinLines_1 = require("../Actions/JoinLines");
const Filter_1 = require("../Actions/Filter");
const Find_1 = require("../Actions/Find");
const NativeEscape_1 = require("../Actions/NativeEscape");
const Mode_2 = require("../Actions/Mode");
const Fold_1 = require("../Actions/Fold");
const Line_1 = require("../Motions/Line");
class ModeVisual extends Mode_1.Mode {
    constructor() {
        super();
        this.id = Mode_1.ModeID.VISUAL;
        this.name = 'VISUAL';
        this.maps = [
            { keys: '{motion}', actions: [MoveCursor_1.ActionMoveCursor.byMotions], args: { isVisualMode: true } },
            { keys: '{N} {motion}', actions: [MoveCursor_1.ActionMoveCursor.byMotions], args: { isVisualMode: true } },
            { keys: '{textObject}', actions: [Selection_1.ActionSelection.expandByTextObject] },
            { keys: 'ctrl+b', actions: [Page_1.ActionPage.up], args: { moveType: Page_1.PageMoveType.Select } },
            { keys: 'ctrl+f', actions: [Page_1.ActionPage.down], args: { moveType: Page_1.PageMoveType.Select } },
            { keys: 'I', actions: [
                    Selection_1.ActionSelection.shrinkToStarts,
                    Mode_2.ActionMode.toInsert,
                ] },
            { keys: 'A', actions: [
                    Selection_1.ActionSelection.shrinkToEnds,
                    Mode_2.ActionMode.toInsert,
                ] },
            { keys: 'backspace', actions: [Delete_1.ActionDelete.selectionsOrRight], args: { shouldYank: true } },
            { keys: 'delete', actions: [Delete_1.ActionDelete.selectionsOrRight], args: { shouldYank: true } },
            { keys: 'x', actions: [Delete_1.ActionDelete.selectionsOrRight], args: { shouldYank: true } },
            { keys: 'X', actions: [Delete_1.ActionDelete.byLines], args: { shouldYank: true } },
            { keys: 'd', actions: [Delete_1.ActionDelete.selectionsOrRight], args: { shouldYank: true } },
            { keys: 'D', actions: [Delete_1.ActionDelete.byLines], args: { shouldYank: true } },
            { keys: 'c', actions: [
                    Delete_1.ActionDelete.selectionsOrRight,
                    Mode_2.ActionMode.toInsert,
                ], args: { shouldYank: true } },
            { keys: 'C', actions: [
                    Delete_1.ActionDelete.byLines,
                    Insert_1.ActionInsert.newLineBefore,
                    Mode_2.ActionMode.toInsert,
                ], args: { shouldYank: true } },
            { keys: 's', actions: [
                    Delete_1.ActionDelete.selectionsOrRight,
                    Mode_2.ActionMode.toInsert,
                ], args: { shouldYank: true } },
            { keys: 'S', actions: [
                    Delete_1.ActionDelete.byLines,
                    Insert_1.ActionInsert.newLineBefore,
                    Mode_2.ActionMode.toInsert,
                ], args: { shouldYank: true } },
            { keys: 'y', actions: [
                    Register_1.ActionRegister.yankSelections,
                    Selection_1.ActionSelection.shrinkToStarts,
                ] },
            { keys: 'Y', actions: [
                    Register_1.ActionRegister.yankLines,
                    Selection_1.ActionSelection.shrinkToStarts,
                    () => MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Line_1.MotionLine.start()] }),
                ] },
            { keys: 'J', actions: [
                    JoinLines_1.ActionJoinLines.onSelections,
                    Selection_1.ActionSelection.shrinkToActives,
                ] },
            { keys: 'p', actions: [Replace_1.ActionReplace.selectionsWithRegister], args: { shouldYank: true } },
            { keys: 'P', actions: [Replace_1.ActionReplace.selectionsWithRegister], args: { shouldYank: true } },
            { keys: 'r {char}', actions: [
                    Replace_1.ActionReplace.selectionsWithCharacter,
                    Selection_1.ActionSelection.shrinkToStarts,
                ] },
            { keys: '~', actions: [
                    Case_1.ActionCase.switchSelections,
                    Selection_1.ActionSelection.shrinkToStarts,
                ] },
            { keys: 'u', actions: [
                    Case_1.ActionCase.lowercaseSelections,
                    Selection_1.ActionSelection.shrinkToStarts,
                ] },
            { keys: 'U', actions: [
                    Case_1.ActionCase.uppercaseSelections,
                    Selection_1.ActionSelection.shrinkToStarts,
                ] },
            { keys: '=', actions: [Filter_1.ActionFilter.Format.bySelections] },
            { keys: '<', actions: [Indent_1.ActionIndent.decrease], args: { isVisualMode: true } },
            { keys: '>', actions: [Indent_1.ActionIndent.increase], args: { isVisualMode: true } },
            { keys: '/', actions: [Find_1.ActionFind.focusFindWidget] },
            { keys: 'V', actions: [Mode_2.ActionMode.toVisualLine] },
            { keys: 'v', actions: [Selection_1.ActionSelection.shrinkToActives] },
            { keys: 'z c', actions: [Fold_1.ActionFold.fold] },
            { keys: 'z o', actions: [Fold_1.ActionFold.unfold] },
            { keys: 'z M', actions: [Fold_1.ActionFold.foldAll] },
            { keys: 'z R', actions: [Fold_1.ActionFold.unfoldAll] },
            { keys: 'ctrl+c', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    Selection_1.ActionSelection.shrinkToActives,
                ] },
            { keys: 'ctrl+[', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    Selection_1.ActionSelection.shrinkToActives,
                ] },
            { keys: 'escape', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    Selection_1.ActionSelection.shrinkToActives,
                ] },
        ];
        this.maps.forEach(map => {
            this.mapper.map(map.keys, map.actions, map.args);
        });
    }
    enter() {
        super.enter();
        Selection_1.ActionSelection.expandToOne();
        if (Configuration_1.Configuration.smartRelativeLineNumbers) {
            RelativeLineNumbers_1.ActionRelativeLineNumbers.on();
        }
    }
    get recordedCommandMaps() { return this._recordedCommandMaps; }
    onWillCommandMapMakesChanges(map) {
        const actions = map.actions.filter(action => {
            return StaticReflect_1.StaticReflect.getMetadata(Metadata_1.SymbolMetadata.Action.shouldSkipOnRepeat, action) !== true;
        });
        const args = Object.assign({
            preferredRelativeRange: vscode_1.window.activeTextEditor
                ? new RangeOffset_1.RangeOffset(vscode_1.window.activeTextEditor.selection)
                : undefined,
        }, map.args);
        this._recordedCommandMaps = [
            {
                keys: map.keys,
                actions: actions,
                args: args,
                isRepeating: true,
            }
        ];
        return Promise.resolve(true);
    }
}
exports.ModeVisual = ModeVisual;
//# sourceMappingURL=Visual.js.map