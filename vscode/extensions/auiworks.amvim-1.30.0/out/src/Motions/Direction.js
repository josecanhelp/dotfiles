"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Motion_1 = require("./Motion");
var Direction;
(function (Direction) {
    Direction[Direction["Prev"] = 0] = "Prev";
    Direction[Direction["Next"] = 1] = "Next";
})(Direction || (Direction = {}));
class MotionDirection extends Motion_1.Motion {
    constructor(args) {
        args.n = args.n === undefined ? 1 : args.n;
        super();
        this.direction = args.direction;
        this.n = args.n;
    }
    static prev(args = {}) {
        return new MotionDirection({
            direction: Direction.Prev,
            n: args.n,
        });
    }
    static next(args = {}) {
        return new MotionDirection({
            direction: Direction.Next,
            n: args.n,
        });
    }
    apply(from, option) {
        from = super.apply(from);
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor || this.direction === undefined || this.n === undefined) {
            return from;
        }
        const document = activeTextEditor.document;
        const _lengthByLine = [];
        const getLengthOfLine = (line) => {
            if (_lengthByLine[line] === undefined) {
                _lengthByLine[line] = document.lineAt(line).text.length;
            }
            return _lengthByLine[line];
        };
        const offset = this.direction === Direction.Prev ? -1 : +1;
        let toLine = from.line;
        let toCharacter = from.character;
        for (let i = 0; i < this.n; i++) {
            toCharacter += offset;
            if (toCharacter < 0) {
                toLine--;
                if (toLine < 0) {
                    toLine = 0;
                    toCharacter = 0;
                    break;
                }
                toCharacter = Math.max(getLengthOfLine(toLine) - 1, 0);
            }
            else if (toCharacter >= getLengthOfLine(toLine)) {
                toLine++;
                if (toLine >= document.lineCount) {
                    toLine = Math.max(document.lineCount - 1, 0);
                    toCharacter = Math.max(getLengthOfLine(toLine) - 1, 0);
                    break;
                }
                toCharacter = 0;
            }
        }
        return new vscode_1.Position(toLine, toCharacter);
    }
}
exports.MotionDirection = MotionDirection;
//# sourceMappingURL=Direction.js.map