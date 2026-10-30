import re,os,json
R=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','..','resources')
CALL=re.compile(r"(RegisterCommand|ESX\.RegisterCommand|lib\.addCommand|RegisterKeyMapping)\(\s*\{?\s*\{?\s*(['\"][^'\"]+['\"]|[A-Za-z_][\w\.\[\]]*)")
def configs(rp):
    t=''
    for dp,dn,fn in os.walk(rp):
        if any(x in dp for x in ('node_modules','/html','/web','/dist')): continue
        for f in fn:
            if f.endswith('.lua') and ('config' in f.lower() or 'shared' in dp or f in ('config.lua',)):
                try: t+=open(os.path.join(dp,f),encoding='utf8',errors='ignore').read()+'\n'
                except: pass
    return t
def resolve(expr,cfg):
    if expr[0] in '\'"': return expr[1:-1]
    parts=[p for p in re.split(r"[\.\[\]'\"]+",expr) if p]
    if len(parts)>=2:
        m=re.search(re.escape(parts[-2])+r"\s*=\s*\{[^{}]*?\b"+re.escape(parts[-1])+r"\s*=\s*['\"]([^'\"]+)['\"]",cfg,re.S)
        if m: return m.group(1)
    m=re.search(r"\b"+re.escape(parts[-1])+r"\s*=\s*['\"]([^'\"]+)['\"]",cfg)
    return m.group(1) if m else None
out={}; unres={}
for top in sorted(os.listdir(R)):
    tp=os.path.join(R,top)
    if not os.path.isdir(tp): continue
    for res in sorted(os.listdir(tp)):
        rp=os.path.join(tp,res)
        if not os.path.isdir(rp): continue
        cfg=configs(rp); cmds={}
        for dp,dn,fn in os.walk(rp):
            if any(x in dp for x in ('node_modules','/html','/web','/dist','/ui','/stream','/dlc')): continue
            for f in fn:
                if not f.endswith('.lua') or f=='fxmanifest.lua': continue
                fp=os.path.join(dp,f); rel=os.path.relpath(fp,rp)
                try: lines=open(fp,encoding='utf8',errors='ignore').read().split('\n')
                except: continue
                for i,l in enumerate(lines):
                    for m in CALL.finditer(l):
                        kind,expr=m.group(1),m.group(2)
                        if expr in ('function','{'): continue
                        name=resolve(expr,cfg)
                        if not name:
                            unres.setdefault(res,set()).add(expr); continue
                        if name.startswith('+') or name.startswith('-'): continue
                        e=cmds.setdefault(name,{'name':name,'file':rel,'desc':'','key':''})
                        if kind=='RegisterKeyMapping':
                            km=re.search(r"RegisterKeyMapping\([^,]+,\s*['\"]([^'\"]*)['\"]\s*,\s*['\"][^'\"]*['\"]\s*,\s*['\"]([^'\"]*)['\"]",l)
                            if km: e['desc']=km.group(1); e['key']=km.group(2)
                        else:
                            blk=' '.join(lines[i:i+4])
                            h=re.search(r"help\s*=\s*['\"]([^'\"]+)['\"]",blk)
                            if h and not e['desc']: e['desc']=h.group(1)[:140]
                            c=re.search(r"--\s*(.+)$",l)
                            if c and not e['desc']: e['desc']=c.group(1).strip()[:140]
        out[top+'/'+res]=sorted(cmds.values(),key=lambda x:x['name'])
json.dump(out,open('commands_raw.json','w'),ensure_ascii=False)
print(sum(len(v) for v in out.values()))
for r,v in unres.items(): print('UNRES',r,sorted(v)[:6])
for k,v in out.items(): 
    if v: print(k,len(v))
