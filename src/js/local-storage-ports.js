'use strict';

var _slicedToArray = function () {
    function sliceIterator(arr, i) {
        var _arr = [];
        var _n = true;
        var _d = false;
        var _e = undefined;
        try {
            for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {
                _arr.push(_s.value);
                if (i && _arr.length === i) break;
            }
        } catch (err) {
            _d = true;
            _e = err;
        } finally {
            try {
                if (!_n && _i["return"]) _i["return"]();
            } finally {
                if (_d) throw _e;
            }
        }
        return _arr;
    }

    return function (arr, i) {
        if (Array.isArray(arr)) {
            return arr;
        } else if (Symbol.iterator in Object(arr)) {
            return sliceIterator(arr, i);
        } else {
            throw new TypeError("Invalid attempt to destructure non-iterable instance");
        }
    };
}();

module.exports = {
    register: register,
    samplePortName: 'storageGetItem'
};

var storageEventListenerPorts = [];

window.addEventListener('storage', function (storageEvent) {
    if (storageEvent.newValue === null) {
        storageEventListenerPorts.forEach(function (ports) {
            ports.storageOnKeyRemoved.send([storageEvent.key, (storageEvent.oldValue)]);
        });
    } else if (storageEvent.oldValue === null) {
        storageEventListenerPorts.forEach(function (ports) {
            ports.storageOnKeyAdded.send([storageEvent.key, (storageEvent.newValue)]);
        });
    } else {
        storageEventListenerPorts.forEach(function (ports) {
            ports.storageOnKeyChanged.send([storageEvent.key, storageEvent.oldValue, storageEvent.newValue]);
        });
    }
});

/**
 * Subscribe the given Elm app ports to ports from the Elm LocalStorage ports module.
 *
 * @param  {Object}   ports  Ports object from an Elm app
 * @param  {Function} log    Function to log ports for the given Elm app
 */
function register(ports, log) {
    log = typeof log === 'function'
        ? log
        : function () {};

    // Mapped to Storage API: https://developer.mozilla.org/en-US/docs/Web/API/Storage
    if (typeof ports.storageGetItem !== 'undefined') {
        ports.storageGetItem.subscribe(storageGetItem);
    } else {
        log(`No such port found: storageGetItem`)
    }
    if (typeof ports.storageSetItem !== 'undefined') {
        ports.storageSetItem.subscribe(storageSetItem);
    } else {
        log(`No such port found: storageSetItem`)
    }
    if (typeof ports.storageRemoveItem !== 'undefined') {
        ports.storageRemoveItem.subscribe(storageRemoveItem);
    } else {
        log(`No such port found: storageRemoveItem`)
    }
    if (typeof ports.storageClear !== 'undefined') {
        ports.storageClear.subscribe(storageClear);
    } else {
        log(`No such port found: storageClear`)
    }
    if (typeof ports.storagePushToSet !== 'undefined') {
        ports.storagePushToSet.subscribe(storagePushToSet);
    } else {
        log(`No such port found: storagePushToSet`)
    }
    if (typeof ports.storageRemoveFromSet !== 'undefined') {
        ports.storageRemoveFromSet.subscribe(storageRemoveFromSet);
    } else {
        log(`No such port found: storageRemoveFromSet`)
    }
    if (typeof ports.storageGetAndThen !== 'undefined') {
        ports.storageGetAndThen.subscribe(storageGetAndThen);
    } else {
        log(`No such port found: storageGetAndThen`)
    }

    // StorageEvent API
    storageEventListenerPorts.push(ports);

    function storageGetItem(key) {
        log('storageGetItem', key);
        var response = getLocalStorageItem(key);

        log('storageGetItemResponse', key, response);
        setTimeout(() => {ports.storageGetItemResponse.send([key, response])}, 2000);
    }

    function storageSetItem(_ref) {
        var _ref2 = _slicedToArray(_ref, 2),
            key = _ref2[0],
            value = _ref2[1];

        log('storageSetItem', key, value);
        setLocalStorageItem(key, value);
    }

    function storageRemoveItem(key) {
        log('storageRemoveItem', key);
        window.localStorage.removeItem(key);
    }

    function storageClear() {
        log('storageClear');
        window.localStorage.clear();
    }

    // A Set is a list with only unique values. (No duplication.)
    function storagePushToSet(_ref3) {
        var _ref4 = _slicedToArray(_ref3, 2),
            key = _ref4[0],
            value = _ref4[1];

        log('storagePushToSet', key, value);

        var item = getLocalStorageItem(key);
        var list = Array.isArray(item) ? item : [];

        if (list.indexOf(value) === -1) {
            list.push(value);
        }

        setLocalStorageItem(key, list);
    }

    function storageRemoveFromSet(_ref5) {
        var _ref6 = _slicedToArray(_ref5, 2),
            key = _ref6[0],
            value = _ref6[1];

        log('storageRemoveFromSet', key, value);

        var list = getLocalStorageItem(key);

        if (!Array.isArray(list)) {
            log('storageRemoveFromSet [aborting; not a list]', key, value, list);
            return;
        }

        // Filter based on JSON strings in to ensure equality-by-value instead of equality-by-reference
        var jsonValue = JSON.stringify(value);
        var updatedSet = list.filter(function (item) {
            return jsonValue !== JSON.stringify(item);
        });

        setLocalStorageItem(key, updatedSet);
    }

    function storageGetAndThen([key, keys, andThens]) {
        log('storageGetAndThen', key, keys, andThens);
        let response = getAndThen(keys, andThens);
        ports.storageGetItemResponse.send([key, response]);
    }
}

/**
 * Get a JSON serialized value from localStorage. (Return the deserialized version.)
 *
 * @param  {String} key Key in localStorage
 * @return {*}      The deserialized value
 */
function getLocalStorageItem(key) {
    try {
        return JSON.parse(window.localStorage.getItem(key));
    } catch (e) {
        return null;
    }
}

/**
 * Set a value of any type in localStorage.
 * (Serializes in JSON before storing since Storage objects can only hold strings.)
 *
 * @param {String} key   Key in localStorage
 * @param {*}      value The value to set
 */
function setLocalStorageItem(key, value) {
    window.localStorage.setItem(key, JSON.stringify(value));
}

function getAndThen(keys = [], prefixes = []) {
    try {
        for (let i = 0; i < prefixes.length; ++i) {
            keys = keys.filter(key => key !== null);
            if (keys.every(Array.isArray)) {
                keys = [].concat(...keys);
            }
            keys = keys.filter(key => typeof key === 'string');
            const prefix = prefixes[i];
            if (typeof prefix === 'string') {
                keys = keys.map(key => `${prefix}.${key}`)
            }
            keys = keys.map(getLocalStorageItem);
        }
        return keys;
    } catch (e) {
        console.error(e);
        return null;
    }
}
