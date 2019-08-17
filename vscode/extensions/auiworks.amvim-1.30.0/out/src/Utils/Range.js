"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class UtilRange {
    static unionOverlaps(from) {
        // Make a copy so we won't destroy the array passed in.
        from = from.map(range => range);
        const to = [];
        while (from.length > 0) {
            let a = from.shift();
            for (let i = 0; i < from.length; i++) {
                const b = from[i];
                if (a.intersection(b) !== undefined) {
                    a = a.union(b);
                    from.splice(i, 1);
                    i--;
                }
            }
            to.push(a);
        }
        return to;
    }
    static toLinewise(from, document) {
        let startLine;
        let startCharacter;
        if (from.start.line !== 0 && from.end.line === document.lineCount - 1) {
            startLine = from.start.line - 1;
            startCharacter = Infinity;
        }
        else {
            startLine = from.start.line;
            startCharacter = 0;
        }
        return document.validateRange(new vscode_1.Range(startLine, startCharacter, from.end.line + 1, 0));
    }
    static isSingleCharacter(range) {
        return range.start.line === range.end.line && range.end.character - range.start.character === 1;
    }
}
exports.UtilRange = UtilRange;
//# sourceMappingURL=Range.js.map