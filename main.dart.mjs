// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `load-ids` option is passed. Each load ID maps to one
  //   or more wasm files as specified in the emitted JSON file. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It also takes a callback that should be invoked with the
  //   loaded module in a format supported by `WebAssembly.compile` or
  //   `WebAssembly.compileStreaming` and the result of using the JS 'import'
  //   API on the js file path. It should return a Promise that resolves when
  //   all the modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports,
      {loadDeferredModules, loadDynamicModule, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _1: (decoder, codeUnits) => decoder.decode(codeUnits),
      _2: () => new TextDecoder("utf-8", {fatal: true}),
      _3: () => new TextDecoder("utf-8", {fatal: false}),
      _4: (s) => +s,
      _5: x0 => new Uint8Array(x0),
      _6: (x0,x1,x2) => x0.set(x1,x2),
      _7: (x0,x1) => x0.transferFromImageBitmap(x1),
      _9: (x0,x1,x2) => x0.slice(x1,x2),
      _10: (x0,x1) => x0.decode(x1),
      _11: (x0,x1) => x0.segment(x1),
      _12: () => new TextDecoder(),
      _13: (x0,x1) => x0.get(x1),
      _14: x0 => x0.buffer,
      _15: x0 => x0.wasmMemory,
      _16: () => globalThis.window._flutter_skwasmInstance,
      _17: x0 => x0.rasterStartMilliseconds,
      _18: x0 => x0.rasterEndMilliseconds,
      _19: x0 => x0.imageBitmaps,
      _135: (x0,x1) => x0.appendChild(x1),
      _166: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _167: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _168: (x0,x1) => new OffscreenCanvas(x0,x1),
      _169: x0 => x0.remove(),
      _170: (x0,x1) => x0.append(x1),
      _172: x0 => x0.unlock(),
      _173: x0 => x0.getReader(),
      _174: (x0,x1) => x0.item(x1),
      _175: x0 => x0.next(),
      _176: x0 => x0.now(),
      _177: (x0,x1) => x0.revokeObjectURL(x1),
      _178: x0 => x0.close(),
      _179: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _180: x0 => new window.ImageDecoder(x0),
      _181: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      _182: (x0,x1) => x0.decode(x1),
      _183: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._183(f,arguments.length,x0) }),
      _184: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _186: (x0,x1) => x0.getModifierState(x1),
      _187: x0 => x0.preventDefault(),
      _188: x0 => x0.stopPropagation(),
      _189: (x0,x1) => x0.removeProperty(x1),
      _190: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._190(f,arguments.length,x0) }),
      _191: x0 => new window.FinalizationRegistry(x0),
      _192: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _194: (x0,x1) => x0.unregister(x1),
      _195: (x0,x1) => x0.prepend(x1),
      _196: x0 => new Intl.Locale(x0),
      _197: (x0,x1) => x0.observe(x1),
      _198: x0 => x0.disconnect(),
      _199: (x0,x1) => x0.getAttribute(x1),
      _200: (x0,x1) => x0.contains(x1),
      _201: (x0,x1) => x0.querySelector(x1),
      _202: (x0,x1) => x0.matchMedia(x1),
      _203: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._203(f,arguments.length,x0) }),
      _204: (x0,x1,x2) => x0.call(x1,x2),
      _205: x0 => x0.blur(),
      _206: x0 => x0.hasFocus(),
      _207: (x0,x1) => x0.removeAttribute(x1),
      _208: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _209: (x0,x1) => x0.hasAttribute(x1),
      _210: (x0,x1) => x0.getModifierState(x1),
      _211: (x0,x1) => x0.createTextNode(x1),
      _212: x0 => x0.getBoundingClientRect(),
      _213: (x0,x1) => x0.replaceWith(x1),
      _214: (x0,x1) => x0.contains(x1),
      _215: (x0,x1) => x0.closest(x1),
      _216: () => new Array(),
      _653: x0 => new Uint8Array(x0),
      _656: () => globalThis.window.flutterConfiguration,
      _658: x0 => x0.assetBase,
      _663: x0 => x0.canvasKitMaximumSurfaces,
      _664: x0 => x0.debugShowSemanticsNodes,
      _665: x0 => x0.hostElement,
      _666: x0 => x0.multiViewEnabled,
      _667: x0 => x0.nonce,
      _669: x0 => x0.fontFallbackBaseUrl,
      _679: x0 => x0.console,
      _680: x0 => x0.devicePixelRatio,
      _681: x0 => x0.document,
      _682: x0 => x0.history,
      _683: x0 => x0.innerHeight,
      _684: x0 => x0.innerWidth,
      _685: x0 => x0.location,
      _686: x0 => x0.navigator,
      _687: x0 => x0.visualViewport,
      _688: x0 => x0.performance,
      _689: x0 => x0.parent,
      _691: x0 => x0.URL,
      _693: (x0,x1) => x0.getComputedStyle(x1),
      _694: x0 => x0.screen,
      _695: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._695(f,arguments.length,x0) }),
      _696: (x0,x1) => x0.requestAnimationFrame(x1),
      _700: (x0,x1) => x0.warn(x1),
      _702: (x0,x1) => x0.debug(x1),
      _703: x0 => globalThis.parseFloat(x0),
      _704: () => globalThis.window,
      _705: () => globalThis.Intl,
      _706: () => globalThis.Symbol,
      _707: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _709: x0 => x0.clipboard,
      _710: x0 => x0.maxTouchPoints,
      _711: x0 => x0.vendor,
      _712: x0 => x0.language,
      _713: x0 => x0.platform,
      _714: x0 => x0.userAgent,
      _715: (x0,x1) => x0.vibrate(x1),
      _716: x0 => x0.languages,
      _717: x0 => x0.documentElement,
      _718: (x0,x1) => x0.querySelector(x1),
      _719: (x0,x1) => x0.querySelectorAll(x1),
      _721: (x0,x1) => x0.createElement(x1),
      _724: (x0,x1) => x0.createEvent(x1),
      _725: x0 => x0.activeElement,
      _728: x0 => x0.head,
      _729: x0 => x0.body,
      _731: (x0,x1) => { x0.title = x1 },
      _734: x0 => x0.visibilityState,
      _735: () => globalThis.document,
      _736: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._736(f,arguments.length,x0) }),
      _737: (x0,x1) => x0.dispatchEvent(x1),
      _745: x0 => x0.target,
      _747: x0 => x0.timeStamp,
      _748: x0 => x0.type,
      _750: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _757: x0 => x0.firstChild,
      _761: x0 => x0.parentElement,
      _763: (x0,x1) => { x0.textContent = x1 },
      _764: x0 => x0.parentNode,
      _765: x0 => x0.nextSibling,
      _766: (x0,x1) => x0.removeChild(x1),
      _767: x0 => x0.isConnected,
      _775: x0 => x0.clientHeight,
      _776: x0 => x0.clientWidth,
      _777: x0 => x0.offsetHeight,
      _778: x0 => x0.offsetWidth,
      _779: x0 => x0.id,
      _780: (x0,x1) => { x0.id = x1 },
      _783: (x0,x1) => { x0.spellcheck = x1 },
      _784: x0 => x0.tagName,
      _785: x0 => x0.style,
      _787: (x0,x1) => x0.querySelectorAll(x1),
      _788: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _789: x0 => x0.tabIndex,
      _790: (x0,x1) => { x0.tabIndex = x1 },
      _791: (x0,x1) => x0.focus(x1),
      _792: x0 => x0.scrollTop,
      _793: (x0,x1) => { x0.scrollTop = x1 },
      _794: (x0,x1) => { x0.scrollLeft = x1 },
      _795: x0 => x0.scrollLeft,
      _796: x0 => x0.classList,
      _797: (x0,x1) => x0.scrollIntoView(x1),
      _800: (x0,x1) => { x0.className = x1 },
      _802: (x0,x1) => x0.getElementsByClassName(x1),
      _803: x0 => x0.click(),
      _804: (x0,x1) => x0.attachShadow(x1),
      _807: x0 => x0.computedStyleMap(),
      _808: (x0,x1) => x0.get(x1),
      _814: (x0,x1) => x0.getPropertyValue(x1),
      _815: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _816: x0 => x0.offsetLeft,
      _817: x0 => x0.offsetTop,
      _818: x0 => x0.offsetParent,
      _820: (x0,x1) => { x0.name = x1 },
      _821: x0 => x0.content,
      _822: (x0,x1) => { x0.content = x1 },
      _826: (x0,x1) => { x0.src = x1 },
      _827: x0 => x0.naturalWidth,
      _828: x0 => x0.naturalHeight,
      _832: (x0,x1) => { x0.crossOrigin = x1 },
      _834: (x0,x1) => { x0.decoding = x1 },
      _835: x0 => x0.decode(),
      _840: (x0,x1) => { x0.nonce = x1 },
      _845: (x0,x1) => { x0.width = x1 },
      _847: (x0,x1) => { x0.height = x1 },
      _850: (x0,x1) => x0.getContext(x1),
      _918: x0 => x0.width,
      _919: x0 => x0.height,
      _921: (x0,x1) => x0.fetch(x1),
      _922: x0 => x0.status,
      _923: x0 => x0.headers,
      _924: x0 => x0.body,
      _925: x0 => x0.arrayBuffer(),
      _927: x0 => x0.text(),
      _928: x0 => x0.read(),
      _929: x0 => x0.value,
      _930: x0 => x0.done,
      _937: x0 => x0.name,
      _938: x0 => x0.x,
      _939: x0 => x0.y,
      _942: x0 => x0.top,
      _943: x0 => x0.right,
      _944: x0 => x0.bottom,
      _945: x0 => x0.left,
      _955: x0 => x0.height,
      _956: x0 => x0.width,
      _957: x0 => x0.scale,
      _958: (x0,x1) => { x0.value = x1 },
      _961: (x0,x1) => { x0.placeholder = x1 },
      _963: (x0,x1) => { x0.name = x1 },
      _964: x0 => x0.selectionDirection,
      _965: x0 => x0.selectionStart,
      _966: x0 => x0.selectionEnd,
      _969: x0 => x0.value,
      _971: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _972: x0 => x0.readText(),
      _973: (x0,x1) => x0.writeText(x1),
      _975: x0 => x0.altKey,
      _976: x0 => x0.code,
      _977: x0 => x0.ctrlKey,
      _978: x0 => x0.key,
      _979: x0 => x0.keyCode,
      _980: x0 => x0.location,
      _981: x0 => x0.metaKey,
      _982: x0 => x0.repeat,
      _983: x0 => x0.shiftKey,
      _984: x0 => x0.isComposing,
      _986: x0 => x0.state,
      _987: (x0,x1) => x0.go(x1),
      _989: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _990: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _991: x0 => x0.pathname,
      _992: x0 => x0.search,
      _993: x0 => x0.hash,
      _997: x0 => x0.state,
      _1000: (x0,x1) => x0.createObjectURL(x1),
      _1002: x0 => new Blob(x0),
      _1012: x0 => x0.matches,
      _1016: x0 => x0.matches,
      _1020: x0 => x0.relatedTarget,
      _1022: x0 => x0.clientX,
      _1023: x0 => x0.clientY,
      _1024: x0 => x0.offsetX,
      _1025: x0 => x0.offsetY,
      _1028: x0 => x0.button,
      _1029: x0 => x0.buttons,
      _1030: x0 => x0.ctrlKey,
      _1034: x0 => x0.pointerId,
      _1035: x0 => x0.pointerType,
      _1036: x0 => x0.pressure,
      _1037: x0 => x0.tiltX,
      _1038: x0 => x0.tiltY,
      _1039: x0 => x0.getCoalescedEvents(),
      _1042: x0 => x0.deltaX,
      _1043: x0 => x0.deltaY,
      _1044: x0 => x0.wheelDeltaX,
      _1045: x0 => x0.wheelDeltaY,
      _1046: x0 => x0.deltaMode,
      _1053: x0 => x0.changedTouches,
      _1056: x0 => x0.clientX,
      _1057: x0 => x0.clientY,
      _1060: x0 => x0.data,
      _1063: (x0,x1) => { x0.disabled = x1 },
      _1065: (x0,x1) => { x0.type = x1 },
      _1066: (x0,x1) => { x0.max = x1 },
      _1067: (x0,x1) => { x0.min = x1 },
      _1068: x0 => x0.value,
      _1069: (x0,x1) => { x0.value = x1 },
      _1070: x0 => x0.disabled,
      _1071: (x0,x1) => { x0.disabled = x1 },
      _1073: (x0,x1) => { x0.placeholder = x1 },
      _1075: (x0,x1) => { x0.name = x1 },
      _1076: (x0,x1) => { x0.autocomplete = x1 },
      _1078: x0 => x0.selectionDirection,
      _1079: x0 => x0.selectionStart,
      _1081: x0 => x0.selectionEnd,
      _1084: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1085: (x0,x1) => x0.add(x1),
      _1087: (x0,x1) => { x0.noValidate = x1 },
      _1088: (x0,x1) => { x0.method = x1 },
      _1089: (x0,x1) => { x0.action = x1 },
      _1114: x0 => x0.orientation,
      _1115: x0 => x0.width,
      _1116: x0 => x0.height,
      _1117: (x0,x1) => x0.lock(x1),
      _1136: x0 => new ResizeObserver(x0),
      _1139: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1139(f,arguments.length,x0,x1) }),
      _1147: x0 => x0.length,
      _1148: x0 => x0.iterator,
      _1149: x0 => x0.Segmenter,
      _1150: x0 => x0.v8BreakIterator,
      _1151: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1154: x0 => x0.language,
      _1155: x0 => x0.script,
      _1156: x0 => x0.region,
      _1174: x0 => x0.done,
      _1175: x0 => x0.value,
      _1176: x0 => x0.index,
      _1180: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1181: (x0,x1) => x0.adoptText(x1),
      _1182: x0 => x0.first(),
      _1183: x0 => x0.next(),
      _1184: x0 => x0.current(),
      _1186: () => globalThis.window.FinalizationRegistry,
      _1197: x0 => x0.hostElement,
      _1198: x0 => x0.viewConstraints,
      _1201: x0 => x0.maxHeight,
      _1202: x0 => x0.maxWidth,
      _1203: x0 => x0.minHeight,
      _1204: x0 => x0.minWidth,
      _1205: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1205(f,arguments.length,x0) }),
      _1206: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1206(f,arguments.length,x0) }),
      _1207: (x0,x1) => ({addView: x0,removeView: x1}),
      _1210: x0 => x0.loader,
      _1211: () => globalThis._flutter,
      _1212: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1213: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1213(f,arguments.length,x0) }),
      _1214: (module,f) => finalizeWrapper(f, function() { return module.exports._1214(f,arguments.length) }),
      _1215: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1218: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1218(f,arguments.length,x0) }),
      _1219: x0 => ({runApp: x0}),
      _1221: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1221(f,arguments.length,x0,x1) }),
      _1222: x0 => new Promise(x0),
      _1223: x0 => x0.length,
      _1224: () => globalThis.window.ImageDecoder,
      _1225: x0 => x0.tracks,
      _1227: x0 => x0.completed,
      _1229: x0 => x0.image,
      _1235: x0 => x0.displayWidth,
      _1236: x0 => x0.displayHeight,
      _1237: x0 => x0.duration,
      _1240: x0 => x0.ready,
      _1241: x0 => x0.selectedTrack,
      _1242: x0 => x0.repetitionCount,
      _1243: x0 => x0.frameCount,
      _1292: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _1293: x0 => x0.preventDefault(),
      _1295: (x0,x1) => ({type: x0,callback: x1}),
      _1299: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1300: x0 => x0.type,
      _1301: x0 => x0.callback,
      _1305: x0 => x0.arrayBuffer(),
      _1306: x0 => x0.getAsFile(),
      _1307: x0 => x0.webkitGetAsEntry(),
      _1308: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1308(f,arguments.length,x0) }),
      _1309: (x0,x1) => x0.getAsString(x1),
      _1310: x0 => x0.slice(),
      _1311: x0 => x0.cancel(),
      _1312: x0 => x0.stream(),
      _1313: x0 => new ReadableStreamDefaultReader(x0),
      _1314: x0 => x0.read(),
      _1317: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1317(f,arguments.length,x0) }),
      _1318: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1318(f,arguments.length,x0) }),
      _1319: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1319(f,arguments.length,x0) }),
      _1320: x0 => ({type: x0}),
      _1321: (x0,x1) => new Blob(x0,x1),
      _1324: x0 => ({audio: x0}),
      _1325: (x0,x1) => x0.getUserMedia(x1),
      _1326: x0 => x0.getAudioTracks(),
      _1327: x0 => x0.stop(),
      _1328: (x0,x1) => x0.removeTrack(x1),
      _1329: x0 => x0.close(),
      _1330: (x0,x1) => x0.warn(x1),
      _1331: x0 => x0.getSettings(),
      _1332: x0 => ({sampleRate: x0}),
      _1333: x0 => new AudioContext(x0),
      _1334: () => new AudioContext(),
      _1337: (x0,x1) => x0.connect(x1),
      _1338: x0 => globalThis.URL.createObjectURL(x0),
      _1339: (x0,x1) => x0.createMediaStreamSource(x1),
      _1340: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1340(f,arguments.length,x0) }),
      _1341: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1341(f,arguments.length,x0) }),
      _1342: (x0,x1) => x0.addModule(x1),
      _1343: x0 => ({parameterData: x0}),
      _1344: (x0,x1,x2) => new AudioWorkletNode(x0,x1,x2),
      _1345: x0 => ({name: x0}),
      _1346: (x0,x1) => x0.query(x1),
      _1347: x0 => x0.enumerateDevices(),
      _1353: x0 => x0.disconnect(),
      _1354: x0 => x0.stop(),
      _1355: (x0,x1,x2) => ({mimeType: x0,audioBitsPerSecond: x1,bitsPerSecond: x2}),
      _1356: (x0,x1) => new MediaRecorder(x0,x1),
      _1357: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1357(f,arguments.length,x0) }),
      _1358: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1358(f,arguments.length,x0) }),
      _1359: (x0,x1) => x0.start(x1),
      _1360: x0 => x0.createAnalyser(),
      _1361: (x0,x1) => x0.getFloatTimeDomainData(x1),
      _1362: x0 => globalThis.MediaRecorder.isTypeSupported(x0),
      _1363: x0 => x0.remove(),
      _1364: (x0,x1,x2,x3) => x0.drawImage(x1,x2,x3),
      _1368: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1368(f,arguments.length,x0) }),
      _1369: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1369(f,arguments.length,x0) }),
      _1370: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1370(f,arguments.length,x0) }),
      _1371: (x0,x1) => x0.querySelector(x1),
      _1372: (x0,x1) => x0.createElement(x1),
      _1373: (x0,x1) => x0.append(x1),
      _1374: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1375: (x0,x1) => x0.replaceChildren(x1),
      _1376: x0 => x0.click(),
      _1377: (x0,x1) => x0.canShare(x1),
      _1378: (x0,x1) => x0.share(x1),
      _1381: (x0,x1) => ({files: x0,text: x1}),
      _1383: x0 => ({files: x0}),
      _1385: x0 => ({text: x0}),
      _1386: () => ({}),
      _1387: (x0,x1,x2) => new File(x0,x1,x2),
      _1388: () => new MediaStream(),
      _1389: x0 => x0.getVideoTracks(),
      _1390: (x0,x1) => x0.addTrack(x1),
      _1391: (x0,x1) => x0.getElementById(x1),
      _1392: (x0,x1) => x0.removeAttribute(x1),
      _1393: x0 => x0.load(),
      _1394: x0 => x0.hasChildNodes(),
      _1395: (x0,x1) => x0.appendChild(x1),
      _1396: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1396(f,arguments.length,x0,x1) }),
      _1397: (x0,x1) => x0.requestVideoFrameCallback(x1),
      _1398: (x0,x1,x2,x3) => x0.call(x1,x2,x3),
      _1399: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1399(f,arguments.length,x0) }),
      _1400: (x0,x1) => x0.requestAnimationFrame(x1),
      _1401: (x0,x1) => x0.cancelVideoFrameCallback(x1),
      _1402: (x0,x1) => x0.cancelAnimationFrame(x1),
      _1403: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1403(f,arguments.length,x0) }),
      _1404: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1404(f,arguments.length,x0) }),
      _1405: x0 => x0.getCapabilities(),
      _1406: () => ({}),
      _1407: (x0,x1) => x0.applyConstraints(x1),
      _1408: x0 => x0.getSupportedConstraints(),
      _1409: x0 => ({ideal: x0}),
      _1410: (x0,x1,x2) => ({width: x0,height: x1,deviceId: x2}),
      _1411: x0 => ({video: x0}),
      _1412: (x0,x1) => ({width: x0,height: x1}),
      _1413: (x0,x1,x2) => ({width: x0,height: x1,facingMode: x2}),
      _1414: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1414(f,arguments.length,x0) }),
      _1415: (x0,x1) => x0.removeChild(x1),
      _1416: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1416(f,arguments.length,x0) }),
      _1417: x0 => x0.pause(),
      _1418: x0 => x0.play(),
      _1419: x0 => ({willReadFrequently: x0}),
      _1420: (x0,x1,x2) => x0.getContext(x1,x2),
      _1421: (x0,x1,x2,x3,x4) => x0.getImageData(x1,x2,x3,x4),
      _1422: (x0,x1,x2) => x0.readBarcodes(x1,x2),
      _1423: (x0,x1,x2,x3) => ({formats: x0,tryHarder: x1,tryRotate: x2,tryInvert: x3}),
      _1424: (x0,x1,x2) => ({tryHarder: x0,tryRotate: x1,tryInvert: x2}),
      _1425: (x0,x1) => x0.detect(x1),
      _1426: () => new BarcodeDetector(),
      _1427: x0 => ({formats: x0}),
      _1428: x0 => new BarcodeDetector(x0),
      _1429: () => new Map(),
      _1430: (x0,x1,x2) => x0.set(x1,x2),
      _1431: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1431(f,arguments.length,x0,x1) }),
      _1432: (x0,x1) => x0.call(x1),
      _1433: (x0,x1) => new ZXing.BrowserMultiFormatReader(x0,x1),
      _1434: () => globalThis.window.navigator.userAgent,
      _1440: (x0,x1) => x0.createElement(x1),
      _1446: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1448: (x0,x1) => x0.start(x1),
      _1449: (x0,x1) => x0.end(x1),
      _1450: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1451: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _1456: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1457: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1457(f,arguments.length,x0) }),
      _1458: (x0,x1) => x0.readEntries(x1),
      _1459: x0 => x0.createReader(),
      _1460: () => new Blob(),
      _1461: (x0,x1,x2,x3) => x0.slice(x1,x2,x3),
      _1462: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1462(f,arguments.length,x0) }),
      _1463: (x0,x1) => x0.file(x1),
      _1464: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1464(f,arguments.length,x0) }),
      _1465: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1465(f,arguments.length,x0) }),
      _1466: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1466(f,arguments.length,x0) }),
      _1467: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1467(f,arguments.length,x0) }),
      _1469: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1469(f,arguments.length,x0) }),
      _1470: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1470(f,arguments.length,x0) }),
      _1471: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1471(f,arguments.length,x0) }),
      _1472: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1472(f,arguments.length,x0) }),
      _1473: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1473(f,arguments.length,x0) }),
      _1474: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1474(f,arguments.length,x0) }),
      _1475: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1475(f,arguments.length,x0) }),
      _1476: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1476(f,arguments.length,x0) }),
      _1477: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1477(f,arguments.length,x0) }),
      _1478: (x0,x1) => x0.setSinkId(x1),
      _1479: x0 => x0.decode(),
      _1480: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1481: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1482: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1482(f,arguments.length,x0) }),
      _1483: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1483(f,arguments.length,x0) }),
      _1484: x0 => x0.send(),
      _1485: () => new XMLHttpRequest(),
      _1487: (x0,x1) => x0.getItem(x1),
      _1488: (x0,x1) => x0.removeItem(x1),
      _1489: (x0,x1,x2) => x0.setItem(x1,x2),
      _1490: (x0,x1) => x0.item(x1),
      _1491: () => new FileReader(),
      _1492: (x0,x1) => x0.readAsDataURL(x1),
      _1493: (x0,x1) => x0.readAsArrayBuffer(x1),
      _1494: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1494(f,arguments.length,x0) }),
      _1495: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1495(f,arguments.length,x0) }),
      _1496: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1496(f,arguments.length,x0) }),
      _1497: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1497(f,arguments.length,x0) }),
      _1504: () => globalThis.ZXingWASM,
      _1505: x0 => x0.text,
      _1506: x0 => x0.format,
      _1507: x0 => x0.bytes,
      _1508: x0 => x0.position,
      _1509: x0 => x0.isValid,
      _1510: x0 => x0.topLeft,
      _1511: x0 => x0.topRight,
      _1512: x0 => x0.bottomRight,
      _1513: x0 => x0.bottomLeft,
      _1514: x0 => x0.x,
      _1515: x0 => x0.y,
      _1516: x0 => x0.barcodeFormat,
      _1517: x0 => x0.text,
      _1518: x0 => x0.rawBytes,
      _1519: x0 => x0.resultPoints,
      _1521: Date.now,
      _1523: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1524: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1525: () => typeof dartUseDateNowForTicks !== "undefined",
      _1526: () => 1000 * performance.now(),
      _1527: () => Date.now(),
      _1528: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1529: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1530: () => new WeakMap(),
      _1531: (map, o) => map.get(o),
      _1532: (map, o, v) => map.set(o, v),
      _1533: x0 => new WeakRef(x0),
      _1534: x0 => x0.deref(),
      _1541: () => globalThis.WeakRef,
      _1545: s => JSON.stringify(s),
      _1546: s => printToConsole(s),
      _1547: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      _1548: (o, p, r) => o.replaceAll(p, () => r),
      _1549: (o, p, r) => o.replace(p, () => r),
      _1550: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1551: s => s.toUpperCase(),
      _1552: s => s.trim(),
      _1553: s => s.trimLeft(),
      _1554: s => s.trimRight(),
      _1555: (string, times) => string.repeat(times),
      _1556: Function.prototype.call.bind(String.prototype.indexOf),
      _1557: (s, p, i) => s.lastIndexOf(p, i),
      _1558: (string, token) => string.split(token),
      _1559: Object.is,
      _1563: (o, t) => typeof o === t,
      _1564: (o, c) => o instanceof c,
      _1565: o => Object.keys(o),
      _1568: (o,s,v) => o[s] = v,
      _1569: (o, a) => o + a,
      _1618: x0 => new Array(x0),
      _1620: x0 => x0.length,
      _1622: (x0,x1) => x0[x1],
      _1623: (x0,x1,x2) => { x0[x1] = x2 },
      _1626: (x0,x1,x2) => new DataView(x0,x1,x2),
      _1628: x0 => new Int8Array(x0),
      _1629: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _1631: x0 => new Uint8ClampedArray(x0),
      _1633: x0 => new Int16Array(x0),
      _1635: x0 => new Uint16Array(x0),
      _1637: x0 => new Int32Array(x0),
      _1639: x0 => new Uint32Array(x0),
      _1641: x0 => new Float32Array(x0),
      _1643: x0 => new Float64Array(x0),
      _1666: () => Symbol("jsBoxedDartObjectProperty"),
      _1667: x0 => x0.random(),
      _1668: (x0,x1) => x0.getRandomValues(x1),
      _1669: () => globalThis.crypto,
      _1670: () => globalThis.Math,
      _1683: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _1684: (handle) => clearTimeout(handle),
      _1685: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _1686: (handle) => clearInterval(handle),
      _1687: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _1688: () => Date.now(),
      _1689: () => new Error().stack,
      _1690: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1691: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _1692: (x0,x1) => x0.exec(x1),
      _1693: (x0,x1) => x0.test(x1),
      _1694: x0 => x0.pop(),
      _1696: o => o === undefined,
      _1698: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _1700: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _1701: o => o instanceof RegExp,
      _1702: (l, r) => l === r,
      _1703: o => o,
      _1704: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      _1705: o => o,
      _1706: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      _1707: o => o,
      _1708: b => !!b,
      _1709: o => o.length,
      _1711: (o, i) => o[i],
      _1712: f => f.dartFunction,
      _1713: () => ({}),
      _1714: () => [],
      _1716: () => globalThis,
      _1717: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _1718: (o, p) => p in o,
      _1719: (o, p) => o[p],
      _1720: (o, p, v) => o[p] = v,
      _1721: (o, m, a) => o[m].apply(o, a),
      _1723: o => String(o),
      _1724: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _1725: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1725(f,arguments.length,x0) }),
      _1726: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1726(f,arguments.length,x0,x1) }),
      _1727: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _1728: o => [o],
      _1729: (o0, o1) => [o0, o1],
      _1730: (o0, o1, o2) => [o0, o1, o2],
      _1731: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _1732: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      _1733: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1734: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1735: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1736: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1737: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1738: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1739: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1740: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1741: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1742: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1743: x0 => new ArrayBuffer(x0),
      _1744: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _1745: x0 => x0.input,
      _1746: x0 => x0.index,
      _1747: x0 => x0.groups,
      _1748: x0 => x0.flags,
      _1749: x0 => x0.multiline,
      _1750: x0 => x0.ignoreCase,
      _1751: x0 => x0.unicode,
      _1752: x0 => x0.dotAll,
      _1753: (x0,x1) => { x0.lastIndex = x1 },
      _1754: (o, p) => p in o,
      _1755: (o, p) => o[p],
      _1756: (o, p, v) => o[p] = v,
      _1759: (x0,x1) => x0.replaceTrack(x1),
      _1766: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1766(f,arguments.length,x0) }),
      _1767: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1767(f,arguments.length,x0) }),
      _1768: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1768(f,arguments.length,x0) }),
      _1769: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1769(f,arguments.length,x0) }),
      _1770: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1770(f,arguments.length,x0) }),
      _1771: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1771(f,arguments.length,x0) }),
      _1772: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1772(f,arguments.length,x0) }),
      _1773: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1773(f,arguments.length,x0) }),
      _1774: x0 => x0.close(),
      _1776: (x0,x1) => x0.createOffer(x1),
      _1777: (x0,x1) => x0.createAnswer(x1),
      _1780: (x0,x1) => ({type: x0,sdp: x1}),
      _1781: (x0,x1) => x0.setLocalDescription(x1),
      _1782: (x0,x1) => ({type: x0,sdp: x1}),
      _1783: (x0,x1) => x0.setRemoteDescription(x1),
      _1784: (x0,x1,x2) => ({candidate: x0,sdpMid: x1,sdpMLineIndex: x2}),
      _1785: (x0,x1) => x0.addIceCandidate(x1),
      _1791: (x0,x1,x2,x3) => ({ordered: x0,protocol: x1,negotiated: x2,id: x3}),
      _1792: (x0,x1,x2) => x0.createDataChannel(x1,x2),
      _1795: (x0,x1,x2) => x0.addTrack(x1,x2),
      _1797: x0 => x0.getSenders(),
      _1802: (x0,x1) => { x0.binaryType = x1 },
      _1805: x0 => new RTCPeerConnection(x0),
      _1818: (x0,x1) => ({video: x0,audio: x1}),
      _1825: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1825(f,arguments.length,x0) }),
      _1826: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1826(f,arguments.length,x0) }),
      _1827: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1827(f,arguments.length,x0) }),
      _1838: () => new XMLHttpRequest(),
      _1839: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1843: x0 => x0.send(),
      _1845: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1845(f,arguments.length,x0) }),
      _1846: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1846(f,arguments.length,x0) }),
      _1851: (x0,x1) => new WebSocket(x0,x1),
      _1852: (x0,x1) => x0.send(x1),
      _1853: (x0,x1,x2) => x0.close(x1,x2),
      _1855: x0 => x0.close(),
      _1857: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1857(f,arguments.length,x0) }),
      _1858: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1858(f,arguments.length,x0) }),
      _1859: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1859(f,arguments.length,x0) }),
      _1860: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1860(f,arguments.length,x0) }),
      _1861: (x0,x1) => x0.send(x1),
      _1862: x0 => x0.close(),
      _1864: () => new AbortController(),
      _1865: x0 => x0.abort(),
      _1866: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _1867: (x0,x1) => globalThis.fetch(x0,x1),
      _1868: (x0,x1) => x0.get(x1),
      _1869: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1869(f,arguments.length,x0,x1,x2) }),
      _1870: (x0,x1) => x0.forEach(x1),
      _1871: x0 => x0.getReader(),
      _1875: x0 => x0.attachStreamToVideo,
      _1877: x0 => x0.decodeContinuously,
      _1881: x0 => x0.reset,
      _1883: x0 => x0.stopContinuousDecode,
      _1885: x0 => x0.stream,
      _1886: x0 => x0.videoElement,
      _1887: () => globalThis.BarcodeDetector.getSupportedFormats(),
      _1888: x0 => x0.rawValue,
      _1889: x0 => x0.format,
      _1890: x0 => x0.cornerPoints,
      _1891: x0 => x0.x,
      _1892: x0 => x0.y,
      _1911: (x0,x1) => x0.key(x1),
      _1912: x0 => x0.mediaDevices,
      _1914: x0 => x0.facingMode,
      _1915: x0 => x0.deviceId,
      _1916: (x0,x1) => ({width: x0,height: x1}),
      _1917: (x0,x1,x2) => ({width: x0,height: x1,facingMode: x2}),
      _1918: o => o instanceof Array,
      _1919: (a, i) => a.splice(i, 1)[0],
      _1921: (a, l) => a.length = l,
      _1922: a => a.pop(),
      _1923: (a, i) => a.splice(i, 1),
      _1924: (a, s) => a.join(s),
      _1925: (a, s, e) => a.slice(s, e),
      _1927: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _1928: a => a.length,
      _1929: (a, l) => a.length = l,
      _1930: (a, i) => a[i],
      _1931: (a, i, v) => a[i] = v,
      _1933: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      _1934: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _1936: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      _1937: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _1938: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      _1939: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _1940: o => o instanceof Uint8ClampedArray,
      _1941: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _1942: o => o instanceof Uint16Array,
      _1943: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _1944: o => o instanceof Int16Array,
      _1945: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _1946: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      _1947: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _1948: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      _1949: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _1951: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _1952: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      _1953: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _1954: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      _1955: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _1956: (a, i) => a.push(i),
      _1957: (t, s) => t.set(s),
      _1958: l => new DataView(new ArrayBuffer(l)),
      _1959: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _1960: o => o.byteLength,
      _1961: o => o.buffer,
      _1962: o => o.byteOffset,
      _1963: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _1964: (b, o) => new DataView(b, o),
      _1965: (b, o, l) => new DataView(b, o, l),
      _1966: Function.prototype.call.bind(DataView.prototype.getUint8),
      _1967: Function.prototype.call.bind(DataView.prototype.setUint8),
      _1968: Function.prototype.call.bind(DataView.prototype.getInt8),
      _1969: Function.prototype.call.bind(DataView.prototype.setInt8),
      _1970: Function.prototype.call.bind(DataView.prototype.getUint16),
      _1971: Function.prototype.call.bind(DataView.prototype.setUint16),
      _1972: Function.prototype.call.bind(DataView.prototype.getInt16),
      _1973: Function.prototype.call.bind(DataView.prototype.setInt16),
      _1974: Function.prototype.call.bind(DataView.prototype.getUint32),
      _1975: Function.prototype.call.bind(DataView.prototype.setUint32),
      _1976: Function.prototype.call.bind(DataView.prototype.getInt32),
      _1977: Function.prototype.call.bind(DataView.prototype.setInt32),
      _1980: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _1981: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _1982: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _1983: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _1984: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _1985: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _1986: Function.prototype.call.bind(Number.prototype.toString),
      _1987: Function.prototype.call.bind(BigInt.prototype.toString),
      _1988: Function.prototype.call.bind(Number.prototype.toString),
      _1989: (d, digits) => d.toFixed(digits),
      _2009: () => globalThis.document,
      _2011: () => globalThis.console,
      _2016: (x0,x1) => { x0.height = x1 },
      _2018: (x0,x1) => { x0.width = x1 },
      _2020: (x0,x1) => { x0.pointerEvents = x1 },
      _2029: x0 => x0.style,
      _2032: x0 => x0.src,
      _2033: (x0,x1) => { x0.src = x1 },
      _2034: x0 => x0.naturalWidth,
      _2035: x0 => x0.naturalHeight,
      _2050: (x0,x1) => x0.error(x1),
      _2055: x0 => x0.status,
      _2056: (x0,x1) => { x0.responseType = x1 },
      _2058: x0 => x0.response,
      _2059: x0 => x0.x,
      _2060: x0 => x0.y,
      _2109: (x0,x1) => { x0.responseType = x1 },
      _2110: x0 => x0.response,
      _2157: (x0,x1) => { x0.lang = x1 },
      _2170: (x0,x1) => { x0.draggable = x1 },
      _2186: x0 => x0.style,
      _2199: (x0,x1) => { x0.oncancel = x1 },
      _2205: (x0,x1) => { x0.onchange = x1 },
      _2245: (x0,x1) => { x0.onerror = x1 },
      _2261: (x0,x1) => { x0.onload = x1 },
      _2285: (x0,x1) => { x0.onpause = x1 },
      _2287: (x0,x1) => { x0.onplay = x1 },
      _2545: (x0,x1) => { x0.download = x1 },
      _2570: (x0,x1) => { x0.href = x1 },
      _2755: (x0,x1) => { x0.width = x1 },
      _2757: (x0,x1) => { x0.height = x1 },
      _2758: x0 => x0.videoWidth,
      _2759: x0 => x0.videoHeight,
      _2763: (x0,x1) => { x0.playsInline = x1 },
      _2788: x0 => x0.error,
      _2789: x0 => x0.src,
      _2790: (x0,x1) => { x0.src = x1 },
      _2792: (x0,x1) => { x0.srcObject = x1 },
      _2798: (x0,x1) => { x0.preload = x1 },
      _2799: x0 => x0.buffered,
      _2800: x0 => x0.readyState,
      _2802: x0 => x0.currentTime,
      _2803: (x0,x1) => { x0.currentTime = x1 },
      _2804: x0 => x0.duration,
      _2805: x0 => x0.paused,
      _2809: (x0,x1) => { x0.playbackRate = x1 },
      _2816: (x0,x1) => { x0.autoplay = x1 },
      _2818: (x0,x1) => { x0.loop = x1 },
      _2820: (x0,x1) => { x0.controls = x1 },
      _2822: (x0,x1) => { x0.volume = x1 },
      _2824: (x0,x1) => { x0.muted = x1 },
      _2839: x0 => x0.code,
      _2840: x0 => x0.message,
      _2913: x0 => x0.length,
      _3109: (x0,x1) => { x0.accept = x1 },
      _3123: x0 => x0.files,
      _3149: (x0,x1) => { x0.multiple = x1 },
      _3167: (x0,x1) => { x0.type = x1 },
      _3417: (x0,x1) => { x0.src = x1 },
      _3419: (x0,x1) => { x0.type = x1 },
      _3423: (x0,x1) => { x0.async = x1 },
      _3425: (x0,x1) => { x0.defer = x1 },
      _3427: (x0,x1) => { x0.crossOrigin = x1 },
      _3461: x0 => x0.width,
      _3462: (x0,x1) => { x0.width = x1 },
      _3463: x0 => x0.height,
      _3464: (x0,x1) => { x0.height = x1 },
      _3865: x0 => x0.items,
      _3866: x0 => x0.types,
      _3868: (x0,x1) => x0[x1],
      _3872: x0 => x0.length,
      _3873: x0 => x0.kind,
      _3874: x0 => x0.type,
      _3876: x0 => x0.dataTransfer,
      _3880: () => globalThis.window,
      _3918: x0 => x0.document,
      _3940: x0 => x0.navigator,
      _4011: (x0,x1) => { x0.ondragenter = x1 },
      _4013: (x0,x1) => { x0.ondragleave = x1 },
      _4015: (x0,x1) => { x0.ondragover = x1 },
      _4019: (x0,x1) => { x0.ondrop = x1 },
      _4204: x0 => x0.localStorage,
      _4310: x0 => x0.mediaDevices,
      _4312: x0 => x0.permissions,
      _4326: x0 => x0.userAgent,
      _4327: x0 => x0.vendor,
      _4376: x0 => x0.data,
      _4413: (x0,x1) => { x0.onmessage = x1 },
      _4532: x0 => x0.length,
      _4749: x0 => x0.readyState,
      _4758: x0 => x0.protocol,
      _4762: (x0,x1) => { x0.binaryType = x1 },
      _4765: x0 => x0.code,
      _4766: x0 => x0.reason,
      _4818: x0 => x0.signalingState,
      _4819: x0 => x0.iceGatheringState,
      _4820: x0 => x0.iceConnectionState,
      _4821: x0 => x0.connectionState,
      _4834: (x0,x1) => { x0.onicegatheringstatechange = x1 },
      _4848: x0 => x0.type,
      _4850: x0 => x0.sdp,
      _4858: x0 => x0.candidate,
      _4859: x0 => x0.sdpMid,
      _4860: x0 => x0.sdpMLineIndex,
      _4882: x0 => x0.candidate,
      _4918: x0 => x0.track,
      _5051: x0 => x0.receiver,
      _5052: x0 => x0.track,
      _5053: x0 => x0.streams,
      _5054: x0 => x0.transceiver,
      _5070: x0 => x0.label,
      _5076: x0 => x0.id,
      _5082: (x0,x1) => { x0.onopen = x1 },
      _5084: (x0,x1) => { x0.onbufferedamountlow = x1 },
      _5090: (x0,x1) => { x0.onclose = x1 },
      _5092: (x0,x1) => { x0.onmessage = x1 },
      _5099: (x0,x1) => { x0.maxPacketLifeTime = x1 },
      _5101: (x0,x1) => { x0.maxRetransmits = x1 },
      _5111: x0 => x0.channel,
      _5893: x0 => x0.destination,
      _5894: x0 => x0.sampleRate,
      _5897: x0 => x0.state,
      _5898: x0 => x0.audioWorklet,
      _6000: x0 => x0.fftSize,
      _6001: (x0,x1) => { x0.fftSize = x1 },
      _6008: (x0,x1) => { x0.smoothingTimeConstant = x1 },
      _6262: x0 => x0.port,
      _6401: x0 => x0.type,
      _6402: x0 => x0.target,
      _6442: x0 => x0.signal,
      _6496: x0 => x0.baseURI,
      _6502: x0 => x0.firstChild,
      _6513: () => globalThis.document,
      _6594: x0 => x0.body,
      _6596: x0 => x0.head,
      _6925: (x0,x1) => { x0.id = x1 },
      _6952: x0 => x0.children,
      _7258: x0 => x0.clientX,
      _7259: x0 => x0.clientY,
      _8270: x0 => x0.value,
      _8272: x0 => x0.done,
      _8449: x0 => x0.size,
      _8450: x0 => x0.type,
      _8453: (x0,x1) => { x0.type = x1 },
      _8456: x0 => x0.name,
      _8457: x0 => x0.lastModified,
      _8462: x0 => x0.length,
      _8467: x0 => x0.result,
      _8834: x0 => x0.mimeType,
      _8835: x0 => x0.state,
      _8839: (x0,x1) => { x0.onstop = x1 },
      _8841: (x0,x1) => { x0.ondataavailable = x1 },
      _8866: x0 => x0.data,
      _8956: x0 => x0.url,
      _8958: x0 => x0.status,
      _8960: x0 => x0.statusText,
      _8961: x0 => x0.headers,
      _8962: x0 => x0.body,
      _9033: x0 => x0.clipboardData,
      _9347: x0 => x0.state,
      _9744: x0 => x0.id,
      _9750: x0 => x0.kind,
      _9751: x0 => x0.id,
      _9752: x0 => x0.label,
      _9753: x0 => x0.enabled,
      _9754: (x0,x1) => { x0.enabled = x1 },
      _9755: x0 => x0.muted,
      _9774: x0 => x0.facingMode,
      _9871: x0 => x0.whiteBalanceMode,
      _9873: x0 => x0.exposureMode,
      _9875: x0 => x0.focusMode,
      _9944: (x0,x1) => { x0.whiteBalanceMode = x1 },
      _9946: (x0,x1) => { x0.exposureMode = x1 },
      _9948: (x0,x1) => { x0.focusMode = x1 },
      _9988: x0 => x0.width,
      _9990: x0 => x0.height,
      _9996: x0 => x0.facingMode,
      _10000: x0 => x0.sampleRate,
      _10012: x0 => x0.channelCount,
      _10072: x0 => x0.deviceId,
      _10073: x0 => x0.kind,
      _11072: (x0,x1) => { x0.border = x1 },
      _11350: (x0,x1) => { x0.display = x1 },
      _11514: (x0,x1) => { x0.height = x1 },
      _11570: (x0,x1) => { x0.left = x1 },
      _11708: (x0,x1) => { x0.objectFit = x1 },
      _11726: (x0,x1) => { x0.opacity = x1 },
      _11838: (x0,x1) => { x0.pointerEvents = x1 },
      _11840: (x0,x1) => { x0.position = x1 },
      _12132: (x0,x1) => { x0.top = x1 },
      _12136: (x0,x1) => { x0.transform = x1 },
      _12140: (x0,x1) => { x0.transformOrigin = x1 },
      _12204: (x0,x1) => { x0.width = x1 },
      _12572: x0 => x0.name,
      _12573: x0 => x0.message,
      _13257: x0 => x0.isDirectory,
      _13258: x0 => x0.name,
      _13259: x0 => x0.fullPath,
      _13289: () => globalThis.console,
      _13317: x0 => x0.message,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });
    dartInstance.exports.$setThisModule(dartInstance);

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
