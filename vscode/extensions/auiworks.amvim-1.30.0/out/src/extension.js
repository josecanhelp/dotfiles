"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Configuration_1 = require("./Configuration");
const Dispatcher_1 = require("./Dispatcher");
let dispatcher;
function activate(context) {
    Configuration_1.Configuration.init();
    dispatcher = new Dispatcher_1.Dispatcher(context);
    context.subscriptions.push(Configuration_1.Configuration, dispatcher);
}
exports.activate = activate;
function getCurrentMode() {
    return dispatcher ? dispatcher.currentMode : null;
}
exports.getCurrentMode = getCurrentMode;
//# sourceMappingURL=extension.js.map