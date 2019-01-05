import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';
import { PortFunnel } from './js/PortFunnel'

var app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    width: window.innerWidth,
    height: window.innerHeight
  }
});

registerServiceWorker();


// These are the defaults, so you don't need to pass them.
// If you need to use something different, they can be passed
// as the 'portNames' and 'moduleDirectory' properties of
// the second parameter to PortFunnel.subscribe() below.
// var portNames = ['cmdPort', 'subPort'];
// var moduleDirectory = 'js/PortFunnel';
// PortFunnel.subscribe will load js/PortFunnel/<module>.js,
// for each module in this list.
var modules = ['LocalStorage'];
PortFunnel.subscribe(app, { modules: modules });


// window.addEventListener("beforeunload", function (event) {
//   event.preventDefault();
//   return "Are you sure you want to exit? All progress will be lost.";
// })
