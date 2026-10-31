(function(){
const $=s=>document.querySelector(s), root=$('#root');
const RES=(typeof GetParentResourceName==='function')?GetParentResourceName():'pickax_casino';
const post=(n,d)=>fetch('https://'+RES+'/'+n,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d||{})}).then(r=>r.json()).catch(()=>({ok:false,msg:'Erreur réseau'}));
const fmt=n=>Number(n||0).toLocaleString('fr-FR').replace(/ | /g,' ');
let S=null,G=null,bet=0,busy=false,view={};
function toast(t,bad){const e=$('#toast');e.textContent=t;e.className='on'+(bad?' bad':'');clearTimeout(toast.t);toast.t=setTimeout(()=>e.className='',2600)}
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));

/* ───── symboles dessinés en SVG ───── */
const SYM={
 seven:'<svg viewBox="0 0 64 64"><text x="32" y="52" text-anchor="middle" font-size="58" font-weight="900" font-family="Georgia,serif" fill="#d22" stroke="#7a0d0d" stroke-width="2">7</text></svg>',
 bar:'<svg viewBox="0 0 64 64"><rect x="4" y="18" width="56" height="28" rx="5" fill="#111" stroke="#c9a24a" stroke-width="3"/><text x="32" y="40" text-anchor="middle" font-size="20" font-weight="900" fill="#f5d77a" font-family="Arial">BAR</text></svg>',
 bell:'<svg viewBox="0 0 64 64"><path d="M32 8c-3 0-5 2-5 5-8 3-12 10-12 20 0 6-3 8-5 11h44c-2-3-5-5-5-11 0-10-4-17-12-20 0-3-2-5-5-5z" fill="#f2b705" stroke="#8a6500" stroke-width="2.5"/><circle cx="32" cy="52" r="5" fill="#8a6500"/></svg>',
 plum:'<svg viewBox="0 0 64 64"><circle cx="32" cy="38" r="20" fill="#7a2bb8" stroke="#431a68" stroke-width="2.5"/><path d="M32 18c0-6 3-10 8-12" stroke="#3b7a2b" stroke-width="4" fill="none" stroke-linecap="round"/><ellipse cx="24" cy="30" rx="5" ry="3" fill="rgba(255,255,255,.35)"/></svg>',
 lemon:'<svg viewBox="0 0 64 64"><ellipse cx="32" cy="34" rx="25" ry="18" fill="#f5e03a" stroke="#a89500" stroke-width="2.5"/><path d="M6 34h-4M58 34h4" stroke="#a89500" stroke-width="4" stroke-linecap="round"/><ellipse cx="24" cy="28" rx="8" ry="3.5" fill="rgba(255,255,255,.45)"/></svg>',
 cherry:'<svg viewBox="0 0 64 64"><path d="M20 40c4-18 12-26 26-30M44 42C44 26 42 18 46 10" stroke="#3b7a2b" stroke-width="3.5" fill="none" stroke-linecap="round"/><circle cx="19" cy="46" r="12" fill="#d22" stroke="#7a0d0d" stroke-width="2.5"/><circle cx="45" cy="47" r="12" fill="#d22" stroke="#7a0d0d" stroke-width="2.5"/><circle cx="15" cy="42" r="3" fill="rgba(255,255,255,.55)"/><circle cx="41" cy="43" r="3" fill="rgba(255,255,255,.55)"/></svg>'
};
const NAMES={seven:'Sept',bar:'BAR',bell:'Cloche',plum:'Prune',lemon:'Citron',cherry:'Cerise'};

/* ───── cadre commun ───── */
function frame(title,sub,inner){
  root.innerHTML='<div class="win"><div class="top"><div class="logo">♠</div><div><h1>'+esc(title)+'</h1><small>'+esc(sub)+'</small></div><div class="sp"></div>'+
  '<div class="bal">Jetons<b id="chips">'+fmt(S.chips)+'</b></div><button class="x" id="cl">✕</button></div><div class="body">'+inner+'</div></div>';
  $('#cl').onclick=()=>post('close');
}
function setChips(n){S.chips=n;const e=$('#chips');if(e)e.textContent=fmt(n)}

/* ───── caisse ───── */
function cashier(){
  frame(S.name,'Caisse — achat et rachat de jetons',
   '<div class="cols"><div class="card"><h2>Acheter des jetons</h2><p>1 jeton = '+S.buy+' $ ('+(S.currency==='bank'?'banque':'liquide')+'). Tu as <b>'+fmt(S.cash)+' $</b>.</p>'+
   '<div class="row">'+[100,500,1000,5000,10000].map(v=>'<button class="chipb" data-b="'+v+'">'+fmt(v)+'</button>').join('')+'</div>'+
   '<input class="num" id="ib" type="number" min="'+S.minBuy+'" max="'+S.maxBuy+'" placeholder="Nombre de jetons">'+
   '<div class="big" id="cb">0 <small>$</small></div><button class="pri" id="bb">ACHETER</button></div>'+
   '<div class="card"><h2>Racheter mes jetons</h2><p>Chaque jeton est racheté '+(S.sell*S.buy).toFixed(2)+' $ ('+Math.round(S.sell*100)+' %).</p>'+
   '<div class="row"><button class="chipb" data-s="all">Tout</button><button class="chipb" data-s="half">Moitié</button></div>'+
   '<input class="num" id="is" type="number" min="1" placeholder="Nombre de jetons">'+
   '<div class="big" id="cs">0 <small>$</small></div><button class="sec" id="bs">RACHETER</button></div></div>'+
   '<div class="stats"><div class="stat"><small>Jetons achetés</small><b>'+fmt(S.stats.bought)+'</b></div><div class="stat"><small>Jetons rachetés</small><b>'+fmt(S.stats.sold)+'</b></div><div class="stat"><small>Total misé</small><b>'+fmt(S.stats.wagered)+'</b></div><div class="stat"><small>Total gagné</small><b>'+fmt(S.stats.won)+'</b></div></div>');
  const ib=$('#ib'),is=$('#is');
  const upd=()=>{$('#cb').innerHTML=fmt(Math.ceil((+ib.value||0)*S.buy))+' <small>$</small>';$('#cs').innerHTML=fmt(Math.floor((+is.value||0)*S.sell*S.buy))+' <small>$</small>'};
  ib.oninput=is.oninput=upd;
  document.querySelectorAll('[data-b]').forEach(b=>b.onclick=()=>{ib.value=(+ib.value||0)+(+b.dataset.b);upd()});
  document.querySelectorAll('[data-s]').forEach(b=>b.onclick=()=>{is.value=b.dataset.s==='all'?S.chips:Math.floor(S.chips/2);upd()});
  $('#bb').onclick=async()=>{const r=await post('buy',{chips:+ib.value});if(r.ok){S.cash=r.cash;setChips(r.chips);toast(r.msg);cashier()}else toast(r.msg,1)};
  $('#bs').onclick=async()=>{const r=await post('sell',{chips:+is.value});if(r.ok){S.cash=r.cash;setChips(r.chips);toast(r.msg);cashier()}else toast(r.msg,1)};
}

/* ───── mise ───── */
function betRow(list,onPick){
  return '<div class="row" id="betrow">'+list.map(v=>'<button class="chipb'+(v===bet?' on':'')+'" data-v="'+v+'">'+fmt(v)+'</button>').join('')+'</div>';
}
function bindBet(onPick){document.querySelectorAll('#betrow .chipb').forEach(b=>b.onclick=()=>{bet=+b.dataset.v;document.querySelectorAll('#betrow .chipb').forEach(x=>x.classList.toggle('on',x===b));onPick&&onPick()})}

/* ───── machine à sous ───── */
function cellHtml(s,win){return '<div class="cell'+(win?' hit':'')+'">'+SYM[s]+'</div>'}
function slots(grid,wins,msg){
  const m=G.cfg;if(!bet||bet<m.min)bet=m.bets[0];
  grid=grid||[['lemon','cherry','plum'],['bell','lemon','bar'],['plum','seven','lemon']];
  const winCells={};(wins||[]).forEach(w=>{const L=[[2,2,2],[1,1,1],[3,3,3],[1,2,3],[3,2,1]][w.line-1];L.forEach((row,r)=>winCells[r+'-'+(row-1)]=1)});
  const pays=Object.keys(G.symbols).sort((a,b)=>G.symbols[b]-G.symbols[a]);
  frame(m.label,'3 rouleaux · 5 lignes de gain · mise de '+fmt(m.min)+' à '+fmt(m.max),
   '<div class="slot"><div class="cab"><div class="cabtitle">★ '+esc(S.name.toUpperCase())+' ★</div><div class="reels">'+
   [0,1,2].map(r=>'<div class="reel" id="r'+r+'">'+[0,1,2].map(row=>cellHtml(grid[r][row],winCells[r+'-'+row])).join('')+'</div>').join('')+'</div>'+
   '<div class="msg" id="msg">'+(msg||'')+'</div>'+betRow(m.bets)+'<button class="pri" id="spin">TOURNER — '+fmt(bet)+' JETONS</button></div>'+
   '<div class="pay"><h3>Tableau des gains (× mise ÷ 5 par ligne)</h3>'+pays.map(s=>'<div class="pr">'+SYM[s]+SYM[s].replace('<svg','<svg style="margin-left:-14px"')+SYM[s].replace('<svg','<svg style="margin-left:-14px"')+'<span>'+NAMES[s]+'</span><b>×'+G.symbols[s]+'</b></div>').join('')+
   '<div class="pr">'+SYM.cherry+SYM.cherry.replace('<svg','<svg style="margin-left:-14px"')+'<span>2 cerises au début</span><b>×'+G.cherryTwo+'</b></div></div></div>');
  bindBet(()=>{$('#spin').textContent='TOURNER — '+fmt(bet)+' JETONS'});
  $('#spin').onclick=async()=>{
    if(busy)return;busy=true;$('#spin').disabled=true;$('#msg').textContent='';
    document.querySelectorAll('.reel').forEach(r=>r.classList.add('spin'));
    const [r]=await Promise.all([post('slots',{bet}),new Promise(k=>setTimeout(k,1100))]);
    busy=false;
    if(!r.ok){toast(r.msg,1);slots(grid,null,'');return}
    setChips(r.chips);
    slots(r.grid,r.wins,r.payout>0?'GAGNÉ ! +'+fmt(r.payout)+' jetons':'Perdu…');
  };
}

/* ───── blackjack ───── */
function card(c){
  if(c.hidden)return '<div class="pc back"></div>';
  const R=['','A','2','3','4','5','6','7','8','9','10','J','Q','K'][c.rank],su=['♠','♥','♦','♣'][c.suit-1],red=c.suit===2||c.suit===3;
  return '<div class="pc'+(red?' red':'')+'"><span class="r">'+R+'</span><span class="s">'+su+'</span></div>';
}
const RES_TXT={blackjack:'BLACKJACK ! ',win:'Gagné ! ',push:'Égalité — mise rendue',lose:'Perdu…',bust:'Dépassé — perdu'};
function blackjack(v){
  const m=G.cfg;if(!bet||bet<m.min)bet=m.bets[0];
  let mid='',acts='';
  if(!v){acts=betRow(m.bets)+'<button class="pri" id="deal">DISTRIBUER — '+fmt(bet)+' JETONS</button>';}
  else if(v.over){mid=(RES_TXT[v.result]||'')+(v.payout>0&&v.result!=='push'?'+'+fmt(v.payout-v.bet)+' jetons':'');acts=betRow(m.bets)+'<button class="pri" id="deal">NOUVELLE PARTIE — '+fmt(bet)+' JETONS</button>';}
  else acts='<div class="acts"><button class="pri" data-a="hit">TIRER</button><button class="sec" data-a="stand">RESTER</button><button class="sec" data-a="double"'+(v.canDouble?'':' disabled')+'>DOUBLER</button></div>';
  frame(m.label,'Blackjack paie 3 pour 2 · le croupier tire jusqu\'à 17 · mise de '+fmt(m.min)+' à '+fmt(m.max),
   '<div class="felt"><div class="hand"><h4>Croupier'+(v?'<b>'+v.dealerValue+'</b>':'')+'</h4><div class="cards">'+(v?v.dealer.map(card).join(''):'')+'</div></div>'+
   '<div class="bjmid">'+(mid||(v?'Mise : '+fmt(v.bet):'Place ta mise'))+'</div>'+
   '<div class="hand"><h4>Toi'+(v?'<b>'+v.playerValue+'</b>':'')+'</h4><div class="cards">'+(v?v.player.map(card).join(''):'')+'</div></div></div>'+acts);
  bindBet(()=>{const d=$('#deal');if(d)d.textContent=(v&&v.over?'NOUVELLE PARTIE':'DISTRIBUER')+' — '+fmt(bet)+' JETONS'});
  const d=$('#deal');if(d)d.onclick=async()=>{const r=await post('bjDeal',{bet});if(!r.ok)return toast(r.msg,1);setChips(r.chips);blackjack(r.view)};
  document.querySelectorAll('[data-a]').forEach(b=>b.onclick=async()=>{if(busy)return;busy=true;const r=await post('bjAct',{act:b.dataset.a});busy=false;if(!r.ok)return toast(r.msg,1);setChips(r.chips);blackjack(r.view)});
}

/* ───── roulette ───── */
const RED=[1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
const col=n=>n===0?'green':RED.includes(n)?'red':'black';
const OUT=[['dozen1','1-12',4],['dozen2','13-24',4],['dozen3','25-36',4]];
function roulette(res,msg){
  const t=G.cfg;if(!bet||!t.chips.includes(bet))bet=t.chips[0];
  if(!view.bets)view.bets=[];if(!view.hist)view.hist=[];
  const tot=()=>view.bets.reduce((s,b)=>s+b.a,0);
  const amt=(k)=>view.bets.filter(b=>(b.t===k.t&&(b.t!=='straight'||b.n===k.n))).reduce((s,b)=>s+b.a,0);
  const cell=(k,label,cls,style)=>{const a=amt(k);return '<div class="n '+cls+'" style="'+(style||'')+'" data-t="'+k.t+'" data-n="'+(k.n==null?'':k.n)+'">'+label+(a?'<span class="coin">'+fmt(a)+'</span>':'')+'</div>'};
  let g=cell({t:'straight',n:0},'0','green','grid-row:1/4;grid-column:1');
  for(let n=1;n<=36;n++){const c=Math.floor((n-1)/3),r=2-((n-1)%3);g+=cell({t:'straight',n},n,col(n),'grid-column:'+(c+2)+';grid-row:'+(r+1))}
  ['col3','col2','col1'].forEach((k,i)=>g+=cell({t:k},'2:1','out','grid-column:14;grid-row:'+(i+1)));
  OUT.forEach(([k,l],i)=>g+=cell({t:k},l,'out','grid-column:'+(2+i*4)+'/'+(6+i*4)+';grid-row:4'));
  [['low','1-18'],['even','PAIR'],['red','ROUGE'],['black','NOIR'],['odd','IMPAIR'],['high','19-36']].forEach(([k,l],i)=>g+=cell({t:k},l,k==='red'?'red':k==='black'?'black':'out','grid-column:'+(2+i*2)+'/'+(4+i*2)+';grid-row:5'));
  const ball=res?'<div class="ball '+res.color+'">'+res.number+'</div>':'<div class="ball green" style="opacity:.35">?</div>';
  frame(t.label,'Roulette européenne (un seul zéro) · mise de '+fmt(t.min)+' à '+fmt(t.max)+' par case · total max '+fmt(t.total),
   '<div class="rl"><div class="felt"><div class="grid">'+g+'</div></div><div class="card"><h2>Mes mises</h2>'+
   '<div class="row">'+t.chips.map(v=>'<button class="chipb'+(v===bet?' on':'')+'" data-c="'+v+'">'+fmt(v)+'</button>').join('')+'</div>'+
   ball+'<div class="msg" id="msg" style="font-size:15px">'+(msg||'')+'</div><div class="hist">'+view.hist.slice(-12).map(n=>'<span style="background:'+({red:'#b52b2b',black:'#15161a',green:'#1e7a4d'})[col(n)]+'">'+n+'</span>').join('')+'</div>'+
   '<div class="big" style="font-size:22px;margin-top:10px">Total misé : '+fmt(tot())+'</div><button class="pri" id="spin"'+(view.bets.length?'':' disabled')+'>LANCER LA BILLE</button><div style="height:8px"></div><button class="sec" id="clr">Effacer les mises</button></div></div>');
  document.querySelectorAll('[data-c]').forEach(b=>b.onclick=()=>{bet=+b.dataset.c;roulette(res,msg)});
  document.querySelectorAll('.n').forEach(e=>e.onclick=()=>{const k={t:e.dataset.t,a:bet};if(e.dataset.n!=='')k.n=+e.dataset.n;const f=view.bets.find(b=>b.t===k.t&&b.n===k.n);if(f)f.a+=bet;else view.bets.push(k);roulette(res,msg)});
  $('#clr').onclick=()=>{view.bets=[];roulette(res,'')};
  $('#spin').onclick=async()=>{
    if(busy)return;busy=true;$('#spin').disabled=true;const bl=$('.ball');bl.classList.add('spin');bl.textContent='…';
    const [r]=await Promise.all([post('roulette',{bets:view.bets}),new Promise(k=>setTimeout(k,1500))]);
    busy=false;
    if(!r.ok){toast(r.msg,1);return roulette(null,'')}
    setChips(r.chips);view.hist.push(r.number);
    roulette(r,(r.payout>0?'GAGNÉ ! +'+fmt(r.payout-r.bet)+' jetons':'Perdu… (−'+fmt(r.bet)+')'));
  };
}

window.addEventListener('message',e=>{
  const d=e.data||{};
  if(d.action==='open'){S=d.state;G=d.game;bet=0;view={};busy=false;root.classList.remove('hidden');
    ({cashier:()=>cashier(),slots:()=>slots(),blackjack:()=>blackjack(),roulette:()=>roulette()})[G.kind]()}
  else if(d.action==='close'){root.classList.add('hidden');root.innerHTML=''}
});
window.addEventListener('keydown',e=>{if(e.key==='Escape')post('close')});
window.__casino={open:d=>window.postMessage(Object.assign({action:'open'},d),'*'),renderers:{cashier,slots,blackjack,roulette},set:(s,g)=>{S=s;G=g}};
})();
