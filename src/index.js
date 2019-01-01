import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    width: window.innerWidth,
    height: window.innerHeight
  }
});

registerServiceWorker();


// window.addEventListener("beforeunload", function (event) {
//   event.preventDefault();
//   return "Are you sure you want to exit? All progress will be lost.";
// })
