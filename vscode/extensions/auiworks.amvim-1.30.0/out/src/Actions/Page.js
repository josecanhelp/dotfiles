"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Selection_1 = require("./Selection");
var PageMoveType;
(function (PageMoveType) {
    PageMoveType[PageMoveType["Normal"] = 0] = "Normal";
    PageMoveType[PageMoveType["Select"] = 1] = "Select";
    PageMoveType[PageMoveType["SelectLine"] = 2] = "SelectLine";
})(PageMoveType = exports.PageMoveType || (exports.PageMoveType = {}));
class ActionPage {
    static up(args = {}) {
        args.moveType = args.moveType === undefined ? PageMoveType.Normal : args.moveType;
        if (args.moveType === PageMoveType.Normal) {
            return vscode_1.commands.executeCommand('cursorPageUp');
        }
        else {
            const thenable = vscode_1.commands.executeCommand('cursorPageUpSelect');
            if (args.moveType === PageMoveType.SelectLine) {
                thenable.then(() => Selection_1.ActionSelection.expandToLine());
            }
            return thenable;
        }
    }
    static down(args = {}) {
        args.moveType = args.moveType === undefined ? PageMoveType.Normal : args.moveType;
        if (args.moveType === PageMoveType.Normal) {
            return vscode_1.commands.executeCommand('cursorPageDown');
        }
        else {
            const thenable = vscode_1.commands.executeCommand('cursorPageDownSelect');
            if (args.moveType === PageMoveType.SelectLine) {
                thenable.then(() => Selection_1.ActionSelection.expandToLine());
            }
            return thenable;
        }
    }
}
exports.ActionPage = ActionPage;
//# sourceMappingURL=Page.js.map