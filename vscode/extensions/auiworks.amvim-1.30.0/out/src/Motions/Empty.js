"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Motion_1 = require("./Motion");
class MotionEmpty extends Motion_1.Motion {
    constructor() {
        super({
            isCharacterUpdated: false,
            isLinewise: false,
        });
    }
}
exports.MotionEmpty = MotionEmpty;
//# sourceMappingURL=Empty.js.map