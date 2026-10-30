"""Build editable, script-free RML skins from Detent's canonical tokens."""
import json, math
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement as E, indent, tostring
root=Path(__file__).resolve().parents[1]
out=root/'rive/detent'
out.mkdir(parents=True,exist_ok=True)
(out/'rive.yaml').write_text('name: detent\nmain: Button\noutput:\n  dir: ../../assets/rive\n')
tokens=json.loads((root/'design_tokens.resolved.json').read_text())
def color(role):
 v=tokens['semantic.light.color.'+role]['$value'];return 'FF'+''.join(f'{round(x*255):02X}' for x in v['components'])
colors={'surfaceColor':color('bg.raised'),'inkColor':color('text.primary'),'accentColor':color('action.primary'),'borderColor':color('border.control'),'displayColor':color('bg.display')}
r=Element('Rive',version='1',kind='fragment');counter=0
def uid():
 global counter
 counter+=1;return f'0:{counter}'
def el(p,tag,**kw):return E(p,tag,{k:str(v).lower() if isinstance(v,bool) else str(v) for k,v in kw.items()})
manifest=[]
components={'Button':(144,50),'IconButton':(40,50),'ToggleButton':(48,50),'Keycap':(40,42),
 'SegmentedControl':(288,40),'Checkbox':(24,24),'RadioGroup':(24,24),'Switch':(48,28),
 'Slider':(240,40),'RangeSlider':(240,40),'RotaryKnob':(96,96),'Tabs':(240,40),
 'Progress':(240,8),'DotMatrix':(160,56),'Meter':(240,56),'TaskStatus':(240,64)}
for i,(name,(w,h)) in enumerate(components.items()):
 aid,style,vm,inst,sm,layer=[uid() for _ in range(6)]
 props={k:uid() for k in ['pressed','selected','hovered','focused','enabled','value','secondaryValue','progress','motionScale',*colors]}
 a=el(r,'Artboard',id=aid,name=name,width=w,height=h,x=(i%4)*340,y=(i//4)*150,styleId=style,viewModelId=vm,viewModelInstanceId=inst,defaultStateMachineId=sm)
 el(a,'LayoutComponentStyle',id=style,name='Artboard Style')
 def bind(node,key,prop,converter=None):
  kw=dict(sourcePathIds=f'{vm}-{props[prop]}',propertyKey=key)
  if converter:kw['converterId']=converter
  el(node,'DataBindContext',**kw)
 def mapper(lo,hi):
  mid=uid();el(r,'DataConverterRangeMapper',id=mid,name=f'{name}Range{counter}',minInput=0,maxInput=1,minOutput=lo,maxOutput=hi,clampLower=True,clampUpper=True);return mid
 def shape(n,x,y,sw,sh,role='surfaceColor',rounding=6,kind='Rectangle',binding=None):
  sid=uid();s=el(a,'Shape',id=sid,name=n,x=x,y=y)
  path=el(s,kind,name='Path',width=sw,height=sh,**({'cornerRadiusTL':rounding} if kind=='Rectangle' else {}))
  if binding: bind(path,20,binding,mapper(0,sw))
  f=el(s,'Fill',name='Fill');c=el(f,'SolidColor',name='Color',colorValue=colors[role]);bind(c,37,role)
  return s,path
 moving=None;selectedObj=None;selectedProp='x';off=0;on=0
 if name in ['Button','IconButton','ToggleButton','Keycap']:
  s,_=shape('Operation face',w/2,(h-10)/2+4,w-8,h-10,'accentColor' if name in ['Button','ToggleButton'] else 'surfaceColor');moving=s
  shape('Physical base',w/2,(h-10)/2+6,w-8,h-10,'borderColor')
 elif name in ['Switch','Checkbox','RadioGroup']:
  if name=='Switch':
   selectedObj,_=shape('Thumb',13,h/2,16,16,'accentColor',kind='Ellipse');off=13;on=35
   shape('Track',w/2,h/2,w-4,22,'inkColor',rounding=11)
  elif name=='Checkbox':
   selectedObj,_=shape('Check',12,12,10,10,'inkColor',rounding=1);selectedProp='opacity';off=0;on=1
   shape('Box',12,12,20,20,'surfaceColor',rounding=2)
  else:
   selectedObj,_=shape('Selected',12,12,10,10,'inkColor',kind='Ellipse');selectedProp='opacity';off=0;on=1
   shape('Ring',12,12,20,20,'borderColor',kind='Ellipse')
 elif name in ['SegmentedControl','Tabs']:
  selectedObj,_=shape('Selection',w/6,h/2,w/3-8,h-8,'accentColor');off=w/6;on=w*5/6
  shape('Track',w/2,h/2,w,h,'borderColor')
 elif name in ['Slider','RangeSlider']:
  thumb,_=shape('Thumb',16,20,12,20,'surfaceColor',rounding=3);bind(thumb,13,'value',mapper(16,w-16))
  if name=='RangeSlider':
   thumb2,_=shape('Upper thumb',w-16,20,12,20,'surfaceColor',rounding=3);bind(thumb2,13,'secondaryValue',mapper(16,w-16))
  shape('Track',w/2,20,w-24,3,'borderColor',rounding=1)
 elif name=='RotaryKnob':
  for j in range(31):
   angle=math.pi*.75+j/30*math.pi*1.5
   shape('Tick'+str(j),48+math.cos(angle)*44,48+math.sin(angle)*44,1,2,'borderColor',rounding=0)
  marker,_=shape('Pointer',48,48,5,5,'inkColor',kind='Ellipse')
  # Rotate the offset path around the dial's centre.
  marker.find('Ellipse').set('y','-30');bind(marker,15,'value',mapper(-math.pi*.75,math.pi*.75))
  shape('Face',48,48,72,72,'surfaceColor',kind='Ellipse')
  shape('Base',48,50,76,76,'borderColor',kind='Ellipse')
 elif name=='Progress':
  s,path=shape('Progress',0,4,w,4,'inkColor',binding='progress');path.set('originX','0')
  shape('Track',w/2,4,w,4,'borderColor')
 elif name in ['Meter','TaskStatus']:
  for j in range(40):
   s,_=shape('Segment'+str(j),8+j*5.6,20,2,24 if name=='Meter' else 12,'accentColor',rounding=0)
   # Opacity is a clamped continuous threshold, driven by real progress.
   mid=uid();el(r,'DataConverterRangeMapper',id=mid,name=f'Threshold{i}_{j}',minInput=j/40,maxInput=(j+1)/40,minOutput=.15,maxOutput=1,clampLower=True,clampUpper=True)
   bind(s,18,'progress',mid)
  shape('Display',w/2,h/2,w,h,'displayColor')
 else:
  # 5x7 glyphs have independent editable shapes. Flutter provides the text value.
  glyph=['01110','10001','10000','11110','10001','10001','01110']
  for j,ch in enumerate(['6','8','%']):
   grid=glyph if ch=='6' else ['01110','10001','10001','01110','10001','10001','01110'] if ch=='8' else ['11001','11010','00010','00100','01000','01011','10011']
   for y,row in enumerate(grid):
    for x,v in enumerate(row):
     if v=='1':shape(f'Dot{j}_{x}_{y}',12+j*44+x*6,8+y*6,2,2,'surfaceColor',kind='Ellipse')
  shape('Display',w/2,h/2,w,h,'displayColor')
 machine=el(a,'StateMachine',id=sm,name='Detent')
 l=el(machine,'StateMachineLayer',id=layer,name='Mechanism')
 idle,active,ia,aa=[uid() for _ in range(4)]
 en=el(l,'EntryState',x=0,y=0);el(en,'StateTransition',stateToId=idle)
 el(l,'AnyState',x=160,y=-120);el(l,'ExitState',x=360,y=-120)
 for state,anim,x,expected,target in [(idle,ia,160,True,active),(active,aa,360,False,idle)]:
  st=el(l,'AnimationState',id=state,animationId=anim,x=x,y=0)
  tr=el(st,'StateTransition',stateToId=target,duration=120)
  cond=el(tr,'TransitionViewModelCondition',opValue='equal')
  comp=el(cond,'TransitionPropertyViewModelComparator');bp=el(comp,'BindablePropertyBoolean');bind(bp,634,'selected' if selectedObj is not None else 'pressed')
  el(cond,'TransitionValueBooleanComparator',value=expected)
 for anim,n,amount in [(ia,'Rest',0),(aa,'Active',1)]:
  an=el(a,'LinearAnimation',id=anim,name=n,duration=1)
  if moving is not None:
   obj=el(an,'KeyedObject',objectId=moving.get('id'));kp=el(obj,'KeyedProperty',property='y');el(kp,'KeyFrameDouble',value=(h-10)/2+4+amount*2)
  if selectedObj is not None:
   obj=el(an,'KeyedObject',objectId=selectedObj.get('id'));kp=el(obj,'KeyedProperty',property=selectedProp);el(kp,'KeyFrameDouble',value=on if amount else off)
 v=el(r,'ViewModel',id=vm,name=name,defaultInstanceId=inst)
 for prop,pid in props.items():
  typ='Color' if prop in colors else 'Number' if prop in ['value','secondaryValue','progress','motionScale'] else 'Boolean'
  el(v,'ViewModelProperty'+typ,id=pid,name=prop)
 vi=el(v,'ViewModelInstance',id=inst,name='Default',exports=True)
 for prop,pid in props.items():
  typ='Color' if prop in colors else 'Number' if prop in ['value','secondaryValue','progress','motionScale'] else 'Boolean'
  val=colors[prop] if prop in colors else .68 if prop in ['value','progress'] else 1 if prop in ['secondaryValue','motionScale'] else prop=='enabled'
  el(vi,'ViewModelInstance'+typ,viewModelPropertyId=pid,propertyValue=val)
 manifest.append({'component':'Nui'+name,'artboard':name,'stateMachine':'Detent','viewModel':name,'properties':list(props),'fallback':'Flutter','source':'rive/detent/scene.rml'})
indent(r,space='  ')
(out/'scene.rml').write_text(tostring(r,encoding='unicode')+'\n')
(root/'assets/rive').mkdir(parents=True,exist_ok=True)
(root/'assets/rive/manifest.json').write_text(json.dumps({'version':1,'cli':'1.8.0','scripts':False,'license':'Project-owned geometric artwork','skins':manifest},indent=2)+'\n')
print(f'Generated {len(manifest)} editable artboards.')
