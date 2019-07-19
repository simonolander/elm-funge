import './main.css';
import { Elm } from './Main.elm';
// import registerServiceWorker from './js/registerServiceWorker';
import localStoragePorts from './js/local-storage-ports';
import consolePorts from './js/console-ports';

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    width: window.innerWidth,
    height: window.innerHeight,
    accessToken: localStorage.getItem("accessToken"),
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
