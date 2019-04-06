import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './js/registerServiceWorker';
import localStoragePorts from './js/local-storage-ports';

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    width: window.innerWidth,
    height: window.innerHeight
  }
});

registerServiceWorker();

console.log(app)
localStoragePorts.register(app.ports, console.log);
