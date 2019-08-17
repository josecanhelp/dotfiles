"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Motion_1 = require("./Motion");
const Empty_1 = require("./Empty");
var MotionMatchDirection;
(function (MotionMatchDirection) {
    MotionMatchDirection[MotionMatchDirection["NEXT"] = 0] = "NEXT";
    MotionMatchDirection[MotionMatchDirection["PREV"] = 1] = "PREV";
})(MotionMatchDirection || (MotionMatchDirection = {}));
class MotionMatch extends Motion_1.Motion {
    constructor() {
        super(...arguments);
        this.isRepeat = false;
    }
    static next(args) {
        args.isTill = args.isTill === undefined ? false : args.isTill;
        const obj = new MotionMatch();
        obj.character = args.character;
        obj.direction = MotionMatchDirection.NEXT;
        obj.isTill = args.isTill;
        obj.n = args.n === undefined ? 1 : args.n;
        MotionMatch.last = obj;
        return obj;
    }
    static prev(args) {
        args.isTill = args.isTill === undefined ? false : args.isTill;
        const obj = new MotionMatch();
        obj.character = args.character;
        obj.direction = MotionMatchDirection.PREV;
        obj.isTill = args.isTill;
        obj.n = args.n === undefined ? 1 : args.n;
        MotionMatch.last = obj;
        return obj;
    }
    static clearLast() {
        MotionMatch.last = undefined;
    }
    static repeatLast(args) {
        return MotionMatch.last ? MotionMatch.last.clone(args) : new Empty_1.MotionEmpty();
    }
    clone(args) {
        args.isReverse = args.isReverse === undefined ? false : args.isReverse;
        args.n = args.n === undefined ? 1 : args.n;
        const obj = new MotionMatch();
        obj.character = this.character;
        obj.direction = args.isReverse
            ? (this.direction === MotionMatchDirection.NEXT ? MotionMatchDirection.PREV : MotionMatchDirection.NEXT)
            : this.direction;
        obj.isTill = this.isTill;
        obj.n = args.n;
        obj.isRepeat = true;
        return obj;
    }
    apply(from, option = {}) {
        option.isInclusive = option.isInclusive === undefined ? false : option.isInclusive;
        from = super.apply(from);
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor || this.direction === undefined || !this.character) {
            return from;
        }
        const document = activeTextEditor.document;
        let toLine = from.line;
        let toCharacter = from.character;
        let targetText = document.lineAt(toLine).text;
        let shouldSkip = false;
        if (this.isRepeat && this.isTill && this.n === 1) {
            if (this.direction === MotionMatchDirection.NEXT) {
                shouldSkip = targetText[toCharacter + 1] === this.character;
            }
            else if (this.direction === MotionMatchDirection.PREV) {
                shouldSkip = targetText[toCharacter - 1] === this.character;
            }
        }
        if (this.direction === MotionMatchDirection.NEXT) {
            targetText = targetText.substr(toCharacter + 1 + (shouldSkip ? 1 : 0));
            let offset = -1;
            for (let i = 0; i < this.n; i++) {
                offset = targetText.indexOf(this.character, offset + 1);
                if (!~offset) {
                    break;
                }
            }
            if (!!~offset) {
                toCharacter += offset + 1 + (shouldSkip ? 1 : 0);
                if (option.isInclusive) {
                    toCharacter += 1;
                }
                if (this.isTill) {
                    toCharacter -= 1;
                }
            }
        }
        else if (this.direction === MotionMatchDirection.PREV) {
            targetText = targetText
                .substr(0, toCharacter - (shouldSkip ? 1 : 0))
                .split('').reverse().join('');
            let offset = -1;
            for (let i = 0; i < this.n; i++) {
                offset = targetText.indexOf(this.character, offset + 1);
                if (!~offset) {
                    break;
                }
            }
            if (!!~offset) {
                toCharacter -= offset + 1 + (shouldSkip ? 1 : 0);
                if (this.isTill) {
                    toCharacter += 1;
                }
            }
        }
        return new vscode_1.Position(toLine, toCharacter);
    }
}
exports.MotionMatch = MotionMatch;
//# sourceMappingURL=Match.js.map