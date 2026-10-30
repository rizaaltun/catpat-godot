#!/usr/bin/env python3
"""Original deterministic Catpat procedural compositions and sound design.
No external samples. Re-running produces source WAVs in a temporary directory and
Vorbis runtime loops / PCM16 effects plus a provenance and level manifest.
"""
from __future__ import annotations
import hashlib, json, math, subprocess, tempfile, wave
from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/runtime/audio'
SR=24000
RNG=np.random.default_rng(1052026)

def hz(midi): return 440*2**((midi-69)/12)
def tvec(seconds): return np.arange(round(SR*seconds))/SR

def pluck(midi, seconds=.9, brightness=.6):
    t=tvec(seconds); f=hz(midi); x=np.zeros_like(t)
    for harmonic, amplitude in [(1,1),(2,.30*brightness),(3,.16*brightness),(4,.06*brightness)]:
        x+=amplitude*np.sin(2*np.pi*f*harmonic*t)*np.exp(-t*(2.8+harmonic*1.6))
    x+=RNG.normal(0,1,len(t))*.025*np.exp(-t*90)
    return x*(1-np.exp(-t*900))*.45

def bell(midi, seconds=1.7):
    t=tvec(seconds); f=hz(midi); x=np.zeros_like(t)
    for ratio,amp,decay in [(1,1,3),(2.76,.23,6),(4.08,.08,8)]:
        x+=amp*np.sin(2*np.pi*f*ratio*t)*np.exp(-t*decay)
    return x*(1-np.exp(-t*1200))*.35

def flute(midi, seconds=.65):
    t=tvec(seconds); f=hz(midi)
    env=np.minimum(t/.055,1)*np.minimum((seconds-t)/.16,1)
    env=np.maximum(env,0)
    phase=2*np.pi*f*t+.012*np.sin(2*np.pi*4.8*t)
    return (.85*np.sin(phase)+.12*np.sin(2*phase)+.035*RNG.normal(size=len(t)))*env*.25

def sweep(f0,f1,seconds,noise=.0):
    t=tvec(seconds); phase=2*np.pi*(f0*t+(f1-f0)*t*t/(2*seconds))
    return (np.sin(phase)+noise*RNG.normal(size=len(t)))*np.sin(np.pi*t/seconds)**1.8*.28

def periodic_noise(seconds,low,high):
    n=round(seconds*SR); freqs=np.fft.rfftfreq(n,1/SR)
    spec=RNG.normal(size=len(freqs))+1j*RNG.normal(size=len(freqs))
    mask=(1-np.exp(-(freqs/max(low,1))**4))*np.exp(-(freqs/max(high,1))**4)
    spec*=mask/np.maximum(freqs,30)**.42
    x=np.fft.irfft(spec,n)
    return x/(np.std(x)+1e-9)

def add(buf,signal,start,gain=1,pan=0):
    # Wrap note tails across the loop boundary rather than leave a loop click.
    indices=(np.arange(len(signal))+round(start*SR))%len(buf)
    if buf.ndim==1: np.add.at(buf,indices,signal*gain)
    else:
        np.add.at(buf[:,0],indices,signal*gain*math.sqrt((1-pan)/2))
        np.add.at(buf[:,1],indices,signal*gain*math.sqrt((1+pan)/2))


def add_fx(buf,signal,start,gain=1,pan=0):
    offset=round(start*SR)
    count=min(len(signal),len(buf)-offset)
    if count>0:buf[offset:offset+count]+=signal[:count]*gain

def music(kind):
    bpm={'path':88,'friends':92,'festival':96,'finale':96}[kind]
    beat=60/bpm; duration=32*beat; buf=np.zeros((round(duration*SR),2))
    chords=[[50,57,62,66],[47,54,59,62],[43,50,55,59],[45,52,57,61]]
    melody=[74,None,76,78,81,78,76,None,74,71,69,None,71,74,76,None]
    if kind=='friends':melody=[74,76,None,78,76,74,71,None,69,71,None,74,76,78,76,None]
    if kind in ['festival','finale']:melody=[74,78,81,None,83,81,78,76,74,None,76,78,81,78,76,None]
    for bar in range(8):
        chord=chords[bar%4]
        add(buf,pluck(chord[0]-12,1.8,.25),bar*4*beat,.35,-.10)
        add(buf,pluck(chord[0]-12,1.3,.25),(bar*4+2)*beat,.22,.08)
        for eighth in range(8):
            note=chord[1+(eighth%3)]
            add(buf,pluck(note,1.3,.50),(bar*4+eighth*.5)*beat,.22,(-.35,.35)[eighth%2])
        for half in range(2):
            note=melody[(bar*2+half)%len(melody)]
            if note:
                voice=flute(note,beat*1.55) if kind in ['path','friends'] else bell(note,beat*1.8)
                add(buf,voice,(bar*4+half*2+.1)*beat,.42,.1 if half else -.1)
        if kind in ['festival','finale']:
            for b in range(4):
                shaker=RNG.normal(size=round(.08*SR))*np.exp(-tvec(.08)*65)*.10
                add(buf,shaker,(bar*4+b+.5)*beat,.11,(-.5,.5)[b%2])
        if kind=='finale' and bar in [0,4]:
            for j,note in enumerate([74,78,81,86]):add(buf,bell(note,2.0),bar*4*beat+j*.12,.30,(j-1.5)/5)
    # Soft short room reflection, preserving periodic boundaries.
    buf+=np.roll(buf,round(.087*SR),axis=0)*.10+np.roll(buf,round(.163*SR),axis=0)*.045
    return buf,duration

def ambience(kind):
    duration=24.;n=round(duration*SR);t=np.arange(n)/SR
    base=periodic_noise(duration,90,3400)
    wind=periodic_noise(duration,35,700)
    slow=.65+.15*np.sin(2*np.pi*t/duration*2)+.12*np.sin(2*np.pi*t/duration*5)
    buf=np.column_stack([base, np.roll(base,127)])*.018*slow[:,None]
    buf+=np.column_stack([wind,np.roll(wind,371)])*.014
    if kind=='river':
        flow=periodic_noise(duration,350,8000)
        buf+=np.column_stack([flow,np.roll(flow,93)])*.045*(.9+.1*np.sin(2*np.pi*t/duration*3))[:,None]
        for j in range(11):add(buf,sweep(1200,1900,.07,.25),j*2.1+.4,.09,math.sin(j)*.6)
    elif kind=='summit':
        buf+=np.column_stack([wind,np.roll(wind,533)])*.035*(.6+.4*np.sin(np.pi*t/duration*3)**2)[:,None]
    elif kind=='festival':
        murmur=periodic_noise(duration,250,1400)
        buf+=np.column_stack([murmur,np.roll(murmur,211)])*.012
        for j in range(4):add(buf,bell(83+j%2,1.1),j*5.7+1.4,.024,math.sin(j)*.7)
    if kind in ['home','garden','river','path','lantern']:
        count={'home':5,'garden':7,'river':3,'path':2,'lantern':2}[kind]
        for j in range(count):
            start=(j+.3)*duration/count
            chirp=sweep(2100+j*61,2900-j*37,.13)
            add(buf,chirp,start,.075,math.sin(j*1.8)*.75)
            add(buf,chirp,start+.19,.045,math.sin(j*1.8)*.75)
    return buf,duration

def noise_hit(seconds,low=120,high=3000):
    x=periodic_noise(seconds,low,high);t=tvec(seconds)
    return x*np.exp(-t*20)*(1-np.exp(-t*1000))*.22

def effect(name):
    duration=1.8 if name in ['finale','companion_join','task_complete','bridge_build'] else .75
    buf=np.zeros(round(duration*SR))
    notes={'ui_press':[74],'ui_back':[69,66],'ui_open':[69,74],'ui_toggle':[78],
           'interact':[69,76],'light_on':[74,81,86],'item_pickup':[78,81],
           'item_place':[69,74],'checkpoint':[74,78,81],'task_complete':[74,78,81,86],
           'companion_join':[69,74,78,81],'finale':[62,69,74,78,81,86],
           'flower':[78,81,86],'page_turn':[], 'pause':[69], 'resume':[74,78], 'error_soft':[66,64]}
    if name in notes:
        for j,note in enumerate(notes[name]):
            add_fx(buf,bell(note,1.5) if name in ['light_on','flower','finale','checkpoint'] else pluck(note,.8,.45),j*.105,.65 if name=='finale' else .45)
    if name=='jump':add_fx(buf,sweep(230,470,.16,.04),0,.5)
    elif name=='land':add_fx(buf,noise_hit(.18,45,900),0,.8);add_fx(buf,pluck(43,.25,.1),0,.25)
    elif name=='step_grass':add_fx(buf,noise_hit(.12,900,6500),0,.5)
    elif name=='step_wood':add_fx(buf,noise_hit(.10,200,2000),0,.6);add_fx(buf,pluck(50,.18,.3),0,.25)
    elif name=='rope_tie':
        add_fx(buf,noise_hit(.20,600,4000),0,.55);add_fx(buf,noise_hit(.12,100,2000),.16,.30)
    elif name=='water_return':
        x=periodic_noise(.5,400,5500)*np.sin(np.pi*tvec(.5)/.5)**2*.12;add_fx(buf,x,0,.75)
        add_fx(buf,bell(74,.6),.3,.12)
    elif name=='bridge_build':
        for j in range(5):add_fx(buf,noise_hit(.10,150,2200),j*.13,.45);add_fx(buf,pluck(43+j*2,.3,.3),j*.13,.2)
        add_fx(buf,pluck(74,.8,.5),.8,.4)
    elif name=='page_turn':add_fx(buf,noise_hit(.3,1500,7500),0,.28)
    return buf

def write_wav(path,buf):
    buf=np.asarray(buf,dtype=float)
    peak=float(np.max(np.abs(buf)))
    if peak>.78:buf*=.78/peak
    # Effects settle to exact silence; ambience/music remain cyclic.
    with wave.open(str(path),'wb') as stream:
        stream.setnchannels(1 if buf.ndim==1 else buf.shape[1]);stream.setsampwidth(2);stream.setframerate(SR)
        stream.writeframes((np.clip(buf,-1,1)*32767).astype('<i2').tobytes())
    return buf

def main():
    OUT.mkdir(parents=True,exist_ok=True);entries=[]
    with tempfile.TemporaryDirectory(prefix='catpat-audio-') as tmp:
        for family,keys in [('music',['path','friends','festival','finale']),('ambience',['home','lantern','river','garden','summit','festival'])]:
            for key in keys:
                buf,duration=music(key) if family=='music' else ambience(key)
                wav=Path(tmp)/f'{family}_{key}.wav';buf=write_wav(wav,buf)
                target=OUT/f'{family}_{key}.ogg'
                pending=target.with_suffix('.ogg.pending')
                subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','4','-f','ogg',str(pending)],check=True)
                pending.replace(target)
                entries.append(record(target,family,key,buf,True))
        names=['ui_press','ui_back','ui_open','ui_toggle','step_grass','step_wood','jump','land','interact','light_on','rope_tie','item_pickup','item_place','bridge_build','water_return','checkpoint','task_complete','companion_join','finale','pause','resume','page_turn','error_soft','flower']
        for key in names:
            buf=effect(key);buf[-round(.03*SR):]*=np.linspace(1,0,round(.03*SR))
            target=OUT/f'sfx_{key}.wav';pending=target.with_suffix('.wav.pending');buf=write_wav(pending,buf);pending.replace(target)
            entries.append(record(target,'sfx',key,buf,False))
    manifest={'version':1,'generator':'tools/generate_audio.py','seed':1052026,'sample_rate':SR,'origin':'Original procedural composition and synthesis. No external samples or melodies; no recorded musician or natural field-recording claim.','style':'Gentle plucked wood / breathy flute / soft bell, quiet synthetic woodland ambiences.','review_status':'Technical generation checked; listening and target-device/browser QA still required.','assets':entries}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
    print(f'Generated {len(entries)} original audio assets, {sum((ROOT/e["path"]).stat().st_size for e in entries):,} bytes')

def record(path,family,key,buf,loop):
    return {'id':f'{family}.{key}','path':str(path.relative_to(ROOT)),'loop':loop,'duration_seconds':round(len(buf)/SR,5),'channels':1 if buf.ndim==1 else buf.shape[1],'peak_linear':round(float(np.max(np.abs(buf))),5),'rms_linear':round(float(np.sqrt(np.mean(buf**2))),5),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

if __name__=='__main__':main()
