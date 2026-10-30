"""Author Detent's native Rive mechanisms; Flutter retains text and input.
Build: python3 tool/generate_rive.py && rive rive/detent --verify
"""
import json
import math
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, indent, tostring

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'rive/detent'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'rive.yaml').write_text('name: detent\nmain: Button\noutput:\n  dir: ../../assets/rive\n')
TOKENS = json.loads((ROOT / 'design_tokens.resolved.json').read_text())
def color(role):
    return 'FF' + ''.join(f'{round(x*255):02X}' for x in TOKENS['semantic.light.color.'+role]['$value']['components'])
COLORS = {k:color(v) for k,v in {'surfaceColor':'bg.raised','inkColor':'text.primary','accentColor':'action.primary',
    'borderColor':'border.control','displayColor':'bg.display','focusColor':'focus.ring','inverseColor':'text.inverse','lineColor':'border.subtle'}.items()}
BOOLS = ['pressed','selected','hovered','focused','enabled','indeterminate']
NUMBERS = ['value','secondaryValue','progress','motionScale','selectionState','taskState','width','height','centerX','centerY','position','secondaryPosition','extent','segmentWidth','trackWidth','activeStart','activeWidth']
ROOT_XML = Element('Rive', version='1', kind='fragment')
COUNTER = 0
MANIFEST = []
def uid():
    global COUNTER
    COUNTER += 1
    return f'0:{COUNTER}'
def el(parent, tag, **attributes):
    return SubElement(parent,tag,{k:str(v).lower() if isinstance(v,bool) else str(v) for k,v in attributes.items()})

class Board:
    def __init__(self,name,width,height):
        self.name,self.width,self.height=name,width,height
        self.vm,self.instance,self.machine_id,self.style=uid(),uid(),uid(),uid()
        self.props={key:uid() for key in BOOLS+NUMBERS+list(COLORS)}
        i=len(MANIFEST)
        self.node=el(ROOT_XML,'Artboard',id=uid(),name=name,width=width,height=height,x=(i%5)*340,y=(i//5)*140,
            styleId=self.style,viewModelId=self.vm,viewModelInstanceId=self.instance,defaultStateMachineId=self.machine_id)
        el(self.node,'LayoutComponentStyle',id=self.style,name='Artboard Style')
        # State machines precede timelines in the editor. Shapes may precede them.
        self.machine=el(self.node,'StateMachine',id=self.machine_id,name='Detent')
        self.animations=[]
        self.layers=0
        self.rest_id=uid()
        self.timeline(self.rest_id,'Rest',[])
        self.layer('Data binding',[(self.rest_id,None,None)])
        MANIFEST.append({'component':'Nui'+name,'artboard':name,'stateMachine':'Detent','viewModel':name,
            'properties':list(self.props),'fallback':'Flutter','source':'rive/detent/scene.rml'})
    def bind(self,node,key,prop,converter=None):
        attrs=dict(sourcePathIds=f'{self.vm}-{self.props[prop]}',propertyKey=key)
        if converter:attrs['converterId']=converter
        el(node,'DataBindContext',**attrs)
    def mapper(self,minimum,maximum,lo=0,hi=1):
        mid=uid();el(ROOT_XML,'DataConverterRangeMapper',id=mid,name=f'{self.name}Map{COUNTER}',
            minInput=lo,maxInput=hi,minOutput=minimum,maxOutput=maximum,clampLower=True,clampUpper=True)
        return mid
    def smooth(self,seconds=.16):
        mid=uid();node=el(ROOT_XML,'DataConverterInterpolator',id=mid,name=f'{self.name}Follow{COUNTER}',duration=seconds,interpolationType='cubic')
        el(node,'CubicEaseInterpolator',x1=.2,y1=0,x2=.2,y2=1)
        return mid
    def group(self,name,x=0,y=0):return el(self.node,'Node',id=uid(),name=name,x=x,y=y)
    def shape(self,name,x,y,width,height,role='surfaceColor',radius=6,ellipse=False,parent=None,stroke=None):
        node=el(parent if parent is not None else self.node,'Shape',id=uid(),name=name,x=x,y=y)
        path=el(node,'Ellipse' if ellipse else 'Rectangle',id=uid(),name='Geometry',width=width,height=height,
            **({} if ellipse else {'cornerRadiusTL':radius}))
        if stroke:
            paint=el(node,'Stroke',name='Outline',thickness=stroke,position='inside')
        else:paint=el(node,'Fill',name='Fill')
        paint_color=el(paint,'SolidColor',name='Color',colorValue=COLORS[role]);self.bind(paint_color,37,role)
        return node,path
    def line(self,name,points,role='inkColor',width=2,parent=None):
        node=el(parent if parent is not None else self.node,'Shape',id=uid(),name=name)
        path=el(node,'PointsPath',name='Path',isClosed=False)
        for x,y in points:el(path,'StraightVertex',x=x,y=y)
        stroke=el(node,'Stroke',name='Stroke',thickness=width)
        col=el(stroke,'SolidColor',name='Color',colorValue=COLORS[role]);self.bind(col,37,role)
        return node,stroke
    def timeline(self,aid,name,keys,duration=1,loop=False):
        an=el(self.node,'LinearAnimation',id=aid,name=name,duration=duration,loopValue='loop' if loop else 'oneShot')
        for obj,prop,frames in keys:
            keyed=el(an,'KeyedObject',objectId=obj.get('id'));kp=el(keyed,'KeyedProperty',property=prop)
            for frame,value in frames:el(kp,'KeyFrameDouble',frame=frame,value=value,interpolationType='linear')
        self.animations.append(name)
    def layer(self,name,states,transition=120):
        # States are (animationId, property, expected literal). All peer transitions
        # are conditional, so running loops cannot re-enter themselves every frame.
        layer=el(self.machine,'StateMachineLayer',id=uid(),name=name)
        ids=[uid() for _ in states]
        ent=el(layer,'EntryState',x=0,y=0);el(ent,'StateTransition',stateToId=ids[0])
        el(layer,'AnyState',x=180,y=-160);el(layer,'ExitState',x=400,y=-160)
        for i,(aid,_,_) in enumerate(states):
            state=el(layer,'AnimationState',id=ids[i],animationId=aid,x=180+(i%3)*220,y=(i//3)*180,reset=True)
            for j,(_,prop,value) in enumerate(states):
                if j==i or prop is None:continue
                tr=el(state,'StateTransition',stateToId=ids[j],duration=120 if prop=='pressed' and value is False else transition,enableEarlyExit=True,interpolationType='cubic')
                el(tr,'CubicEaseInterpolator',x1=.2,y1=0,x2=.2,y2=1)
                cond=el(tr,'TransitionViewModelCondition',opValue='equal')
                comparator=el(cond,'TransitionPropertyViewModelComparator')
                boolean=isinstance(value,bool)
                bindable=el(comparator,'BindablePropertyBoolean' if boolean else 'BindablePropertyNumber')
                self.bind(bindable,634 if boolean else 636,prop)
                el(cond,'TransitionValueBooleanComparator' if boolean else 'TransitionValueNumberComparator',value=value)
        self.layers+=1
    def toggle(self,name,prop,keys,transition=120):
        off,on=uid(),uid()
        self.timeline(off,name+' off',[(obj,key,[(0,a)]) for obj,key,a,b in keys])
        self.timeline(on,name+' on',[(obj,key,[(0,b)]) for obj,key,a,b in keys])
        self.layer(name,[(off,prop,False),(on,prop,True)],transition)
    def finish(self):
        v=el(ROOT_XML,'ViewModel',id=self.vm,name=self.name,defaultInstanceId=self.instance)
        for prop,pid in self.props.items():
            typ='Color' if prop in COLORS else 'Boolean' if prop in BOOLS else 'Number'
            el(v,'ViewModelProperty'+typ,id=pid,name=prop)
        vi=el(v,'ViewModelInstance',id=self.instance,name='Default',exports=True)
        defaults={'width':self.width,'height':self.height,'centerX':self.width/2,'centerY':self.height/2,
            'value':.68,'secondaryValue':.8,'progress':.68,'motionScale':1,'position':24+.68*(self.width-48),
            'secondaryPosition':24+.8*(self.width-48),'extent':.68*self.width,'segmentWidth':self.width/3-8,'trackWidth':max(0,self.width-48),'activeStart':24,'activeWidth':max(0,self.width-48)*.68}
        for prop,pid in self.props.items():
            typ='Color' if prop in COLORS else 'Boolean' if prop in BOOLS else 'Number'
            value=COLORS[prop] if prop in COLORS else prop=='enabled' if prop in BOOLS else defaults.get(prop,0)
            el(vi,'ViewModelInstance'+typ,viewModelPropertyId=pid,propertyValue=value)
        MANIFEST[-1]['animations']=self.animations

for name,width,height in [('Button',144,42),('FlatButton',144,42),('IconButton',40,42),('ToggleButton',48,42),('Keycap',40,34)]:
    b=Board(name,width,height)
    face,path=b.shape('Operation face',0,0,width,height-2)
    path.set('originX','0');path.set('originY','0')
    b.bind(path,20,'width');b.bind(path,21,'height',b.mapper(-2,998,0,1000))
    b.toggle('Press','pressed',[(face,'y',0,2)],60)
    if name!='FlatButton':
        outline,outlinepath=b.shape('Control outline',0,0,width,height-2,'borderColor',stroke=1)
        outlinepath.set('originX','0');outlinepath.set('originY','0')
        b.bind(outlinepath,20,'width');b.bind(outlinepath,21,'height',b.mapper(-2,998,0,1000))
        b.node.remove(outline);b.node.insert(1,outline)
        b.toggle('Outline press','pressed',[(outline,'y',0,2)],60)
    # A restrained edge glow, rather than a scale that moves neighbouring controls.
    edge,edgepath=b.shape('Hover edge',0,0,width,height-2,'accentColor',stroke=1)
    edgepath.set('originX','0');edgepath.set('originY','0');b.bind(edgepath,20,'width');b.bind(edgepath,21,'height',b.mapper(-2,998,0,1000))
    # Earlier shapes draw on top; insert edge before the face.
    b.node.remove(edge);b.node.insert(1,edge)
    b.toggle('Hover','hovered',[(edge,'opacity',0,.5)],90)
    b.toggle('Edge press','pressed',[(edge,'y',0,2)],60)
    if name!='FlatButton':
        base,basepath=b.shape('Physical base',0,2,width,height-2,'borderColor')
        basepath.set('originX','0');basepath.set('originY','0');b.bind(basepath,20,'width');b.bind(basepath,21,'height',b.mapper(-2,998,0,1000))
    b.finish()

for name in ['Checkbox','RadioGroup','Switch']:
    b=Board(name,48 if name=='Switch' else 24,28 if name=='Switch' else 24)
    if name=='Switch':
        thumb,_=b.shape('Sliding thumb',13,14,20,20,'inkColor',ellipse=True)
        b.toggle('Selection','selected',[(thumb,'x',13,35)],160)
        b.toggle('Press feedback','pressed',[(thumb,'scaleX',1,.9),(thumb,'scaleY',1,.9)],60)
        b.shape('Track outline',24,14,48,26,'borderColor',radius=13,stroke=1)
        b.shape('Track',24,14,48,26,'surfaceColor',radius=13)
    elif name=='Checkbox':
        check,_=b.line('Check',[(6,12),(10,16),(18,8)],'inverseColor',2)
        mixed,_=b.line('Mixed',[(6,12),(18,12)],'inverseColor',2)
        fill,_=b.shape('Selected face',12,12,20,20,'inkColor',radius=3)
        b.toggle('Selection','selected',[(check,'opacity',0,1),(check,'scaleX',.7,1),(check,'scaleY',.7,1),(fill,'opacity',0,1)],120)
        # selectionState 2 is explicitly mixed, independent of checked.
        off,on=uid(),uid();b.timeline(off,'Mixed hidden',[(mixed,'opacity',[(0,0)])]);b.timeline(on,'Mixed visible',[(mixed,'opacity',[(0,1)]),(check,'opacity',[(0,0)])])
        b.layer('Mixed state',[(off,'selectionState',0),(off,'selectionState',1),(on,'selectionState',2)],120)
        b.shape('Control outline',12,12,20,20,'borderColor',radius=4,stroke=1)
    else:
        dot,_=b.shape('Selected dot',12,12,10,10,'inkColor',ellipse=True)
        b.toggle('Selection','selected',[(dot,'opacity',0,1),(dot,'scaleX',.6,1),(dot,'scaleY',.6,1)],160)
        b.shape('Control outline',12,12,20,20,'borderColor',ellipse=True,stroke=1)
    b.finish()

for name in ['SegmentedControl','Tabs']:
    b=Board(name,288,40)
    selection,path=b.shape('Travelling selection',48,20,88,32,'accentColor')
    b.bind(selection,13,'position',b.smooth(.16));b.bind(selection,14,'centerY')
    b.bind(path,20,'segmentWidth');b.bind(path,21,'height',b.mapper(-10,990,0,1000))
    if name=='SegmentedControl':
        outline,outlinepath=b.shape('Selection outline',48,20,88,32,'borderColor',stroke=1)
        b.bind(outline,13,'position',b.smooth(.16));b.bind(outline,14,'centerY')
        b.bind(outlinepath,20,'segmentWidth');b.bind(outlinepath,21,'height',b.mapper(-10,990,0,1000))
        base,basepath=b.shape('Selection base',48,22,88,32,'borderColor')
        b.bind(base,13,'position',b.smooth(.16));b.bind(base,14,'centerY',b.mapper(2,1002,0,1000))
        b.bind(basepath,20,'segmentWidth');b.bind(basepath,21,'height',b.mapper(-10,990,0,1000))
    if name=='Tabs':
        path.set('height','2');path.set('originY','1')
    b.finish()

b=Board('TabIndicator',120,2)
underline,_=b.shape('Selection underline',60,1,120,2,'accentColor',radius=0)
b.toggle('Selection','selected',[(underline,'scaleX',0,1),(underline,'opacity',0,1)],160)
b.finish()

for name in ['Slider','RangeSlider']:
    b=Board(name,240,64)
    for i,prop in enumerate(['position','secondaryPosition'] if name=='RangeSlider' else ['position']):
        thumb,path=b.shape('Thumb'+str(i),24,32,18,24,'surfaceColor',radius=4)
        b.bind(thumb,13,prop);b.bind(thumb,14,'centerY')
        border,_=b.shape('Thumb outline'+str(i),24,32,18,24,'borderColor',radius=4,stroke=1)
        b.bind(border,13,prop);b.bind(border,14,'centerY')
        b.toggle('Thumb press'+str(i),'pressed',[(thumb,'scaleY',1,.9),(border,'scaleY',1,.9)],60)
    active,path=b.shape('Active track',24,32,130,5,'inkColor',radius=2);path.set('originX','0')
    b.bind(active,13,'activeStart');b.bind(active,14,'centerY');b.bind(path,20,'activeWidth')
    track,path=b.shape('Track',24,32,192,5,'lineColor',radius=2);path.set('originX','0');b.bind(path,20,'trackWidth');b.bind(track,14,'centerY')
    for j in range(21):
        tick,_=b.shape('Tick'+str(j),24+j*192/20,52,1,8 if j%5==0 else 4,'borderColor',radius=0)
        b.bind(tick,13,'width',b.mapper(24-48*j/20,24-48*j/20+1000*j/20,0,1000))
        b.bind(tick,14,'centerY',b.mapper(20,1020,0,1000))
    b.finish()

b=Board('RotaryKnob',96,96)
marker,_=b.shape('Value pointer',48,48,5,5,'inkColor',ellipse=True)
marker.find('Ellipse').set('y','-30');b.bind(marker,15,'value',b.mapper(-math.pi*.75,math.pi*.75))
b.toggle('Grab','pressed',[(marker,'scaleX',1,1.2),(marker,'scaleY',1,1.2)],60)
for j in range(31):
    a=math.pi*.75+j/30*math.pi*1.5
    b.shape('Tick'+str(j),48+math.cos(a)*44,48+math.sin(a)*44,1,2,'borderColor',radius=0)
b.shape('Inner ring',48,48,60,60,'borderColor',ellipse=True,stroke=1)
b.shape('Face',48,48,72,72,'surfaceColor',ellipse=True)
b.shape('Base',48,50,76,76,'borderColor',ellipse=True);b.finish()

b=Board('Progress',240,4)
fill,path=b.shape('Measured progress',0,2,160,4,'inkColor',radius=1);path.set('originX','0');b.bind(path,20,'extent')
band,_=b.shape('Indeterminate band',-64,2,64,4,'inkColor',radius=1)
rest,run=uid(),uid();b.timeline(rest,'Measured',[(fill,'opacity',[(0,1)]),(band,'opacity',[(0,0)])])
b.timeline(run,'Indeterminate',[(fill,'opacity',[(0,0)]),(band,'opacity',[(0,1)]),(band,'x',[(0,-64),(72,304)])],72,True)
b.layer('Progress mode',[(rest,'indeterminate',False),(run,'indeterminate',True)],0)
b.shape('Track',120,2,240,4,'borderColor',radius=1);b.finish()

for name in ['CircularProgress','Spinner']:
    b=Board(name,32,32)
    arc,path=b.shape('Arc',16,16,26,26,'inkColor',ellipse=True,stroke=2)
    trim=el(arc.find('Stroke'),'TrimPath',id=uid(),name='Progress',start=0,end=.25)
    b.bind(trim,115,'progress')
    rest,run=uid(),uid();b.timeline(rest,'Measured',[(arc,'rotation',[(0,0)])])
    b.timeline(run,'Rotate',[(arc,'rotation',[(0,0),(72,math.tau)])],72,True)
    b.layer('Activity',[(rest,'indeterminate',False),(run,'indeterminate',True)],0);b.finish()

for name in ['Meter','TaskStatus']:
    b=Board(name,240,40)
    count=32 if name=='Meter' else 40
    for j in range(count):
        segment,_=b.shape('Segment'+str(j),(j+.5)*240/count,20,240/count-2,32,'accentColor',radius=0)
        # Only data changes animate; the meter never invents activity at rest.
        b.bind(segment,18,'progress',b.mapper(.16,1,j/count,(j+1)/count))
    b.finish()

b=Board('TaskGlyph',32,32)
idle,_=b.shape('Idle',16,16,10,10,'borderColor',ellipse=True,stroke=2)
success,stroke=b.line('Success',[(7,16),(13,22),(26,8)],'accentColor',2)
error,_=b.line('Error',[(9,9),(23,23)],'accentColor',2)
error2,_=b.line('Error other',[(23,9),(9,23)],'accentColor',2)
cancel,_=b.line('Canceled',[(7,16),(25,16)],'borderColor',2)
activity=b.group('Activity',16,16)
for j in range(8):
    a=j/8*math.tau
    b.shape('Activity tick'+str(j),math.cos(a)*11,math.sin(a)*11,2,5,'accentColor',radius=1,parent=activity)
objects=[idle,activity,success,error,error2,cancel]
states=[]
for state,label in enumerate(['Idle','Running','Success','Error','Canceled','Canceling']):
    aid=uid();active=[idle] if state==0 else [activity] if state in [1,5] else [success] if state==2 else [error,error2] if state==3 else [cancel]
    keys=[(o,'opacity',[(0,1 if o in active else 0)]) for o in objects]
    if state in [1,5]:keys.append((activity,'rotation',[(0,0),(72,math.tau)]))
    if state in [2,3,4]:
        for o in active:keys.extend([(o,'scaleX',[(0,.7),(12,1)]),(o,'scaleY',[(0,.7),(12,1)])])
    b.timeline(aid,label,keys,72 if state in [1,5] else 12,state in [1,5]);states.append((aid,'taskState',state))
b.layer('Task lifecycle',states,80);b.finish()

b=Board('Chevron',24,24)
chevron,_=b.line('Chevron path',[(-3,-6),(3,0),(-3,6)],'inkColor',1.5)
chevron.set('x','12');chevron.set('y','12')
b.toggle('Expand','selected',[(chevron,'rotation',0,math.pi/2)],120)
b.finish()

b=Board('Skeleton',240,12)
band,_=b.shape('Loading sweep',-60,6,60,12,'surfaceColor',radius=2)
rest,run=uid(),uid();b.timeline(rest,'Static',[(band,'opacity',[(0,0)])])
b.timeline(run,'Loading',[(band,'opacity',[(0,.35)]),(band,'x',[(0,-60),(90,300)])],90,True)
b.layer('Loading policy',[(rest,'indeterminate',False),(run,'indeterminate',True)],0)
b.shape('Placeholder',120,6,240,12,'borderColor',radius=2);b.finish()

b=Board('EmptyState',48,48)
lid,_=b.line('Tray rim',[(8,25),(17,25),(20,30),(28,30),(31,25),(40,25)],'inkColor',2)
b.line('Tray base',[(8,25),(8,38),(40,38),(40,25)],'inkColor',2)
b.line('Tray sides',[(8,25),(13,12),(35,12),(40,25)],'borderColor',2)
aid=uid();b.timeline(aid,'Arrive',[(lid,'y',[(0,-4),(13,0)]),(lid,'opacity',[(0,.2),(13,1)])],13)
b.layer('First appearance',[(aid,None,None)]);b.finish()

# Numeric glyphs are separate artboards, so variable text is never a fixed 68%.
GLYPHS={
'0':['01110','10001','10011','10101','11001','10001','01110'],
'1':['00100','01100','00100','00100','00100','00100','01110'],
'2':['01110','10001','00001','00010','00100','01000','11111'],
'3':['11110','00001','00001','01110','00001','00001','11110'],
'4':['00010','00110','01010','10010','11111','00010','00010'],
'5':['11111','10000','10000','11110','00001','00001','11110'],
'6':['01110','10000','10000','11110','10001','10001','01110'],
'7':['11111','00001','00010','00100','01000','01000','01000'],
'8':['01110','10001','10001','01110','10001','10001','01110'],
'9':['01110','10001','10001','01111','00001','00001','01110'],
'Percent':['11001','11010','00010','00100','01000','01011','10011'],
'Dot':['00000','00000','00000','00000','00000','00110','00110'],
'Colon':['00000','00100','00100','00000','00100','00100','00000'],
'Minus':['00000','00000','00000','11111','00000','00000','00000'],
'Space':['00000']*7}
for name,grid in GLYPHS.items():
    b=Board('Digit'+name,28.8,33.6)
    node=b.group('Glyph')
    for y,row in enumerate(grid):
        for x,filled in enumerate(row):
            if filled=='1':b.shape(f'Dot{x}_{y}',(x+.5)*4.8,(y+.5)*4.8,3,3,'inkColor',ellipse=True,parent=node)
    aid=uid();b.timeline(aid,'Reveal',[(node,'opacity',[(0,.15),(10,1)])],10);b.layer('Arrival',[(aid,None,None)])
    b.finish()

# Retain the original preview artboard name, with a truthful manifest note.
b=Board('DotMatrix',28.8,33.6)
for y,row in enumerate(GLYPHS['8']):
    for x,filled in enumerate(row):
        if filled=='1':b.shape(f'Dot{x}_{y}',(x+.5)*4.8,(y+.5)*4.8,3,3,'inkColor',ellipse=True)
b.finish();MANIFEST[-1]['usage']='Standalone numeral preview; NuiDotMatrix composes Digit* artboards.'
indent(ROOT_XML,space='  ')
(OUT/'scene.rml').write_text(tostring(ROOT_XML,encoding='unicode')+'\n')
(ROOT/'assets/rive/manifest.json').write_text(json.dumps({'version':2,'cli':'1.8.0','scripts':False,
    'license':'Project-owned geometric artwork','skins':MANIFEST},indent=2)+'\n')
print(f'Generated {len(MANIFEST)} artboards with state-driven mechanisms and numeric glyphs.')
