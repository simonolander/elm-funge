import './main.css';
import {Elm} from './Main.elm';
// import registerServiceWorker from './js/registerServiceWorker';
import localStoragePorts from './js/local-storage-ports';
import consolePorts from './js/console-ports';

function expiredAccessToken() {
    localStorage.setItem("accessToken", JSON.stringify({version: 1, accessToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik1UazRSakF5UVVFeFJqUkVRVU0yTkRsRVJEQTNRMFZGUmpNNE9EQkNNMEl6UXpjeU5rSkVPUSJ9.eyJpc3MiOiJodHRwczovL2Rldi0yNTN4emQ0Yy5ldS5hdXRoMC5jb20vIiwic3ViIjoiZ29vZ2xlLW9hdXRoMnwxMDA1MjA3NzIyMTMwNTU5MTAyMjMiLCJhdWQiOlsiaHR0cHM6Ly91cy1jZW50cmFsMS1sdW1pbm91cy1jdWJpc3QtMjM0ODE2LmNsb3VkZnVuY3Rpb25zLm5ldCIsImh0dHBzOi8vZGV2LTI1M3h6ZDRjLmV1LmF1dGgwLmNvbS91c2VyaW5mbyJdLCJpYXQiOjE1NjM2MzMzMDUsImV4cCI6MTU2MzY0MDUwNSwiYXpwIjoiUW5MWXNRNENEYXFjR1ZpQTQzdDkwejZsbzdMNzdKSzYiLCJzY29wZSI6Im9wZW5pZCBwcm9maWxlIHJlYWQ6ZHJhZnRzIHJlYWQ6Ymx1ZXByaW50cyBlZGl0OmRyYWZ0cyBlZGl0OmJsdWVwcmludHMgc3VibWl0OnNvbHV0aW9ucyBwdWJsaXNoOmJsdWVwcmludHMifQ.qqmVdB0TzKsJKefqHIe--LIpivj7hKRW94KJwGxsezNQ2bIZKGdSqnMuf6aH4uWYxzBSc-4kU-b7tTqIhhfED7f5itYABcG9Allut5QgPT9v5iB45WYLngfLtLdcPen6BVxzfGaaUoN0DIHePeBSAqAVnORMvXaD2dSo72x761ZLWg2MPlB8y3q1iZMxdUx_IJAIdRykbPnT8pA9CWYyfXStwDTIUCM_lTtoyuhwauehE0h89RAcGaRRdAQPlWf-RFv7S33sALVsVZTZX-c0i3EbDcx0SPe9K7cKnlcN7uM3Uvww_4AKuZGbZ7B6OAwSqfpAMlg_ESrJQh4SGjA1rA"}))
}

function fakeUserInfo() {
    localStorage.setItem("userInfo", JSON.stringify({sub: "fake-sub"}))
}

const app = Elm.Main.init({
    node: document.getElementById('root'),
    flags: {
        width: window.innerWidth,
        height: window.innerHeight,
        currentTimeMillis: Date.now(),
        localStorageEntries: function () {
            const entries = [];
            for (let i = 0; i < localStorage.length; ++i) {
                const key = localStorage.key(i);
                const value = localStorage.getItem(key);
                entries.push([key, JSON.parse(value)]);
            }
            return entries;
        }(),
    }
});

// registerServiceWorker();

localStoragePorts.register(app.ports);
consolePorts.register(app.ports);


window.localStorageDump = function () {
    var v = {};
    for (var i = 0; i < localStorage.length; ++i) {
        v[localStorage.key(i)] = JSON.parse(localStorage.getItem(localStorage.key(i)));
    }
    return v;
};
