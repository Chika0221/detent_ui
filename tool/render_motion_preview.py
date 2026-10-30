"""Capture processing-only Rive feedback for the README preview.
Requires the installed Rive CLI and ffmpeg. Does not publish or upload anything.
"""
import subprocess
import tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TARGET=ROOT/'example/screenshots/rive-motion.gif'
with tempfile.TemporaryDirectory(prefix='detent-motion-') as tmp:
    tmp=Path(tmp)
    for frame in range(24):
        for artboard,viewport in [('Progress','324x84'),('Meter','324x84'),('TaskStatus','324x84'),('Skeleton','324x84')]:
            command=['rive',str(ROOT/'rive/detent'),f'--artboard={artboard}',f'--viewport={viewport}','--fit=contain']
            command+=['--data=progress=0.68','--data=extent=163.2',
                '--data=indeterminate='+('false' if artboard=='Progress' else 'true'),
                '--data=taskState=1','--advance=1',f'--advance={frame*5+1}']
            command+=[f'--screenshot={tmp}/{artboard}-{frame:02d}.png']
            result=subprocess.run(command,cwd=ROOT,capture_output=True,text=True)
            if result.returncode:raise RuntimeError(result.stderr+result.stdout)
        if (frame+1)%6==0:print(f'Rendered {frame+1}/24 frames',flush=True)
    font=ROOT/'assets/fonts/Manrope.ttf'
    filters=(f'[0:v][1:v]hstack=inputs=2[top];[2:v][3:v]hstack=inputs=2[bottom];'
        f'[top][bottom]vstack=inputs=2,pad=iw:220:0:26:color=0xE5E6E3,'
        f'drawtext=fontfile={font}:text=PROGRESS:fontcolor=0x202426:fontsize=14:x=12:y=6,'
        f'drawtext=fontfile={font}:text=LIVE METER:fontcolor=0x202426:fontsize=14:x=336:y=6,'
        f'drawtext=fontfile={font}:text=TASK STATUS:fontcolor=0x202426:fontsize=14:x=12:y=198,'
        f'drawtext=fontfile={font}:text=SKELETON:fontcolor=0x202426:fontsize=14:x=336:y=198,'
        'split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a')
    inputs=[]
    for name in ['Progress','Meter','TaskStatus','Skeleton']:
        inputs+=['-framerate','12','-i',str(tmp/f'{name}-%02d.png')]
    subprocess.run(['ffmpeg','-y','-loglevel','error',*inputs,
        '-filter_complex',filters,'-loop','0',str(TARGET)],check=True)
print(TARGET)
