"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const GoToLine_1 = require("./Commands/GoToLine");
const Write_1 = require("./Commands/Write");
const WriteAll_1 = require("./Commands/WriteAll");
const Quit_1 = require("./Commands/Quit");
const QuitAll_1 = require("./Commands/QuitAll");
const WriteQuit_1 = require("./Commands/WriteQuit");
const WriteQuitAll_1 = require("./Commands/WriteQuitAll");
const VisualSplit_1 = require("./Commands/VisualSplit");
const NewFile_1 = require("./Commands/NewFile");
const VerticalNewFile_1 = require("./Commands/VerticalNewFile");
class ActionCommandLine {
    static run(input) {
        if (input && input[0] === ':') {
            input = input.slice(1);
        }
        if (!input || input.length === 0) {
            return Promise.resolve(false);
        }
        const commandConstructor = this.maps[input] ? this.maps[input]
            : Number.isInteger(Number(input)) ? GoToLine_1.GoToLineCommand
                : undefined;
        if (!commandConstructor) {
            return Promise.resolve(false);
        }
        const command = new commandConstructor(input);
        return command.execute();
    }
    static promptAndRun() {
        if (!vscode.window.activeTextEditor) {
            return Promise.resolve(false);
        }
        return vscode.window.showInputBox({
            prompt: 'Vim command line',
            value: ':',
            ignoreFocusOut: false,
            valueSelection: [1, 1],
        })
            .then((input) => ActionCommandLine.run(input));
    }
}
ActionCommandLine.maps = {
    'w': Write_1.WriteCommand,
    'write': Write_1.WriteCommand,
    'wa': WriteAll_1.WriteAllCommand,
    'wall': WriteAll_1.WriteAllCommand,
    'q': Quit_1.QuitCommand,
    'quit': Quit_1.QuitCommand,
    'qa': QuitAll_1.QuitAllCommand,
    'qall': QuitAll_1.QuitAllCommand,
    'wq': WriteQuit_1.WriteQuitCommand,
    'x': WriteQuit_1.WriteQuitCommand,
    'wqa': WriteQuitAll_1.WriteQuitAllCommand,
    'wqall': WriteQuitAll_1.WriteQuitAllCommand,
    'xa': WriteQuitAll_1.WriteQuitAllCommand,
    'xall': WriteQuitAll_1.WriteQuitAllCommand,
    'vs': VisualSplit_1.VerticalSplitCommand,
    'vsp': VisualSplit_1.VerticalSplitCommand,
    'new': NewFile_1.NewFileCommand,
    'vne': VerticalNewFile_1.VerticalNewFileCommand,
    'vnew': VerticalNewFile_1.VerticalNewFileCommand,
};
exports.ActionCommandLine = ActionCommandLine;
//# sourceMappingURL=CommandLine.js.map