"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Mode_1 = require("./Mode");
const Configuration_1 = require("../Configuration");
const Generic_1 = require("../Mappers/Generic");
const RelativeLineNumbers_1 = require("../Actions/RelativeLineNumbers");
const Insert_1 = require("../Actions/Insert");
const Delete_1 = require("../Actions/Delete");
const Selection_1 = require("../Actions/Selection");
const MoveCursor_1 = require("../Actions/MoveCursor");
const NativeEscape_1 = require("../Actions/NativeEscape");
const Mode_2 = require("../Actions/Mode");
const Character_1 = require("../Motions/Character");
const Word_1 = require("../Motions/Word");
const Line_1 = require("../Motions/Line");
class ModeInsert extends Mode_1.Mode {
    constructor() {
        super();
        this.id = Mode_1.ModeID.INSERT;
        this.name = 'INSERT';
        this.maps = [
            { keys: 'ctrl+w', actions: [() => Delete_1.ActionDelete.byMotions({ motions: [Word_1.MotionWord.prevStart()] })] },
            { keys: 'ctrl+u', actions: [() => Delete_1.ActionDelete.byMotions({ motions: [Line_1.MotionLine.firstNonBlank()] })] },
            { keys: 'ctrl+c', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    () => Selection_1.ActionSelection.shrinkToActives()
                        .then(isShrunken => isShrunken ? Promise.resolve(true) : Mode_2.ActionMode.toNormal()),
                ] },
            { keys: 'ctrl+[', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    () => Selection_1.ActionSelection.shrinkToActives()
                        .then(isShrunken => isShrunken ? Promise.resolve(true) : Mode_2.ActionMode.toNormal()),
                ] },
            { keys: 'escape', actions: [
                    NativeEscape_1.ActionNativeEscape.press,
                    () => Selection_1.ActionSelection.shrinkToActives()
                        .then(isShrunken => isShrunken ? Promise.resolve(true) : Mode_2.ActionMode.toNormal()),
                ] },
        ];
        this.isRecording = false;
        this.maps.forEach(map => {
            this.mapper.map(map.keys, map.actions, map.args);
        });
    }
    enter() {
        super.enter();
        this.textEditor = vscode_1.window.activeTextEditor;
        this.startRecord();
        if (Configuration_1.Configuration.smartRelativeLineNumbers) {
            RelativeLineNumbers_1.ActionRelativeLineNumbers.off();
        }
    }
    exit() {
        super.exit();
        this.endRecord();
        if (this.textEditor === vscode_1.window.activeTextEditor) {
            MoveCursor_1.ActionMoveCursor.byMotions({ motions: [Character_1.MotionCharacter.left()] });
        }
    }
    input(key, args = {}) {
        const matchResultKind = super.input(key);
        // Pass key to built-in command if match failed.
        if (matchResultKind !== Generic_1.MatchResultKind.FAILED) {
            return matchResultKind;
        }
        this.startRecord();
        this.pushCommandMap({
            keys: key,
            actions: [Insert_1.ActionInsert.textAtSelections],
            args: {
                text: key,
                replaceCharCnt: args.replaceCharCnt,
            }
        });
        this.execute();
        return Generic_1.MatchResultKind.FOUND;
    }
    get recordedCommandMaps() { return this._recordedCommandMaps; }
    startRecord() {
        if (this.isRecording) {
            return;
        }
        if (!this.textEditor) {
            return;
        }
        this.isRecording = true;
        this.recordStartPosition = this.textEditor.selection.active;
        this.recordStartLineText = this.textEditor.document.lineAt(this.recordStartPosition.line).text;
        this._recordedCommandMaps = [];
    }
    processRecord() {
        if (!this.textEditor) {
            return;
        }
        const currentLineText = this.textEditor.document.lineAt(this.recordStartPosition.line).text;
        let deletionCountBefore = 0;
        let deletionCountAfter = 0;
        let searchLimit;
        // Calculate deletion count before.
        searchLimit = Math.min(this.recordStartPosition.character, this.recordStartLineText.length);
        for (let i = 0; i < searchLimit; i++) {
            if (currentLineText.length <= i || currentLineText[i] !== this.recordStartLineText[i]) {
                deletionCountBefore = this.recordStartPosition.character - i;
                break;
            }
        }
        // Calculate deletion count after;
        const minIndex = this.recordStartPosition.character - deletionCountBefore;
        searchLimit = this.recordStartLineText.length - this.recordStartPosition.character + 1;
        for (let i = 1; i < searchLimit; i++) {
            const originalIndex = this.recordStartLineText.length - i;
            const currentIndex = currentLineText.length - i;
            if (currentIndex < minIndex || currentLineText[currentIndex] !== this.recordStartLineText[originalIndex]) {
                deletionCountAfter = searchLimit - i;
                break;
            }
        }
        const inputText = currentLineText.substring(this.recordStartPosition.character - deletionCountBefore, currentLineText.length - (this.recordStartLineText.length - this.recordStartPosition.character - deletionCountAfter));
        if (deletionCountBefore > 0) {
            this._recordedCommandMaps.push({
                keys: '',
                actions: [
                    () => Delete_1.ActionDelete.byMotions({
                        motions: [Character_1.MotionCharacter.left({ n: deletionCountBefore })]
                    })
                ],
                isRepeating: true,
            });
        }
        if (inputText.length > 0) {
            this._recordedCommandMaps.push({
                keys: '',
                actions: [Insert_1.ActionInsert.textAtSelections],
                args: {
                    text: inputText,
                },
                isRepeating: true,
            });
        }
        if (deletionCountAfter > 0) {
            this._recordedCommandMaps.push({
                keys: '',
                actions: [
                    () => Delete_1.ActionDelete.byMotions({
                        motions: [Character_1.MotionCharacter.right({ n: deletionCountAfter })]
                    })
                ],
                isRepeating: true,
            }, {
                keys: '',
                actions: [
                    () => MoveCursor_1.ActionMoveCursor.byMotions({
                        motions: [Character_1.MotionCharacter.left({ n: deletionCountAfter - 1 })]
                    })
                ],
                isRepeating: true,
            });
        }
    }
    endRecord() {
        if (!this.isRecording) {
            return;
        }
        this.isRecording = false;
        this.processRecord();
    }
    onWillCommandMapMakesChanges(map) {
        if (!this.isRecording) {
            return Promise.resolve(false);
        }
        if (map.keys === '\n') {
            this.processRecord();
            this._recordedCommandMaps.push({
                keys: 'enter',
                actions: [Insert_1.ActionInsert.textAtSelections],
                args: {
                    text: '\n',
                },
                isRepeating: true,
            });
        }
        return Promise.resolve(true);
    }
    onDidCommandMapMakesChanges(map) {
        if (!this.isRecording) {
            return Promise.resolve(false);
        }
        if (map.keys === '\n') {
            if (!this.textEditor) {
                return Promise.resolve(false);
            }
            this.recordStartPosition = this.textEditor.selection.active;
            this.recordStartLineText = this.textEditor.document.lineAt(this.recordStartPosition.line).text;
        }
        return Promise.resolve(true);
    }
    onDidChangeTextEditorSelection() {
        if (!this.textEditor) {
            return;
        }
        if (this.textEditor.selection.active.line !== this.recordStartPosition.line) {
            this.endRecord();
        }
    }
}
exports.ModeInsert = ModeInsert;
//# sourceMappingURL=Insert.js.map