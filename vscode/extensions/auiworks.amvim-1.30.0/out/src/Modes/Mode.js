"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const StaticReflect_1 = require("../LanguageExtensions/StaticReflect");
const Metadata_1 = require("../Symbols/Metadata");
const Generic_1 = require("../Mappers/Generic");
const Command_1 = require("../Mappers/Command");
var ModeID;
(function (ModeID) {
    ModeID[ModeID["NORMAL"] = 0] = "NORMAL";
    ModeID[ModeID["VISUAL"] = 1] = "VISUAL";
    ModeID[ModeID["VISUAL_LINE"] = 2] = "VISUAL_LINE";
    ModeID[ModeID["INSERT"] = 3] = "INSERT";
})(ModeID = exports.ModeID || (exports.ModeID = {}));
class Mode {
    constructor() {
        this.pendings = [];
        this.executing = false;
        this.inputs = [];
        this.mapper = new Command_1.CommandMapper();
    }
    enter() {
        this.updateStatusBar();
    }
    updateStatusBar(message) {
        let status = `-- ${this.name} --`;
        if (message) {
            status += ` ${message}`;
        }
        vscode_1.window.setStatusBarMessage(status);
    }
    exit() {
        this.clearInputs();
        this.clearPendings();
    }
    dispose() {
        this.exit();
    }
    clearInputs() {
        this.inputs = [];
    }
    clearPendings() {
        this.pendings = [];
    }
    input(key, args = {}) {
        let inputs;
        if (key === 'escape') {
            inputs = [key];
        }
        else {
            this.inputs.push(key);
            inputs = this.inputs;
        }
        const { kind, map } = this.mapper.match(inputs);
        if (kind === Generic_1.MatchResultKind.FAILED) {
            this.updateStatusBar();
            this.clearInputs();
        }
        else if (kind === Generic_1.MatchResultKind.FOUND) {
            this.updateStatusBar();
            this.clearInputs();
            this.pushCommandMap(map);
            this.execute();
        }
        else if (kind === Generic_1.MatchResultKind.WAITING) {
            this.updateStatusBar(`${this.inputs.join(' ')} and...`);
        }
        return kind;
    }
    pushCommandMap(map) {
        this.pendings.push(map);
    }
    /**
     * Override this to return recorded command maps.
     */
    get recordedCommandMaps() { return []; }
    /**
     * Override this to do something before command map makes changes.
     */
    onWillCommandMapMakesChanges(map) {
        return Promise.resolve(true);
    }
    /**
     * Override this to do something after command map made changes.
     */
    onDidCommandMapMakesChanges(map) {
        return Promise.resolve(true);
    }
    /**
     * Override this to do something after selection changes.
     */
    onDidChangeTextEditorSelection() { }
    /**
     * Override this to do something after recording ends.
     */
    onDidRecordFinish(recordedCommandMaps, lastModeID) { }
    execute() {
        if (this.executing) {
            return;
        }
        this.executing = true;
        const one = () => {
            const map = this.pendings.shift();
            if (!map) {
                this.executing = false;
                return;
            }
            let promise = Promise.resolve(true);
            const isAnyActionIsChange = map.actions.some(action => {
                return StaticReflect_1.StaticReflect.getMetadata(Metadata_1.SymbolMetadata.Action.isChange, action);
            });
            if (isAnyActionIsChange) {
                promise = promise.then(() => this.onWillCommandMapMakesChanges(map));
            }
            map.actions.forEach(action => {
                promise = promise.then(() => action(map.args));
            });
            if (isAnyActionIsChange) {
                promise = promise.then(() => this.onDidCommandMapMakesChanges(map));
            }
            promise.then(one.bind(this), () => {
                this.clearPendings();
                this.executing = false;
            });
        };
        one();
    }
}
exports.Mode = Mode;
//# sourceMappingURL=Mode.js.map