"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Motion_1 = require("./Motion");
class MotionCharacter extends Motion_1.Motion {
    constructor(args = {}) {
        super(args);
    }
    static left(args = {}) {
        args.n = args.n === undefined ? 1 : args.n;
        const obj = new MotionCharacter();
        obj.translate(0, -args.n);
        return obj;
    }
    static right(args = {}) {
        args.n = args.n === undefined ? 1 : args.n;
        const obj = new MotionCharacter();
        obj.translate(0, +args.n);
        return obj;
    }
    static up(args = {}) {
        args.n = args.n === undefined ? 1 : args.n;
        const obj = new MotionCharacter({
            isLinewise: true,
            isCharacterUpdated: false,
        });
        obj.translate(-args.n, 0);
        return obj;
    }
    static down(args = {}) {
        args.n = args.n === undefined ? 1 : args.n;
        const obj = new MotionCharacter({
            isLinewise: true,
            isCharacterUpdated: false,
        });
        obj.translate(+args.n, 0);
        return obj;
    }
}
exports.MotionCharacter = MotionCharacter;
//# sourceMappingURL=Character.js.map