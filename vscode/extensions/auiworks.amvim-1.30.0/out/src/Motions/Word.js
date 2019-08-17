"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Motion_1 = require("./Motion");
const Word_1 = require("../Utils/Word");
var MotionWordDirection;
(function (MotionWordDirection) {
    MotionWordDirection[MotionWordDirection["Prev"] = 0] = "Prev";
    MotionWordDirection[MotionWordDirection["Next"] = 1] = "Next";
})(MotionWordDirection || (MotionWordDirection = {}));
var MotionWordMatchKind;
(function (MotionWordMatchKind) {
    MotionWordMatchKind[MotionWordMatchKind["Start"] = 0] = "Start";
    MotionWordMatchKind[MotionWordMatchKind["End"] = 1] = "End";
    MotionWordMatchKind[MotionWordMatchKind["Both"] = 2] = "Both";
})(MotionWordMatchKind || (MotionWordMatchKind = {}));
class MotionWord extends Motion_1.Motion {
    constructor(args = {}) {
        super();
        this.n = args.n === undefined ? 1 : args.n;
        this.useBlankSeparatedStyle = args.useBlankSeparatedStyle === undefined ? false : args.useBlankSeparatedStyle;
    }
    static nextStart(args = {}) {
        const obj = new MotionWord(args);
        obj.direction = MotionWordDirection.Next;
        obj.matchKind = MotionWordMatchKind.Start;
        return obj;
    }
    static nextEnd(args = {}) {
        const obj = new MotionWord(args);
        obj.direction = MotionWordDirection.Next;
        obj.matchKind = MotionWordMatchKind.End;
        return obj;
    }
    static prevStart(args = {}) {
        const obj = new MotionWord(args);
        obj.direction = MotionWordDirection.Prev;
        obj.matchKind = MotionWordMatchKind.Start;
        return obj;
    }
    static prevEnd(args = {}) {
        const obj = new MotionWord(args);
        obj.direction = MotionWordDirection.Prev;
        obj.matchKind = MotionWordMatchKind.End;
        return obj;
    }
    apply(from, option = {}) {
        option.isInclusive = option.isInclusive === undefined ? false : option.isInclusive;
        option.isChangeAction = option.isChangeAction === undefined ? false : option.isChangeAction;
        option.shouldCrossLines = option.shouldCrossLines === undefined ? true : option.shouldCrossLines;
        from = super.apply(from);
        const activeTextEditor = vscode_1.window.activeTextEditor;
        if (!activeTextEditor) {
            return from;
        }
        const document = activeTextEditor.document;
        let matchKind = this.matchKind;
        for (let i = 0; i < this.n; i++) {
            // Match both start and end on last round if used in change action.
            if (i === this.n - 1 && option.isChangeAction && matchKind === MotionWordMatchKind.Start) {
                matchKind = MotionWordMatchKind.Both;
            }
            const result = this.applyOnce(document, from, matchKind, {
                isInclusive: option.isInclusive,
                shouldCrossLines: option.shouldCrossLines,
            });
            from = result.to;
            if (result.shouldStop) {
                break;
            }
        }
        return from;
    }
    applyOnce(document, from, matchKind, option) {
        let line = from.line;
        let lastPosition;
        let lastCharacterKind;
        if (this.direction === MotionWordDirection.Next) {
            while (line < document.lineCount) {
                const text = document.lineAt(line).text + '\n';
                let character = line === from.line ? from.character : 0;
                while (character < text.length) {
                    const currentCharacterKind = Word_1.UtilWord.getCharacterKind(text.charCodeAt(character), this.useBlankSeparatedStyle);
                    if (lastPosition !== undefined && lastCharacterKind !== currentCharacterKind) {
                        let startPosition;
                        let endPosition;
                        if (currentCharacterKind !== Word_1.WordCharacterKind.Blank) {
                            startPosition = new vscode_1.Position(line, character);
                        }
                        if (lastCharacterKind !== Word_1.WordCharacterKind.Blank) {
                            endPosition = lastPosition;
                            if (endPosition.isEqual(from)) {
                                endPosition = undefined;
                            }
                            else {
                                if (option.isInclusive) {
                                    endPosition = endPosition.translate(0, +1);
                                }
                            }
                        }
                        if (matchKind === MotionWordMatchKind.Start) {
                            if (startPosition !== undefined) {
                                return {
                                    to: startPosition,
                                    shouldStop: false,
                                };
                            }
                        }
                        else if (matchKind === MotionWordMatchKind.End) {
                            if (endPosition !== undefined) {
                                return {
                                    to: endPosition,
                                    shouldStop: false,
                                };
                            }
                        }
                        else if (matchKind === MotionWordMatchKind.Both) {
                            if (endPosition !== undefined) {
                                return {
                                    to: endPosition,
                                    shouldStop: false,
                                };
                            }
                            else if (startPosition !== undefined) {
                                return {
                                    to: startPosition,
                                    shouldStop: false,
                                };
                            }
                        }
                    }
                    lastPosition = new vscode_1.Position(line, character);
                    lastCharacterKind = currentCharacterKind;
                    character++;
                }
                if (!option.shouldCrossLines) {
                    return {
                        to: document.lineAt(line).range.end,
                        shouldStop: true,
                    };
                }
                line++;
            }
            // Return end position if matching failed.
            return {
                to: document.lineAt(document.lineCount - 1).range.end,
                shouldStop: true,
            };
        }
        else if (this.direction === MotionWordDirection.Prev) {
            while (line >= 0) {
                const text = document.lineAt(line).text + '\n';
                let character = line === from.line ? from.character : text.length - 1;
                while (character >= 0) {
                    const currentCharacterKind = Word_1.UtilWord.getCharacterKind(text.charCodeAt(character), this.useBlankSeparatedStyle);
                    if (lastPosition !== undefined && lastCharacterKind !== currentCharacterKind) {
                        let startPosition;
                        let endPosition;
                        if (lastCharacterKind !== Word_1.WordCharacterKind.Blank) {
                            startPosition = lastPosition;
                            if (startPosition.isEqual(from)) {
                                startPosition = undefined;
                            }
                        }
                        if (currentCharacterKind !== Word_1.WordCharacterKind.Blank) {
                            endPosition = new vscode_1.Position(line, character);
                        }
                        if (matchKind === MotionWordMatchKind.Start) {
                            if (startPosition !== undefined) {
                                return {
                                    to: startPosition,
                                    shouldStop: false,
                                };
                            }
                        }
                        else if (matchKind === MotionWordMatchKind.End) {
                            if (endPosition !== undefined) {
                                return {
                                    to: endPosition,
                                    shouldStop: false,
                                };
                            }
                        }
                        else if (matchKind === MotionWordMatchKind.Both) {
                            if (endPosition !== undefined) {
                                return {
                                    to: endPosition,
                                    shouldStop: false,
                                };
                            }
                            else if (startPosition !== undefined) {
                                return {
                                    to: startPosition,
                                    shouldStop: false,
                                };
                            }
                        }
                    }
                    lastPosition = new vscode_1.Position(line, character);
                    lastCharacterKind = currentCharacterKind;
                    character--;
                }
                if (!option.shouldCrossLines) {
                    return {
                        to: document.lineAt(line).range.start,
                        shouldStop: true,
                    };
                }
                line--;
            }
            // Return start position if matching failed.
            return {
                to: new vscode_1.Position(0, 0),
                shouldStop: true,
            };
        }
        else {
            throw new Error(`Direction is invalid: ${this.direction}`);
        }
    }
}
exports.MotionWord = MotionWord;
//# sourceMappingURL=Word.js.map