// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import '../css/app.scss';

// Phoenix LiveView polyfills
import 'mdn-polyfills/Object.assign';
import 'mdn-polyfills/CustomEvent';
import 'mdn-polyfills/String.prototype.startsWith';
import 'mdn-polyfills/Array.from';
import 'mdn-polyfills/Array.prototype.find';
import 'mdn-polyfills/Array.prototype.some';
import 'mdn-polyfills/NodeList.prototype.forEach';
import 'mdn-polyfills/Element.prototype.closest';
import 'mdn-polyfills/Element.prototype.matches';
import 'mdn-polyfills/Node.prototype.remove';
import 'child-replace-with-polyfill';
import 'url-search-params-polyfill';
import 'formdata-polyfill';
import 'classlist-polyfill';
import '@webcomponents/template';
import 'shim-keyboard-event-key';
import 'core-js/features/set';

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import 'phoenix_html';
import { Socket } from 'phoenix';
import topbar from 'topbar';
import { LiveSocket } from 'phoenix_live_view';

let Hooks = {};
Hooks.ProgressBar = {
  mounted() {
    // Adapted from: https://dev.to/mushfiqweb/create-a-custom-progress-bar-using-html5-433m
    let progressbar = this.el;
    let max = progressbar.max;
    let time = (1000 / max) * 10;
    let value = progressbar.value;
    const loading = () => {
      value += 1;
      progressbar.value = value;

      if (value == max) {
        clearInterval(animate);
        progressbar.value = 0;
        value = 0;
        animate = setInterval(() => loading(), time);
      }
    };
    let animate = setInterval(() => loading(), time);

    // a reference so that the timer can be cancelld when the progress bar leaves the page:
    window.animateRef = animate;
  },

  beforeDestroy() {
    if (window.animateRef) {
      clearInterval(window.animateRef);
    }
  }
};

Hooks.CopyButton = {
  mounted() {
    this.el.addEventListener('click', window.copyToClipboard);
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');
let liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken }
});

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

window.copyToClipboard = function() {
  var copyData = this.dataset['copydata'];

  // From: https://www.30secondsofcode.org/blog/s/copy-text-to-clipboard-with-javascript
  const el = document.createElement('textarea');
  el.value = copyData;
  document.body.appendChild(el);
  el.select();
  el.setSelectionRange(0, 99999); // For mobile - see https://www.w3schools.com/howto/howto_js_copy_clipboard.asp
  document.execCommand('copy');
  document.body.removeChild(el);

  alert('Copied to clipboard');
};
