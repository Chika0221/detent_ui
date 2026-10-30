"""Capture actual Rive mechanisms and assemble a deterministic README preview.
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
        active=3<=frame<12
        release=frame>=12
        for artboard,prop,viewport in [('Button','pressed','432x126'),('Switch','selected','216x126')]:
            command=['rive',str(ROOT/'rive/detent'),f'--artboard={artboard}',f'--viewport={viewport}','--fit=contain']
            command+=['--advance=30']
            if active:
                command+=[f'--data={prop}=true',f'--advance={(frame-3)*5}']
            elif release:
                command+=[f'--data={prop}=true','--advance=30',f'--data={prop}=false',f'--advance={(frame-12)*5}']
            command+=[f'--screenshot={tmp}/{artboard}-{frame:02d}.png']
            result=subprocess.run(command,cwd=ROOT,capture_output=True,text=True)
            if result.returncode:raise RuntimeError(result.stderr+result.stdout)
        if (frame+1)%6==0:print(f'Rendered {frame+1}/24 frames',flush=True)
    font=ROOT/'assets/fonts/Manrope.ttf'
    filters=(f'[0:v][1:v]hstack=inputs=2,pad=iw:180:0:42:color=0xE5E6E3,'
        f'drawtext=fontfile={font}:text=BUTTON / PRESS:fontcolor=0x202426:fontsize=16:x=12:y=12,'
        f'drawtext=fontfile={font}:text=SWITCH / SELECT:fontcolor=0x202426:fontsize=16:x=444:y=12,'
        'split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a')
    subprocess.run(['ffmpeg','-y','-loglevel','error','-framerate','12','-i',str(tmp/'Button-%02d.png'),
        '-framerate','12','-i',str(tmp/'Switch-%02d.png'),'-filter_complex',filters,'-loop','0',str(TARGET)],check=True)
print(TARGET)
