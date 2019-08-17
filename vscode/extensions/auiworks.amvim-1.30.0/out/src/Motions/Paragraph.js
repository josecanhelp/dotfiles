"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Motion_1 = require("./Motion");
var Direction;
(function (Direction) {
    Direction[Direction["Prev"] = 0] = "Prev";
    Direction[Direction["Next"] = 1] = "Next";
})(Direction || (Direction = {}));
class MotionParagraph extends Motion_1.Motion {
    constructor(args) {
        args.n = args.n === undefined ? 1 : args.n;
        super();
        this.direction = args.direction;
        this.n = args.n;
    }
    static prev(args) {
        return new MotionParagraph({
            direction: Direction.Prev,
            n: args.n,
        });
    }
    static next(args) {
        return new MotionParagraph({
            direction: Direction.Next,
            n: args.n,
        });
    }
    apply(from) {
        from = super.apply(from);
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor || this.direction === undefined || this.n === undefined) {
            return from;
        }
        const document = activeTextEditor.document;
        for (let i = 0; i < this.n; i++) {
            const result = this.applyOnce(document, from);
            from = result.to;
            if (result.shouldStop) {
                break;
            }
        }
        return from;
    }
    applyOnce(document, from) {
        let toLine = undefined;
        let toCharacter = 0;
        let shouldStop = false;
        // Skip first group of empty lines if currently on empty line.
        let shouldSkip = MotionParagraph.isLineEmpty(document, from.line);
        if (this.direction === Direction.Prev) {
            for (let i = from.line - 1; i >= 0; i--) {
                const isLineEmpty = MotionParagraph.isLineEmpty(document, i);
                if (shouldSkip) {
                    if (!isLineEmpty) {
                        shouldSkip = false;
                    }
                    continue;
                }
                if (isLineEmpty) {
                    toLine = i;
                    break;
                }
            }
            if (toLine === undefined) {
                shouldStop = true;
                toLine = 0;
            }
        }
        else {
            for (let i = from.line + 1; i < document.lineCount; i++) {
                const isLineEmpty = MotionParagraph.isLineEmpty(document, i);
                if (shouldSkip) {
                    if (!isLineEmpty) {
                        shouldSkip = false;
                    }
                    continue;
                }
                if (isLineEmpty) {
                    toLine = i;
                    break;
                }
            }
            if (toLine === undefined) {
                shouldStop = true;
                toLine = document.lineCount - 1;
                toCharacter = document.lineAt(toLine).text.length;
            }
        }
        return {
            to: new vscode_1.Position(toLine, toCharacter),
            shouldStop: shouldStop,
        };
    }
    static isLineEmpty(document, line) {
        return document.lineAt(line).text === '';
    }
}
exports.MotionParagraph = MotionParagraph;
//# sourceMappingURL=Paragraph.js.map