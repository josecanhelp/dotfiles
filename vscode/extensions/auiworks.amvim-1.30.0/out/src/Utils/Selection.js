"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
class UtilSelection {
    static unionOverlaps(from) {
        // Make a copy so we won't destroy the array passed in.
        from = from.map(selection => selection);
        const to = [];
        while (from.length > 0) {
            let a = from.shift();
            for (let i = 0; i < from.length; i++) {
                const b = from[i];
                if (a.intersection(b) !== undefined) {
                    const unionedRange = a.union(b);
                    a = a.isReversed
                        ? new vscode_1.Selection(unionedRange.end, unionedRange.start)
                        : new vscode_1.Selection(unionedRange.start, unionedRange.end);
                    from.splice(i, 1);
                    i--;
                }
            }
            to.push(a);
        }
        return to;
    }
    static shrinkToActive(selection) {
        const line = selection.active.line;
        let character = selection.active.character;
        if (!selection.isEmpty && !selection.isReversed && character > 0) {
            character--;
        }
        return new vscode_1.Selection(line, character, line, character);
    }
    static shrinkToActives(selections) {
        return selections.map(selection => UtilSelection.shrinkToActive(selection));
    }
    static getActiveInVisualMode(first, second) {
        let active;
        let isReversed;
        if (second) {
            isReversed = first.isAfter(second);
            active = second;
        }
        else {
            isReversed = first.isReversed;
            active = first.active;
        }
        return !isReversed && active.character > 0
            ? active.translate(0, -1)
            : active;
    }
}
exports.UtilSelection = UtilSelection;
//# sourceMappingURL=Selection.js.map