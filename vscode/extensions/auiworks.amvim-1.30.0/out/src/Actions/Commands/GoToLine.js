"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Base_1 = require("./Base");
const MoveCursor_1 = require("../MoveCursor");
const Document_1 = require("../../Motions/Document");
const Line_1 = require("../../Motions/Line");
class GoToLineCommand extends Base_1.Command {
    constructor(input) {
        super(input);
        this.line = Number(this.input);
    }
    execute() {
        if (!Number.isInteger(this.line)) {
            return Promise.resolve(false);
        }
        return MoveCursor_1.ActionMoveCursor.byMotions({
            motions: [
                Document_1.MotionDocument.toLine({ n: this.line }),
                Line_1.MotionLine.firstNonBlank()
            ],
            noEmptyAtLineEnd: true,
        });
    }
}
exports.GoToLineCommand = GoToLineCommand;
//# sourceMappingURL=GoToLine.js.map