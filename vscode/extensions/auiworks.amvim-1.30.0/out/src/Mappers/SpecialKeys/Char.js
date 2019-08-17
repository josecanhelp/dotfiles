"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Generic_1 = require("../Generic");
class SpecialKeyChar {
    constructor() {
        this.indicator = '{char}';
    }
    unmapConflicts(node, keyToMap) {
        delete node[this.indicator];
        if (keyToMap === this.indicator) {
            node = {};
        }
    }
    matchSpecial(inputs, additionalArgs, lastSpecialKeyMatch) {
        let character = inputs[0];
        if (character === 'space') {
            character = ' ';
        }
        additionalArgs.character = character;
        return {
            specialKey: this,
            kind: Generic_1.MatchResultKind.FOUND,
            matchedCount: 1,
        };
    }
}
exports.SpecialKeyChar = SpecialKeyChar;
//# sourceMappingURL=Char.js.map