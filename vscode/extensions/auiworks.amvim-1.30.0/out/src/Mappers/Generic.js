"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var MatchResultKind;
(function (MatchResultKind) {
    MatchResultKind[MatchResultKind["FAILED"] = 0] = "FAILED";
    MatchResultKind[MatchResultKind["WAITING"] = 1] = "WAITING";
    MatchResultKind[MatchResultKind["FOUND"] = 2] = "FOUND";
})(MatchResultKind = exports.MatchResultKind || (exports.MatchResultKind = {}));
class GenericMapper {
    constructor(specialKeys = []) {
        this.root = {};
        this.specialKeys = specialKeys;
    }
    static isMapLeaf(node) {
        return node && typeof node.keys === 'string';
    }
    map(joinedKeys, args) {
        const map = {
            keys: joinedKeys,
            args: args || undefined,
        };
        let node = this.root;
        const keys = joinedKeys.split(GenericMapper.separator);
        keys.forEach((key, index) => {
            this.specialKeys.forEach(specialKey => {
                specialKey.unmapConflicts(node, key);
            });
            if (GenericMapper.isMapLeaf(node[key])) {
                delete node[key];
            }
            if (index === keys.length - 1) {
                node[key] = map;
            }
            else {
                node[key] = node[key] || {};
                node = node[key];
            }
        });
        return map;
    }
    match(inputs) {
        let node = this.root;
        let matched = true;
        let additionalArgs = {};
        let lastSpecialKeyMatch;
        for (let index = 0; index < inputs.length; index++) {
            const input = inputs[index];
            if (node[input]) {
                node = node[input];
                continue;
            }
            let match;
            this.specialKeys.some(specialKey => {
                if (!node[specialKey.indicator]) {
                    return false;
                }
                match = specialKey.matchSpecial(inputs.slice(index), additionalArgs, lastSpecialKeyMatch);
                return match ? true : false;
            });
            if (match) {
                if (match.kind === MatchResultKind.FOUND) {
                    node = node[match.specialKey.indicator];
                    lastSpecialKeyMatch = match;
                    index += match.matchedCount - 1;
                    continue;
                }
                else if (match.kind === MatchResultKind.WAITING) {
                    break;
                }
            }
            matched = false;
            break;
        }
        if (!matched) {
            return { kind: MatchResultKind.FAILED };
        }
        else if (GenericMapper.isMapLeaf(node)) {
            // Make a copy of node and args object
            const map = Object.assign({}, node);
            const args = Object.assign({}, map.args);
            Object.getOwnPropertyNames(additionalArgs).forEach(name => {
                args[name] = additionalArgs[name];
            });
            map.args = args;
            return { kind: MatchResultKind.FOUND, map };
        }
        else {
            return { kind: MatchResultKind.WAITING };
        }
    }
}
GenericMapper.separator = ' ';
exports.GenericMapper = GenericMapper;
//# sourceMappingURL=Generic.js.map