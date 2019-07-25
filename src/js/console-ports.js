module.exports = {
    register: register
};

function register(ports) {
    if (typeof ports.info !== 'undefined') {
        ports.info.subscribe(function (value) {
            console.info(value);
        });
    }
    if (typeof ports.error !== 'undefined') {
        ports.error.subscribe(function (value) {
            console.error(value);
        });
    }
}
