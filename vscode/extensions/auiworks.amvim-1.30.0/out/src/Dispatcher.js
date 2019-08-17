"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Keys = require("./Keys");
const Mode_1 = require("./Modes/Mode");
const Normal_1 = require("./Modes/Normal");
const Visual_1 = require("./Modes/Visual");
const VisualLine_1 = require("./Modes/VisualLine");
const Insert_1 = require("./Modes/Insert");
const Mode_2 = require("./Actions/Mode");
const Find_1 = require("./Actions/Find");
const MoveCursor_1 = require("./Actions/MoveCursor");
const Configuration_1 = require("./Configuration");
class Dispatcher {
    constructor(context) {
        this.modes = {
            [Mode_1.ModeID.NORMAL]: new Normal_1.ModeNormal(),
            [Mode_1.ModeID.VISUAL]: new Visual_1.ModeVisual(),
            [Mode_1.ModeID.VISUAL_LINE]: new VisualLine_1.ModeVisualLine(),
            [Mode_1.ModeID.INSERT]: new Insert_1.ModeInsert(),
        };
        this.disposables = [];
        Object.keys(this.modes).forEach(key => {
            let mode = this.modes[key];
            context.subscriptions.push(vscode_1.commands.registerCommand(`amVim.mode.${mode.id}`, () => {
                this.switchMode(mode.id);
            }));
        });
        context.subscriptions.push(vscode_1.commands.registerCommand('type', args => {
            this.inputHandler(args.text)();
        }));
        context.subscriptions.push(vscode_1.commands.registerCommand('replacePreviousChar', args => {
            this.inputHandler(args.text, { replaceCharCnt: args.replaceCharCnt })();
        }));
        Keys.raws.forEach(key => {
            context.subscriptions.push(vscode_1.commands.registerCommand(`amVim.${key}`, this.inputHandler(key)));
        });
        context.subscriptions.push(vscode_1.commands.registerCommand('amVim.executeNativeFind', Find_1.ActionFind.executeNativeFind));
        MoveCursor_1.ActionMoveCursor.updatePreferredColumn();
        this.switchMode(Configuration_1.Configuration.defaultModeID);
        this.disposables.push(vscode_1.window.onDidChangeTextEditorSelection(() => {
            // Ensure this is executed after all pending commands.
            setTimeout(() => {
                Mode_2.ActionMode.switchByActiveSelections(this._currentMode.id);
                MoveCursor_1.ActionMoveCursor.updatePreferredColumn();
                this._currentMode.onDidChangeTextEditorSelection();
            }, 0);
        }), vscode_1.window.onDidChangeActiveTextEditor(() => {
            if (Configuration_1.Configuration.defaultModeID === Mode_1.ModeID.INSERT) {
                Mode_2.ActionMode.toInsert();
            }
            else {
                // Passing `null` to `currentMode` to force mode switch.
                Mode_2.ActionMode.switchByActiveSelections(null);
            }
            MoveCursor_1.ActionMoveCursor.updatePreferredColumn();
        }));
    }
    get currentMode() { return this._currentMode; }
    inputHandler(key, args = {}) {
        return () => {
            this._currentMode.input(key, args);
        };
    }
    switchMode(id) {
        const lastMode = this._currentMode;
        if (lastMode) {
            lastMode.exit();
        }
        this._currentMode = this.modes[id];
        this._currentMode.enter();
        vscode_1.commands.executeCommand('setContext', 'amVim.mode', this._currentMode.name);
        // For use in repeat command
        if (lastMode) {
            this._currentMode.onDidRecordFinish(lastMode.recordedCommandMaps, lastMode.id);
        }
    }
    dispose() {
        vscode_1.Disposable.from(...this.disposables).dispose();
        Object.keys(this.modes).forEach(id => {
            (this.modes[id]).dispose();
        });
    }
}
exports.Dispatcher = Dispatcher;
//# sourceMappingURL=Dispatcher.js.map