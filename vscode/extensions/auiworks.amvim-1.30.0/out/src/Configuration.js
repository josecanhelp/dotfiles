"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const Mode_1 = require("./Modes/Mode");
const Word_1 = require("./Utils/Word");
class Configuration {
    static get defaultModeID() { return this._defaultModeID; }
    static get smartRelativeLineNumbers() { return this._smartRelativeLineNumbers; }
    static init() {
        if (this.isReady) {
            return;
        }
        this.isReady = true;
        this.onDidChangeConfiguration();
        this.disposables.push(vscode_1.workspace.onDidChangeConfiguration(() => this.onDidChangeConfiguration()));
    }
    static onDidChangeConfiguration() {
        this.updateCache();
        this.updateKeybindingContexts();
        this._defaultModeID = this.getExtensionSetting('startInInsertMode', false) ? Mode_1.ModeID.INSERT : Mode_1.ModeID.NORMAL;
        this._smartRelativeLineNumbers = this.getExtensionSetting('smartRelativeLineNumbers', false);
        Word_1.UtilWord.updateCharacterKindCache(this.getEditorSetting('wordSeparators', '`~!@#$%^&*()-=+[{]}\\|;:\'",.<>/?'));
    }
    static updateCache() {
        this.extensionNamespace = vscode_1.workspace.getConfiguration('amVim');
        this.editorNamespace = vscode_1.workspace.getConfiguration('editor');
    }
    static updateKeybindingContexts() {
        vscode_1.commands.executeCommand('setContext', 'amVim.configuration.shouldBindCtrlCommands', this.getExtensionSetting('bindCtrlCommands', true));
        vscode_1.commands.executeCommand('setContext', 'amVim.configuration.shouldMimicVimSearchBehavior', this.getExtensionSetting('mimicVimSearchBehavior', true));
        vscode_1.commands.executeCommand('setContext', 'amVim.configuration.shouldUseVimStyleNavigationInListView', this.getExtensionSetting('vimStyleNavigationInListView', true));
    }
    static getExtensionSetting(section, defaultValue) {
        return this.extensionNamespace.get(section, defaultValue);
    }
    static getEditorSetting(section, defaultValue) {
        return this.editorNamespace.get(section, defaultValue);
    }
    /**
     * Remarks: Workaround undefined bug in native API.
     */
    static getInsertSpace() {
        if (vscode_1.window.activeTextEditor) {
            const options = vscode_1.window.activeTextEditor.options;
            if (options.insertSpaces !== undefined) {
                return options.insertSpaces;
            }
        }
        return this.getEditorSetting('insertSpaces', true);
    }
    /**
     * Remarks: Workaround undefined bug in native API.
     */
    static getTabSize() {
        if (vscode_1.window.activeTextEditor) {
            const options = vscode_1.window.activeTextEditor.options;
            if (options.tabSize !== undefined) {
                return options.tabSize;
            }
        }
        return this.getEditorSetting('tabSize', 4);
    }
    static dispose() {
        vscode_1.Disposable.from(...this.disposables).dispose();
    }
}
Configuration.isReady = false;
Configuration.disposables = [];
exports.Configuration = Configuration;
//# sourceMappingURL=Configuration.js.map