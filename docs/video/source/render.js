const {chromium}=require('playwright');const {spawn}=require('child_process');const fs=require('fs');
(async()=>{
 const FPS=30;
 const b=await chromium.launch();const p=await b.newPage({viewport:{width:1280,height:720}});
 p.on('pageerror',e=>console.log('ERR',e.message));
 await p.goto('file:///tmp/vid/video.html');await p.waitForTimeout(600);
 const total=await p.evaluate(()=>TOTAL);const frames=Math.round(total*FPS);
 const ff=spawn('ffmpeg',['-y','-f','image2pipe','-framerate',String(FPS),'-vcodec','mjpeg','-i','-','-i','/tmp/vid/audio.wav','-c:v','libx264','-pix_fmt','yuv420p','-crf','19','-preset','medium','-r',String(FPS),'-c:a','aac','-b:a','192k','-shortest','-movflags','+faststart','/tmp/vid/bluebay_menus.mp4'],{stdio:['pipe','ignore','pipe']});
 let err='';ff.stderr.on('data',d=>err+=d);
 for(let f=0;f<frames;f++){
  await p.evaluate(t=>render(t),f/FPS);
  const buf=await p.screenshot({type:'jpeg',quality:92});
  if(!ff.stdin.write(buf)) await new Promise(r=>ff.stdin.once('drain',r));
  if(f%90===0){fs.writeFileSync('/tmp/vid/progress.txt',`${f}/${frames}`);}
 }
 ff.stdin.end();await new Promise(r=>ff.on('close',r));
 fs.writeFileSync('/tmp/vid/progress.txt','DONE '+frames);
 if(!fs.existsSync('/tmp/vid/bluebay_menus.mp4'))console.log(err.slice(-600));
 await b.close();
})();
