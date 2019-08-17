"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class RangeOffset {
    constructor(first, second) {
        if (first instanceof vscode_1.Range) {
            this.lineOffset = first.end.line - first.start.line;
            this.characterOffset = first.end.character - first.start.character;
        }
        else {
            this.lineOffset = first;
            this.characterOffset = second;
        }
    }
}
exports.RangeOffset = RangeOffset;
//# sourceMappingURL=RangeOffset.js.map