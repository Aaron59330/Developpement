import numpy as np, wave
SR=44100
INTRO,SD,N=4.0,4.2,13
OUT=INTRO+SD*N; TOTAL=OUT+4.4
n=int(TOTAL*SR); L=np.zeros(n); R=np.zeros(n)
rng=np.random.default_rng(7)
def add(sig,t0,pan=0.0,g=1.0):
    i=int(t0*SR)
    if i<0: sig=sig[-i:]; i=0
    m=min(len(sig),n-i)
    if m<=0: return
    L[i:i+m]+=sig[:m]*g*(1-pan)/1.0; R[i:i+m]+=sig[:m]*g*(1+pan)/1.0
def env(dur,a=.008,r=None):
    t=np.arange(int(dur*SR))/SR; r=r or dur
    e=np.minimum(t/a,1)*np.exp(-t*(4.5/dur))
    return e
def tone(f,dur,kind='sine',vol=.1,slide=None,a=.008):
    t=np.arange(int(dur*SR))/SR
    ff=f if slide is None else f*(slide/f)**(t/dur)
    ph=2*np.pi*np.cumsum(ff)/SR
    if kind=='sine': w=np.sin(ph)
    elif kind=='tri': w=2/np.pi*np.arcsin(np.sin(ph))
    elif kind=='saw': w=2*((ph/(2*np.pi))%1)-1
    else: w=np.sign(np.sin(ph))
    return w*env(dur,a)*vol
def whoosh(dur=.9,vol=.12):
    t=np.arange(int(dur*SR))/SR
    x=rng.standard_normal(len(t))
    # filtre passe-bande glissant (moyenne mobile variable simple)
    y=np.zeros_like(x); c=0.0
    for i in range(len(t)):
        k=.02+.5*np.sin(np.pi*t[i]/dur)**2
        c+=(x[i]-c)*k; y[i]=c
    e=np.sin(np.pi*t/dur)**2
    return y*e*vol*4
def blip(): return tone(540,.07,'sine',.11)+np.pad(tone(810,.09,'sine',.08),(int(.035*SR),0))[:int(.12*SR)] if False else None
def click(vol=1):
    a=tone(540,.07,'sine',.10*vol); b=tone(810,.09,'sine',.07*vol); out=np.zeros(int(.13*SR)); out[:len(a)]+=a; i=int(.035*SR); out[i:i+len(b)]+=b; return out
def ding(vol=1):
    a=tone(1175,.22,'sine',.09*vol); b=tone(1568,.34,'sine',.07*vol); out=np.zeros(int(.5*SR)); out[:len(a)]+=a; i=int(.09*SR); out[i:i+len(b)]+=b; return out
def confirm(vol=1):
    out=np.zeros(int(.4*SR))
    for k,(f,d) in enumerate([(520,.1),(780,.1),(1040,.2)]):
        s=tone(f,d,'tri',.1*vol); i=int(k*.07*SR); out[i:i+len(s)]+=s
    return out
# ---- nappe douce (accords Am - F - C - G, 4,2 s chacun)
chords=[(220,261.6,329.6),(174.6,220,261.6),(261.6,329.6,392),(196,246.9,293.7)]
t=np.arange(n)/SR
pad=np.zeros(n)
for ci in range(int(TOTAL//SD)+2):
    s0=ci*SD; ch=chords[ci%4]
    i0=int(s0*SR); i1=min(n,int((s0+SD+.6)*SR))
    if i0>=n: break
    tt=np.arange(i1-i0)/SR
    e=np.minimum(tt/1.2,1)*np.minimum((SD+.6-tt)/1.0,1)
    for f in ch:
        pad[i0:i1]+=np.sin(2*np.pi*f*tt)*.5*e*.028
        pad[i0:i1]+=np.sin(2*np.pi*f*2*tt+.4)*.2*e*.012
fade=np.minimum(t/2.0,1)*np.minimum((TOTAL-t)/2.0,1)
pad*=fade
L+=pad;R+=pad
# ---- arpège pluck léger (croches à 120 bpm)
pent=[440,523.3,587.3,659.3,784,880,784,659.3]
beat=.5
k=0
for tt0 in np.arange(INTRO-.5,OUT+3.5,beat):
    f=pent[(k*3+k//4)%len(pent)]*(1 if (k//8)%2==0 else .75)
    s=tone(f,.55,'tri',.020,a=.004)
    add(s,tt0,pan=((k%4)-1.5)*.15)
    k+=1
# ---- intro : montée + sting logo
add(whoosh(1.2,.10),0.0)
add(ding(1.4),0.55,g=1.0); add(confirm(1.0),1.0)
for i,f in enumerate([220,330,440]): add(tone(f,1.8,'sine',.05,a=.3),0.4+i*.05)
# ---- scènes
for i in range(N):
    s0=INTRO+i*SD
    add(whoosh(.9,.11),s0-.5)
    add(click(1.2),s0+.20)             # titre
    add(click(.8),s0+.55,pan=.2)       # texte
    for j in range(2):
        add(tone(900+j*180,.07,'sine',.07),s0+1.25+j*.35,pan=.3)   # puces
    if i%3==0: add(ding(.8),s0+1.5,pan=-.2)
# ---- outro
add(whoosh(1.0,.10),OUT-.4)
add(ding(1.5),OUT+.5); add(confirm(1.3),OUT+.9)
for i,f in enumerate([261.6,329.6,392,523.3]): add(tone(f,2.6,'sine',.05,a=.15),OUT+.4+i*.12)
m=max(np.abs(L).max(),np.abs(R).max()); g=.8/m
st=np.stack([L*g,R*g],1)
pcm=(st*32767).astype('<i2')
with wave.open('/tmp/vid/audio.wav','wb') as w:
    w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
print('ok',TOTAL)
