/* Browserless contract tests for the actual shipped shell JS, not WebGL gameplay. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const htmlPath = process.argv[2];
if (!htmlPath) throw new Error('Pass the actual prepared index.html');
const html = fs.readFileSync(htmlPath, 'utf8');
const configScript = html.match(/<script id="catpat-export-config">([\s\S]*?)<\/script>/)[1];
const shellUrl = html.match(/<script src="([^"]*\/shell\.js)"><\/script>/)[1];
const shell = fs.readFileSync(path.join(path.dirname(htmlPath), shellUrl), 'utf8');
let checks = 0;
function check(condition, label) { assert.ok(condition, label); checks++; console.log('PASS ' + label); }
function target() {
    const listeners = {};
    return {listeners, addEventListener(name, fn) {(listeners[name] ||= []).push(fn);},
        dispatchEvent(evt) {(listeners[evt.type] || []).forEach(fn => fn(evt));},
        fire(name) {this.dispatchEvent({type:name});}};
}
async function flush() { await new Promise(resolve => setImmediate(resolve)); await new Promise(resolve => setImmediate(resolve)); }
async function boot(options = {}) {
    const elements = {};
    const ids = ['canvas','game-viewport','loading-panel','orientation-panel','error-panel','loading-progress','orientation-detail','error-title','error-message','error-technical','retry-button'];
    for (const id of ids) elements[id] = Object.assign(target(), {hidden:false, style:{}, textContent:'', attributes:{}, setAttribute(k,v){this.attributes[k]=v;}});
    const canvas = elements.canvas;
    canvas.width=1280;canvas.height=720;canvas.blurCount=0;canvas.focusCount=0;
    canvas.blur=()=>{canvas.blurCount++;};canvas.focus=()=>{canvas.focusCount++;};
    const pointer = Object.assign(target(), {matches:!!options.coarse});
    const window = Object.assign(target(), {innerWidth:options.width||844,innerHeight:options.height||390,devicePixelRatio:options.dpr||1,location:{reload(){window.reloadCount++;}},reloadCount:0,matchMedia(){return pointer;},visualViewport:target()});
    let blurCount=0;window.addEventListener('blur',()=>blurCount++);
    const insets=options.insets||[0,0,0,0];
    elements['game-viewport'].getBoundingClientRect=()=>({width:window.innerWidth-insets[1]-insets[3],height:window.innerHeight-insets[0]-insets[2]});
    const document=Object.assign(target(),{hidden:false,getElementById(id){return elements[id];}});
    const calls=[];
    class Engine {
        static getMissingFeatures(request){calls.featureRequest=request;return options.missing||[];}
        constructor(config){calls.push({config});this.call=calls[calls.length-1];}
        startGame(callbacks){this.call.callbacks=callbacks;if(options.reject)return Promise.reject(new Error(options.reject));if(options.pending)return new Promise(()=>{});return Promise.resolve();}
    }
    const context=vm.createContext({window,document,console:{error(){}},Event:class {constructor(type){this.type=type;}},Engine:options.noEngine?undefined:Engine});
    vm.runInContext(configScript,context);vm.runInContext(shell,context);await flush();
    return {elements,canvas,window,document,pointer,calls,get blurCount(){return blurCount;},async resize(width,height){window.innerWidth=width;window.innerHeight=height;window.fire('resize');await flush();}};
}
(async()=>{
    let app=await boot({width:720,height:1080});
    check(app.calls.length===1 && app.elements['orientation-panel'].hidden,'keyboard desktop portrait remains usable');
    check(app.calls[0].config.canvasResizePolicy===0 && app.calls[0].config.focusCanvas===false,'shell controls safe canvas sizing without changing engine payload');
    check(app.elements['loading-panel'].hidden && app.elements['error-panel'].hidden,'successful engine Promise hides loading without claiming a device gameplay test');
    app=await boot({coarse:true,width:390,height:844});
    check(app.calls.length===0 && !app.elements['orientation-panel'].hidden && app.canvas.tabIndex===-1 && app.canvas.style.pointerEvents==='none','coarse portrait defers launch and blocks pointer and Tab access behind the rotate card');
    await app.resize(844,390);
    check(app.calls.length===1 && app.elements['orientation-panel'].hidden,'landscape starts the deferred journey once');
    await app.resize(390,844);
    check(app.canvas.blurCount>0 && app.blurCount>0 && !app.elements['orientation-panel'].hidden && app.canvas.style.pointerEvents==='none','rotation releases input and sends focus-out before blocking touches');
    await app.resize(844,390);
    check(app.calls.length===1 && app.canvas.style.pointerEvents==='auto','returning landscape does not restart the game or clear a saved session');
    app=await boot({coarse:true,width:390,height:844,missing:['WebGL2']});
    check(app.calls.length===0 && !app.elements['error-panel'].hidden && app.elements['orientation-panel'].hidden && app.elements['error-technical'].textContent==='WebGL2' && app.elements['error-message'].textContent.includes('WebGL2'),'real missing WebGL2 error stays visible and has priority over portrait instructions');
    await app.resize(844,390);
    check(!app.elements['error-panel'].hidden && app.calls.length===0,'rotation cannot hide an engine feature failure');
    app=await boot({reject:'Failed to fetch hashed.pck'});
    check(!app.elements['error-panel'].hidden && app.elements['error-technical'].textContent==='Failed to fetch hashed.pck','failed startup Promise preserves the actual diagnostic');
    app.elements['retry-button'].fire('click');check(app.window.reloadCount===1,'retry performs one ordinary page reload');
    app=await boot({pending:true});
    app.calls[0].callbacks.onProgress(5,10);check(app.elements['loading-progress'].textContent.includes('%50'),'known download size shows an accurate percentage');
    app.calls[0].callbacks.onProgress(5,0);check(!app.elements['loading-progress'].textContent.includes('%'),'unknown download size never invents a percentage');
    app.calls[0].callbacks.onExit(7);check(!app.elements['error-panel'].hidden && app.elements['error-technical'].textContent.includes('7'),'nonzero engine exit is visible');
    app=await boot({pending:true});app.calls[0].callbacks.onPrintError('SCRIPT ERROR: runtime scene failure');
    check(!app.elements['error-panel'].hidden && app.elements['error-technical'].textContent==='SCRIPT ERROR: runtime scene failure','runtime script failures remain visible even when Godot has not rejected startup');
    app=await boot({width:844,height:390,dpr:3,insets:[0,44,21,44]});
    check(app.canvas.width===1312 && app.canvas.height===738 && app.canvas.style.width==='656px','canvas fits simulated safe-area insets with capped physical resolution');
    const blurBefore=app.blurCount;await app.resize(844,390);check(app.blurCount===blurBefore,'unchanged size does not introduce a pause');
    app.canvas.fire('webglcontextlost');check(!app.elements['error-panel'].hidden && app.elements['error-technical'].textContent==='WebGL context lost','runtime WebGL loss remains an actionable failure');
    app=await boot({noEngine:true});check(!app.elements['error-panel'].hidden && app.calls.length===0,'missing loader script reports a failure instead of a blank canvas');
    console.log(`WEB SHELL CONTRACT: ${checks} checks, 0 failures`);
})().catch(err=>{console.error(err);process.exitCode=1;});
