"""Author processing-only Rive displays; interactive controls use Flutter motion.
Build: python3 tool/generate_rive.py && rive rive/detent --verify
"""
import json
import math
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, indent, tostring

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'rive/detent'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'rive.yaml').write_text('name: detent\nmain: Progress\noutput:\n  dir: ../../assets/rive\n')
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

b=Board('Progress',240,4)
shine,path=b.shape('Measured activity',0,2,160,4,'inverseColor',radius=1);path.set('originX','0');b.bind(path,20,'extent')
a,busy=uid(),uid();b.timeline(a,'Measured still',[(shine,'opacity',[(0,0)])])
b.timeline(busy,'Measured pulse',[(shine,'opacity',[(0,0),(60,.16),(120,0)])],120,True)
b.layer('Measured activity',[(a,'taskState',0),(busy,'taskState',1)],0)
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

b=Board('Meter',240,40)
shine,path=b.shape('Live sheen',0,20,160,32,'inverseColor',radius=0);path.set('originX','0');b.bind(path,20,'extent')
a,busy=uid(),uid();b.timeline(a,'Meter still',[(shine,'opacity',[(0,0)])])
b.timeline(busy,'Meter live',[(shine,'opacity',[(0,0),(48,.14),(96,0)])],96,True)
b.layer('Live signal',[(a,'indeterminate',False),(busy,'indeterminate',True)],0)
for j in range(32):
    segment,_=b.shape('Segment'+str(j),(j+.5)*240/32,20,240/32-2,32,'accentColor',radius=0)
    b.bind(segment,18,'progress',b.mapper(.16,1,j/32,(j+1)/32))
b.finish()

b=Board('TaskStatus',56,28)
dots=[]
for j in range(32):
    mask=b.group('Measured dot mask'+str(j));b.bind(mask,18,'progress',b.mapper(.18,1,j/32,(j+1)/32))
    dot,_=b.shape('Dot'+str(j),3.5+(j%8)*7,3.5+(j//8)*7,3,3,'accentColor',ellipse=True,parent=mask)
    dots.append(dot)
a,busy=uid(),uid();b.timeline(a,'Task still',[(dot,'opacity',[(0,1)]) for dot in dots])
b.timeline(busy,'Task wave',[(dot,'opacity',[(0,.35),(j%8*6,.35),(j%8*6+18,1),(j%8*6+36,.35),(96,.35)]) for j,dot in enumerate(dots)],96,True)
b.layer('Processing only',[(a,'indeterminate',False),(busy,'indeterminate',True)],0);b.finish()

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

b=Board('Skeleton',240,12)
band,_=b.shape('Loading sweep',-60,6,60,12,'surfaceColor',radius=2)
rest,run=uid(),uid();b.timeline(rest,'Static',[(band,'opacity',[(0,0)])])
b.timeline(run,'Loading',[(band,'opacity',[(0,.35)]),(band,'x',[(0,-60),(90,300)])],90,True)
b.layer('Loading policy',[(rest,'indeterminate',False),(run,'indeterminate',True)],0)
b.shape('Placeholder',120,6,240,12,'borderColor',radius=2);b.finish()

indent(ROOT_XML,space='  ')
(OUT/'scene.rml').write_text(tostring(ROOT_XML,encoding='unicode')+'\n')
(ROOT/'assets/rive/manifest.json').write_text(json.dumps({'version':2,'cli':'1.8.0','scripts':False,
    'license':'Project-owned geometric artwork','skins':MANIFEST},indent=2)+'\n')
print(f'Generated {len(MANIFEST)} artboards with state-driven mechanisms and numeric glyphs.')
