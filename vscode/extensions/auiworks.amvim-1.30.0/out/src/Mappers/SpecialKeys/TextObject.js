"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Generic_1 = require("../Generic");
const Block_1 = require("../../TextObjects/Block");
const QuotedString_1 = require("../../TextObjects/QuotedString");
const Word_1 = require("../../TextObjects/Word");
class SpecialKeyTextObject extends Generic_1.GenericMapper {
    constructor() {
        super();
        this.indicator = '{textObject}';
        this.conflictRegExp = /^[ai]|\{char\}$/;
        this.mapInfos = [
            {
                characters: ['b', '(', ')'],
                method: Block_1.TextObjectBlock.byParentheses,
            },
            {
                characters: ['[', ']'],
                method: Block_1.TextObjectBlock.byBrackets,
            },
            {
                characters: ['B', '{', '}'],
                method: Block_1.TextObjectBlock.byBraces,
            },
            {
                characters: ['<', '>'],
                method: Block_1.TextObjectBlock.byChevrons,
            },
            {
                characters: ['\''],
                method: QuotedString_1.TextObjectQuotedString.bySingle,
            },
            {
                characters: ['"'],
                method: QuotedString_1.TextObjectQuotedString.byDouble,
            },
            {
                characters: ['`'],
                method: QuotedString_1.TextObjectQuotedString.byBackward,
            },
            {
                characters: ['w'],
                method: Word_1.TextObjectWord.byWord,
                args: { useBlankSeparatedStyle: false },
            },
            {
                characters: ['W'],
                method: Word_1.TextObjectWord.byWord,
                args: { useBlankSeparatedStyle: true },
            },
        ];
        this.maps = [
        // Reserved for special maps.
        ];
        this.mapInfos.forEach(mapInfo => {
            mapInfo.characters.forEach(character => {
                this.map(`a ${character}`, mapInfo.method, Object.assign({}, mapInfo.args, { isInclusive: true }));
                this.map(`i ${character}`, mapInfo.method, Object.assign({}, mapInfo.args, { isInclusive: false }));
            });
        });
        this.maps.forEach(map => {
            this.map(map.keys, map.textObjectGenerator, map.args);
        });
    }
    map(joinedKeys, textObjectGenerator, args) {
        const map = super.map(joinedKeys, args);
        map.textObjectGenerator = textObjectGenerator;
    }
    unmapConflicts(node, keyToMap) {
        if (keyToMap === this.indicator) {
            Object.getOwnPropertyNames(node).forEach(key => {
                this.conflictRegExp.test(key) && delete node[key];
            });
        }
        if (this.conflictRegExp.test(keyToMap)) {
            delete node[this.indicator];
        }
        // This class has lower priority than other keys.
    }
    matchSpecial(inputs, additionalArgs, lastSpecialKeyMatch) {
        const { kind, map } = this.match(inputs);
        if (kind === Generic_1.MatchResultKind.FAILED) {
            return null;
        }
        if (map) {
            additionalArgs.textObject = map.textObjectGenerator(map.args);
        }
        return {
            specialKey: this,
            kind,
            matchedCount: inputs.length,
        };
    }
}
exports.SpecialKeyTextObject = SpecialKeyTextObject;
//# sourceMappingURL=TextObject.js.map