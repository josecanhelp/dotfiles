"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const StaticReflect_1 = require("../LanguageExtensions/StaticReflect");
const Metadata_1 = require("../Symbols/Metadata");
const Mode_1 = require("./Mode");
const Configuration_1 = require("../Configuration");
const BlockCursor_1 = require("../Actions/BlockCursor");
const RelativeLineNumbers_1 = require("../Actions/RelativeLineNumbers");
const MoveCursor_1 = require("../Actions/MoveCursor");
const Page_1 = require("../Actions/Page");
const Insert_1 = require("../Actions/Insert");
const Delete_1 = require("../Actions/Delete");
const Replace_1 = require("../Actions/Replace");
const Case_1 = require("../Actions/Case");
const Register_1 = require("../Actions/Register");
const Reveal_1 = require("../Actions/Reveal");
const NativeEscape_1 = require("../Actions/NativeEscape");
const JoinLines_1 = require("../Actions/JoinLines");
const Find_1 = require("../Actions/Find");
const Selection_1 = require("../Actions/Selection");
const History_1 = require("../Actions/History");
const Indent_1 = require("../Actions/Indent");
const Filter_1 = require("../Actions/Filter");
const Mode_2 = require("../Actions/Mode");
const Fold_1 = require("../Actions/Fold");
const CommandLine_1 = require("../Actions/CommandLine");
const Character_1 = require("../Motions/Character");
const Line_1 = require("../Motions/Line");
class ModeNormal extends Mode_1.Mode {
    constructor() {
        super();
        this.id = Mode_1.ModeID.NORMAL;
        this.name = 'NORMAL';
        this.maps = [
            { keys: '{motion}', actions: [MoveCursor_1.ActionMoveCursor.byMotions], args: { noEmptyAtLineEnd: true } },
            { keys: '{N} {motion}', actions: [MoveCursor_1.ActionMoveCursor.byMotions], args: { noEmptyAtLineEnd: true } },
            { keys: 'ctrl+b', actions: [Page_1.ActionPage.up] },
            { keys: 'ctrl+f', actions: [Page_1.ActionPage.down] },
            { keys: 'i', actions: [Mode_2.ActionMode.toInsert] },
            { keys: 'I', actions: [
                    () => MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Line_1.MotionLine.firstNonBlank()] }),
                    Mode_2.ActionMode.toInsert,
                ] },
            { keys: 'a', actions: [
                    () => MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Character_1.MotionCharacter.right()] }),
                    Mode_2.ActionMode.toInsert,
                ] },
            { keys: 'A', actions: [
                    () => MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Line_1.MotionLine.end()] }),
                    Mode_2.ActionMode.toInsert,
                ] },
            { keys: 'o', actions: [
                    Insert_1.ActionInsert.newLineAfter,
                    Mode_2.ActionMode.toInsert,
                ] },
            { keys: 'O', actions: [
                    Insert_1.ActionInsert.newLineBefore,
                    Mode_2.ActionMode.toInsert,
                ] },
            { keys: 's', actions: [
                    Delete_1.ActionDelete.selectionsOrRight,
                    Mode_2.ActionMode.toInsert,
                ], args: {
                    shouldYank: true
                } },
            { keys: 'X', actions: [Delete_1.ActionDelete.selectionsOrLeft], args: { shouldYank: true } },
            { keys: '{N} X', actions: [Delete_1.ActionDelete.selectionsOrLeft,], args: { shouldYank: true } },
            { keys: 'x', actions: [
                    Delete_1.ActionDelete.selectionsOrRight,
                    Selection_1.ActionSelection.validateSelections,
                ], args: {
                    shouldYank: true
                } },
            { keys: '{N} x', actions: [
                    Delete_1.ActionDelete.selectionsOrRight,
                    Selection_1.ActionSelection.validateSelections,
                ], args: {
                    shouldYank: true
                } },
            { keys: 'delete', actions: [
                    Delete_1.ActionDelete.selectionsOrRight,
                    Selection_1.ActionSelection.validateSelections,
                ], args: {
                    shouldYank: true
                } },
            { keys: 'd d', actions: [Delete_1.ActionDelete.byLines], args: { shouldYank: true } },
            { keys: '{N} d d', actions: [Delete_1.ActionDelete.byLines], args: { shouldYank: true } },
            { keys: 'd {N} d', actions: [Delete_1.ActionDelete.byLines], args: { shouldYank: true } },
            { keys: 'D', actions: [
                    Delete_1.ActionDelete.byMotions,
                    Selection_1.ActionSelection.validateSelections,
                ], args: {
                    motions: [Line_1.MotionLine.end()],
                    shouldYank: true
                } },
            { keys: 'd {motion}', actions: [
                    Delete_1.ActionDelete.byMotions,
                    Selection_1.ActionSelection.validateSelections,
                ], args: {
                    shouldYank: true
                } },
            { keys: 'd {N} {motion}', actions: [
                    Delete_1.ActionDelete.byMotions,
                    Selection_1.ActionSelection.validateSelections,
                ], args: {
                    shouldYank: true
                } },
            { keys: '{N} d {motion}', actions: [
                    Delete_1.ActionDelete.byMotions,
                    Selection_1.ActionSelection.validateSelections,
                ], args: {
                    shouldYank: true
                } },
            { keys: 'd {textObject}', actions: [
                    Delete_1.ActionDelete.byTextObject,
                    Selection_1.ActionSelection.validateSelections,
                ], args: {
                    shouldYank: true
                } },
            { keys: 'C', actions: [
                    Delete_1.ActionDelete.byMotions,
                    Mode_2.ActionMode.toInsert,
                ], args: {
                    motions: [Line_1.MotionLine.end()],
                    shouldYank: true
                } },
            { keys: 'c c', actions: [
                    () => MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Line_1.MotionLine.firstNonBlank()] }),
                    Delete_1.ActionDelete.byMotions,
                    Mode_2.ActionMode.toInsert,
                ], args: {
                    motions: [Line_1.MotionLine.end()],
                    shouldYank: true
                } },
            { keys: 'S', actions: [
                    () => MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Line_1.MotionLine.firstNonBlank()] }),
                    Delete_1.ActionDelete.byMotions,
                    Mode_2.ActionMode.toInsert,
                ], args: {
                    motions: [Line_1.MotionLine.end()],
                    shouldYank: true
                } },
            { keys: 'c {motion}', actions: [
                    Delete_1.ActionDelete.byMotions,
                    Mode_2.ActionMode.toInsert,
                ], args: {
                    shouldYank: true,
                    isChangeAction: true,
                } },
            { keys: 'c {N} {motion}', actions: [
                    Delete_1.ActionDelete.byMotions,
                    Mode_2.ActionMode.toInsert,
                ], args: {
                    shouldYank: true,
                    isChangeAction: true,
                } },
            { keys: 'c {textObject}', actions: [
                    Delete_1.ActionDelete.byTextObject,
                    Mode_2.ActionMode.toInsert,
                ], args: {
                    shouldYank: true,
                } },
            { keys: 'J', actions: [JoinLines_1.ActionJoinLines.onSelections] },
            { keys: 'r {char}', actions: [Replace_1.ActionReplace.charactersWithCharacter] },
            { keys: '~', actions: [
                    Case_1.ActionCase.switchActives,
                    () => MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Character_1.MotionCharacter.right()] }),
                ] },
            { keys: 'y y', actions: [Register_1.ActionRegister.yankLines] },
            { keys: '{N} y y', actions: [Register_1.ActionRegister.yankLines] },
            { keys: 'y {N} y', actions: [Register_1.ActionRegister.yankLines] },
            { keys: 'Y', actions: [Register_1.ActionRegister.yankLines] },
            { keys: 'y {motion}', actions: [Register_1.ActionRegister.yankByMotions] },
            { keys: 'y {N} {motion}', actions: [Register_1.ActionRegister.yankByMotions] },
            { keys: 'y {textObject}', actions: [Register_1.ActionRegister.yankByTextObject] },
            { keys: 'p', actions: [Register_1.ActionRegister.putAfter] },
            { keys: '{N} p', actions: [Register_1.ActionRegister.putAfter] },
            { keys: 'P', actions: [Register_1.ActionRegister.putBefore] },
            { keys: '{N} P', actions: [Register_1.ActionRegister.putBefore] },
            { keys: 'n', actions: [Find_1.ActionFind.next] },
            { keys: 'N', actions: [Find_1.ActionFind.prev] },
            { keys: '*', actions: [
                    Find_1.ActionFind.byIndicator,
                    Find_1.ActionFind.next,
                ] },
            { keys: '#', actions: [
                    Find_1.ActionFind.byIndicator,
                    Find_1.ActionFind.prev,
                ] },
            { keys: '= {motion}', actions: [Filter_1.ActionFilter.Format.byMotions] },
            { keys: '= {N} {motion}', actions: [Filter_1.ActionFilter.Format.byMotions] },
            { keys: '= =', actions: [Filter_1.ActionFilter.Format.byCursors] },
            { keys: 'u', actions: [
                    History_1.ActionHistory.undo,
                    Selection_1.ActionSelection.validateSelections,
                ] },
            { keys: 'ctrl+r', actions: [
                    History_1.ActionHistory.redo,
                    Selection_1.ActionSelection.validateSelections,
                ] },
            { keys: '< <', actions: [Indent_1.ActionIndent.decrease] },
            { keys: '> >', actions: [Indent_1.ActionIndent.increase] },
            { keys: '/', actions: [Find_1.ActionFind.focusFindWidget] },
            { keys: 'v', actions: [Mode_2.ActionMode.toVisual] },
            { keys: 'V', actions: [Mode_2.ActionMode.toVisualLine] },
            { keys: 'z .', actions: [Reveal_1.ActionReveal.primaryCursor], args: { revealType: vscode_1.TextEditorRevealType.InCenter } },
            { keys: 'z z', actions: [Reveal_1.ActionReveal.primaryCursor], args: { revealType: vscode_1.TextEditorRevealType.InCenter } },
            { keys: 'z c', actions: [Fold_1.ActionFold.fold] },
            { keys: 'z o', actions: [Fold_1.ActionFold.unfold] },
            { keys: 'z M', actions: [Fold_1.ActionFold.foldAll] },
            { keys: 'z R', actions: [Fold_1.ActionFold.unfoldAll] },
            { keys: ':', actions: [CommandLine_1.ActionCommandLine.promptAndRun] },
            { keys: '.', actions: [this.repeatRecordedCommandMaps.bind(this)] },
            { keys: 'ctrl+c', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    Selection_1.ActionSelection.shrinkToPrimaryActive,
                ] },
            { keys: 'ctrl+[', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    Selection_1.ActionSelection.shrinkToPrimaryActive,
                ] },
            { keys: 'escape', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    Selection_1.ActionSelection.shrinkToPrimaryActive,
                ] },
        ];
        this.maps.forEach(map => {
            this.mapper.map(map.keys, map.actions, map.args);
        });
    }
    enter() {
        super.enter();
        BlockCursor_1.ActionBlockCursor.on();
        if (Configuration_1.Configuration.smartRelativeLineNumbers) {
            RelativeLineNumbers_1.ActionRelativeLineNumbers.on();
        }
    }
    exit() {
        super.exit();
        BlockCursor_1.ActionBlockCursor.off();
    }
    get recordedCommandMaps() { return this._recordedCommandMaps; }
    onWillCommandMapMakesChanges(map) {
        if (map.isRepeating) {
            return Promise.resolve(false);
        }
        const actions = map.actions.filter(action => {
            return StaticReflect_1.StaticReflect.getMetadata(Metadata_1.SymbolMetadata.Action.shouldSkipOnRepeat, action) !== true;
        });
        this._recordedCommandMaps = [
            {
                keys: map.keys,
                actions: actions,
                args: map.args,
                isRepeating: true,
            }
        ];
        return Promise.resolve(true);
    }
    onDidRecordFinish(recordedCommandMaps, lastModeID) {
        if (!recordedCommandMaps || recordedCommandMaps.length === 0) {
            return;
        }
        if (lastModeID === Mode_1.ModeID.INSERT) {
            recordedCommandMaps.forEach(map => map.isRepeating = true);
            if (this._recordedCommandMaps === undefined) {
                this._recordedCommandMaps = recordedCommandMaps;
            }
            else {
                this._recordedCommandMaps = this._recordedCommandMaps.concat(recordedCommandMaps);
            }
        }
        else {
            this._recordedCommandMaps = recordedCommandMaps;
        }
    }
    repeatRecordedCommandMaps() {
        if (this._recordedCommandMaps === undefined) {
            return Promise.resolve(false);
        }
        // TODO: Replace `args.n` if provided
        this._recordedCommandMaps.forEach(map => this.pushCommandMap(map));
        this.pushCommandMap({
            keys: 'escape',
            actions: [NativeEscape_1.ActionNativeEscape.press],
        });
        this.execute();
        return Promise.resolve(true);
    }
}
exports.ModeNormal = ModeNormal;
//# sourceMappingURL=Normal.js.map