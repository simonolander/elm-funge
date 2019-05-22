module.exports = {
    register: register
};

function register(ports) {
    if (typeof ports.log !== 'undefined') {
        ports.log.subscribe(function (value) {
            console.log(JSON.parse(value));
        });
    }
    if (typeof ports.error !== 'undefined') {
        ports.error.subscribe(function (value) {
            console.error(value);
        });
    }
}
