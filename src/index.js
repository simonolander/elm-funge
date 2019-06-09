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
  }
});

// registerServiceWorker();

localStoragePorts.register(app.ports);
consolePorts.register(app.ports);
