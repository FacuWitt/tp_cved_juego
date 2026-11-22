import numpy as np, wave
from scipy import signal
SR=44100
rng=np.random.default_rng(7)
def save(name,x,peak=0.85):
    x=np.asarray(x,dtype=np.float64).copy()
    if 'loop' not in name:
        k=int(SR*0.03); x[-k:]*=np.linspace(1,0,k)
    m=np.max(np.abs(x)); x=x/m*peak if m>0 else x
    w=wave.open(name+'.wav','wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((x*32767).astype('<i2').tobytes()); w.close()
def bp(x,lo,hi,order=2):
    b,a=signal.butter(order,[lo/(SR/2),hi/(SR/2)],'band'); return signal.lfilter(b,a,x)
def lp(x,f,order=2):
    b,a=signal.butter(order,f/(SR/2)); return signal.lfilter(b,a,x)
def hp(x,f,order=2):
    b,a=signal.butter(order,f/(SR/2),'high'); return signal.lfilter(b,a,x)
def knock(f0,dur=0.22,hard=1.0,r=rng):
    n=int(SR*dur); t=np.arange(n)/SR; x=np.zeros(n)
    for ratio,amp,dec in [(1.0,1.0,38),(2.31,0.55,55),(3.87,0.35,80),(5.9,0.18,120)]:
        f=f0*ratio*(1+r.uniform(-0.03,0.03))
        x+=amp*np.sin(2*np.pi*f*t+r.uniform(0,6.28))*np.exp(-dec*t*(0.8+0.4*r.random()))
    click=r.standard_normal(n)*np.exp(-900*t); x+=hard*0.6*lp(click,5000)
    x+=0.25*np.sin(2*np.pi*f0*0.5*t)*np.exp(-30*t)   # cuerpo hueco
    return x
# 1. golpes de madera sueltos
for i,f in enumerate([310,420,540,690,860]):
    save(f'wood_knock_{i+1}',knock(f,0.4,1.0),0.8)
# 2. cascada de barcos (loop)
L=int(SR*6.0); x=np.zeros(L)
for _ in range(190):
    k=knock(rng.uniform(240,1100),0.2,rng.uniform(0.5,1.2))*rng.uniform(0.15,1.0)**1.5
    p=rng.integers(0,L); idx=(p+np.arange(len(k)))%L; x[idx]+=k
save('boat_cascade_loop',lp(x,7000),0.8)
# 3. zumbido de tubos fluorescentes (loop de 4 s, ciclos enteros)
n=int(SR*4.0); t=np.arange(n)/SR; x=np.zeros(n)
for h,a in [(1,0.5),(2,1.0),(3,0.25),(4,0.45),(6,0.3),(8,0.18),(10,0.1),(12,0.07),(24,0.03)]:
    x+=a*np.sin(2*np.pi*50*h*t+h)
x*=1+0.06*np.sin(2*np.pi*0.5*t)+0.03*np.sin(2*np.pi*7*t)
hiss=bp(rng.standard_normal(n),5000,9000)*0.012*(1+0.5*np.sin(2*np.pi*100*t))
whine=0.008*np.sin(2*np.pi*3150*t)
save('fluoro_hum_loop',x+hiss+whine,0.6)
# 4. relé / tubo que se apaga
n=int(SR*0.35); t=np.arange(n)/SR
x=lp(rng.standard_normal(n)*np.exp(-700*t),6000)+0.8*np.sin(2*np.pi*140*t)*np.exp(-28*t)+0.4*np.sin(2*np.pi*1900*t)*np.exp(-200*t)
x[int(0.045*SR):]+=0.5*(lp(rng.standard_normal(n)*np.exp(-900*t),5000))[:n-int(0.045*SR)]
save('relay_clack',x,0.8)
# 5. trazos de escritura (alguien escribe en la pared)
for i in range(3):
    n=int(SR*rng.uniform(0.7,1.1)); t=np.arange(n)/SR; env=np.zeros(n)
    pos=0.02
    while pos<n/SR-0.12:
        d=rng.uniform(0.07,0.2); a=int(pos*SR); b=min(n,a+int(d*SR))
        env[a:b]+=np.hanning(b-a)*rng.uniform(0.4,1.0); pos+=d+rng.uniform(0.01,0.07)
    x=bp(rng.standard_normal(n),1800,5200)*env*(1+0.6*np.sin(2*np.pi*rng.uniform(25,45)*t))
    save(f'scrawl_{i+1}',x,0.55)
# 6. drone grave (loop de 12 s)
n=int(SR*12.0); t=np.arange(n)/SR
x=0.9*np.sin(2*np.pi*41*t)+0.8*np.sin(2*np.pi*(41+1/3)*t)+0.5*np.sin(2*np.pi*61.5*t)*(0.6+0.4*np.sin(2*np.pi*t/6))
x+=0.25*np.sin(2*np.pi*82.25*t)*(0.5+0.5*np.sin(2*np.pi*t/4+1))
nz=np.fft.rfft(rng.standard_normal(n)); f=np.fft.rfftfreq(n,1/SR); nz[1:]/=f[1:]; nz[0]=0; nz[f>400]=0   # ruido marrón, periódico
x+=3.0*np.fft.irfft(nz,n)/np.max(np.abs(np.fft.irfft(nz,n)))*0.5
hi=0.06*np.sin(2*np.pi*1217*t)*(0.5+0.5*np.sin(2*np.pi*t/12))+0.05*np.sin(2*np.pi*1223*t)
save('dread_drone_loop',x+hi,0.7)
# 7. golpe grave del apagón
n=int(SR*2.2); t=np.arange(n)/SR
x=np.sin(2*np.pi*(38+30*np.exp(-9*t))*t)*np.exp(-2.3*t)+0.5*lp(rng.standard_normal(n)*np.exp(-60*t),900)+0.15*lp(rng.standard_normal(n),200)*np.exp(-1.5*t)
save('blackout_thud',x,0.9)
# 8. chisporroteo eléctrico (tubo que parpadea)
n=int(SR*0.3); t=np.arange(n)/SR
gate=(signal.square(2*np.pi*100*t,0.3)>0)*(rng.random(n)>0.2)
x=hp(rng.standard_normal(n),2500)*gate*np.exp(-6*t)+0.4*np.sin(2*np.pi*100*t)*np.exp(-8*t)
save('tube_flicker',x,0.6)
# 9. golpe en el cuerpo (un barco te pega)
n=int(SR*0.4); t=np.arange(n)/SR
x=knock(170,0.4,1.4,rng)[:n]+1.2*np.sin(2*np.pi*70*t)*np.exp(-22*t)
save('boat_hit_body',x,0.85)
