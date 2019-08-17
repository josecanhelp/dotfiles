"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Generic_1 = require("./Generic");
const N_1 = require("./SpecialKeys/N");
const Char_1 = require("./SpecialKeys/Char");
const Motion_1 = require("./SpecialKeys/Motion");
const TextObject_1 = require("./SpecialKeys/TextObject");
class CommandMapper extends Generic_1.GenericMapper {
    constructor() {
        super([
            new N_1.SpecialKeyN(),
            new Motion_1.SpecialKeyMotion(),
            new TextObject_1.SpecialKeyTextObject(),
            new Char_1.SpecialKeyChar(),
        ]);
    }
    map(joinedKeys, actions, args) {
        const map = super.map(joinedKeys, args);
        map.actions = actions;
    }
    match(inputs) {
        const { kind, map } = super.match(inputs);
        return {
            kind,
            map: map ? map : undefined
        };
    }
}
exports.CommandMapper = CommandMapper;
//# sourceMappingURL=Command.js.map