"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function isObject(x) {
    return typeof x === 'object' ? x !== null : typeof x === 'function';
}
function isUndefined(x) {
    return x === undefined;
}
function isConstructor(x) {
    return typeof x === 'function';
}
/**
 * Static version of https://github.com/rbuckton/ReflectDecorators/ (Partial)
 * Save metadata as static so we can get it without context.
 */
class StaticReflect {
    static obtainMetadata(target, shouldCreateWhenNotExist = false) {
        for (let i = 0; i < this.metadataMaps.length; i++) {
            const map = this.metadataMaps[i];
            if (map.target === target) {
                return map.metadata;
            }
        }
        if (shouldCreateWhenNotExist) {
            const map = {
                target,
                metadata: {}
            };
            this.metadataMaps.push(map);
            return map.metadata;
        }
        else {
            return undefined;
        }
    }
    /**
      * A default metadata decorator factory that can be used on a class, class member, or parameter.
      * @param metadataKey The key for the metadata entry.
      * @param metadataValue The value for the metadata entry.
      * @returns A decorator function.
      * @remarks
      * If `metadataKey` is already defined for the target and target key, the
      * metadataValue for that key will be overwritten.
      * @example
      *
      *     // constructor
      *     @StaticReflect.metadata(key, value)
      *     class C {
      *     }
      *
      *     // property (on constructor)
      *     class C {
      *         @StaticReflect.metadata(key, value)
      *         static staticProperty;
      *     }
      *
      *     // property (on prototype)
      *     class C {
      *         @StaticReflect.metadata(key, value)
      *         property;
      *     }
      *
      *     // method (on constructor)
      *     class C {
      *         @StaticReflect.metadata(key, value)
      *         static staticMethod() { }
      *     }
      *
      *     // method (on prototype)
      *     class C {
      *         @StaticReflect.metadata(key, value)
      *         method() { }
      *     }
      */
    static metadata(key, value) {
        function decorator(targetObject, targetKey) {
            if (!isUndefined(targetKey)) {
                if (!isObject(targetObject)) {
                    throw new TypeError();
                }
                StaticReflect.defineMetadata(key, value, targetObject[targetKey]);
            }
            else {
                if (!isConstructor(targetObject)) {
                    throw new TypeError();
                }
                StaticReflect.defineMetadata(key, value, targetObject);
            }
        }
        return decorator;
    }
    static defineMetadata(key, value, target) {
        const metadata = this.obtainMetadata(target, true);
        metadata[key] = value;
    }
    static getMetadata(key, target) {
        const metadata = this.obtainMetadata(target);
        if (metadata !== undefined) {
            return metadata[key];
        }
        else {
            return undefined;
        }
    }
}
StaticReflect.metadataMaps = [];
exports.StaticReflect = StaticReflect;
//# sourceMappingURL=StaticReflect.js.map