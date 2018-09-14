class UIDMXControls extends UICollapsibleSection implements LXParameterListener
{
   private final DiscreteParameter P_CurrentBloomIndex = (DiscreteParameter)
     new DiscreteParameter("Index", 0, 0, 42)
     .addListener(this);
   
   private final BooleanParameter P_SendDoHome = (BooleanParameter)
     new BooleanParameter("Do Home", false)
     .addListener(this);
   
   private final BooleanParameter P_SendSetMaxPulses = (BooleanParameter)
     new BooleanParameter("Set Max Pulses", false)
     .addListener(this);
     
   public UIDMXControls (
     UI _UI,
     float _PanelWidth
     )
   {
       super(_UI, 0, 0, _PanelWidth, 0); 
       
       setLayout(UI2dContainer.Layout.VERTICAL);
       setChildMargin(2, 0);
       
       setTitle("DMX Commands");
       
       new UIIntegerBox(UI_PADDING, UI_PADDING, 32, 32)
         .setParameter(P_CurrentBloomIndex)
         .addToContainer(this);
         
       new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("Set Max Pulses")
            .addToContainer(this);
        
        new UIButton(12, UI_PADDING, 16, 16)
            .setParameter(P_SendSetMaxPulses)
            .addToContainer(this);
        
        new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("Go Home")
            .addToContainer(this);
        
        new UIButton(12, UI_PADDING, 16, 16)
            .setParameter(P_SendDoHome)
            .addToContainer(this);
       
   }
   
   void onParameterChanged(LXParameter parameter)
    {
        if (parameter == P_CurrentBloomIndex)
        {
            
        }
        else if (parameter == P_SendSetMaxPulses && P_SendSetMaxPulses.getValueb())
        {
           for (int i = 0; i < RadiaNodeDatagrams.length; i++)
           {
               if (RadiaNodeDatagrams[i] != null && RadiaNodeDatagrams[i].BloomId == P_CurrentBloomIndex.getValuei())
               {
                   println("Sending Max Pulses For Node " + P_CurrentBloomIndex.getValuei());
                   RadiaNodeDatagrams[i].setSendMaxPulses();
                   P_SendSetMaxPulses.setValue(false);
               }
           }
        }
        else if (parameter == P_SendDoHome && P_SendDoHome.getValueb())
        {
           
           for (int i = 0; i < RadiaNodeDatagrams.length; i++)
           {
               if (RadiaNodeDatagrams[i] != null && RadiaNodeDatagrams[i].BloomId == P_CurrentBloomIndex.getValuei())
               {
                 println("Homing " + P_CurrentBloomIndex.getValuei());
                   RadiaNodeDatagrams[i].doHome();
                   P_SendDoHome.setValue(false);
                   break;
               }
           
           }
        }
    }
}

// Displays information about the ProjectController Object
class UIProjectControls extends UICollapsibleSection implements LXParameterListener, LX.ProjectListener
{
    ProjectController Controller;
    
    private final BooleanParameter Enabled = (BooleanParameter) 
        new BooleanParameter("Enabled", false)
        .addListener((LXParameterListener)this);
    
    private UILabel NextSceneTime;
    
    public UIProjectControls(
        UI _UI, 
        float _PanelWidth,
        ProjectController _Controller)
    {
        super(_UI, 0, 0, _PanelWidth, 0);
        Controller = _Controller;
        
        setLayout(UI2dContainer.Layout.VERTICAL);
        setChildMargin(2,0);
        
        setTitle("PROJECT MODULATOR");
        
        new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("Enabled")
            .addToContainer(this);
        
        new UIButton(12, UI_PADDING, 16, 16)
            .setParameter(Enabled)
            .addToContainer(this);
        
        new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("Change At")
            .addToContainer(this);
        
        NextSceneTime = (UILabel)
            new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("00:00p")
            .addToContainer(this);
        
    }
    
    void onParameterChanged(LXParameter parameter)
    {
        if (parameter == Enabled)
        {
            println("Enabled: " + Enabled.getValueb());
            if (Enabled.getValueb())
            {
                Controller.Reset();
                lx.engine.addLoopTask((LXLoopTask)Controller);
            }
            else
            {
                lx.engine.removeLoopTask((LXLoopTask)Controller);
            }
        }
    }
    
    void projectChanged(
        File project, 
        LX.ProjectListener.Change change
        )
    {
        println("projectChanged() : " + change);
        if (change == LX.ProjectListener.Change.OPEN)
        {
            println("Setting next scene time");
            try {
                NextSceneTime.setLabel(Controller.GetNextSceneTimeString());
            }
            catch (Exception e) {
                println("No GetNextSceneTimeString");
            }
        }
    }
}


/*
// NOTE (Trip) : Might be unnecessary - just realized the "Live" button on Master Channel disables outputs when off
class UIOutputControls extends UICollapsibleSection implements LXParameterListener
{
   
    private final BooleanParameter Enabled = (BooleanParameter) 
        new BooleanParameter("Enabled", true)
        .addListener((LXParameterListener)this);
    
    public UIOutputControls(
        UI _UI, 
        float _PanelWidth)
    {
        super(_UI, 0, 0, _PanelWidth, 0);
        
        setLayout(UI2dContainer.Layout.VERTICAL);
        setChildMargin(2,0);
        
        setTitle("NETWORK OUTPUT");
        
        new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("Enabled")
            .addToContainer(this);
        
        new UIButton(12, UI_PADDING, 16, 16)
            .setParameter(Enabled)
            .addToContainer(this);
    }
    
    void onParameterChanged(LXParameter parameter)
    {
        if (parameter == Enabled)
        {
            println("Output Enabled: " + Enabled.getValueb());
            lx.engine.output.enabled.setValue(Enabled.getValueb());
        }
    }
}
*/
<<<<<<< HEAD
=======

private static final int DUST_FILL = #A7784C;

public class UISimulation extends UI3dComponent {

    private final PImage dust;
    private final PImage person;

  UISimulation() {
    addChild(umbrellaModel = new UIRadiaLumia());
    this.dust = loadImage("dust.png");
    this.person = loadImage("person.png");
  }
  
  protected void beginDraw(UI ui, PGraphics pg) {
    float level = 255;
    pg.pointLight(level, level, level, -10*FEET, 30*FEET, -30*FEET);
    pg.pointLight(level, level, level, 30*FEET, 20*FEET, -20*FEET);
    pg.pointLight(level, level, level, 0, 0, 30*FEET);
  }
  
  @Override
  protected void onDraw(heronarts.p3lx.ui.UI ui, PGraphics pg) {
    pg.tint(DUST_FILL);
    pg.textureMode(NORMAL);
    pg.beginShape();
    pg.texture(this.dust);
    float HEIGHT_REF = 20*FEET;
    pg.vertex(-100*FEET, -HEIGHT_REF - 1*FEET, -100*FEET, 0, 0);
    pg.vertex(100*FEET, -HEIGHT_REF - 1*FEET, -100*FEET, 0, 1);
    pg.vertex(100*FEET, -HEIGHT_REF - 1*FEET, 100*FEET, 1, 1);
    pg.vertex(-100*FEET, -HEIGHT_REF - 1*FEET, 100*FEET, 1, 0);
    pg.endShape(CLOSE);
    
    float personY = -HEIGHT_REF - 1*FEET;
    drawPerson(pg, -10*FEET, personY, 10*FEET, 1.5*FEET, 1.5*FEET);
    drawPerson(pg, 8*FEET, personY, 12*FEET, -1.5*FEET, 1.5*FEET);
    drawPerson(pg, 2*FEET, personY, 8*FEET, -2*FEET, 1*FEET);
    
    // pg.fill(WOOD_FILL);
    // pg.noStroke();
  }
  
  void drawPerson(PGraphics pg, float personX, float personY, float personZ, float personXW, float personZW) {
    pg.tint(#393939);
    pg.beginShape();
    pg.texture(this.person);
    pg.vertex(personX, personY, personZ, 0, 1);
    pg.vertex(personX + personXW, personY, personZ + personZW, 1, 1);
    pg.vertex(personX + personXW, personY + 5*FEET, personZ + personZW, 1, 0);
    pg.vertex(personX, personY + 5*FEET, personZ, 0, 0);
    pg.endShape(CLOSE);
  }

  protected void endDraw(UI ui, PGraphics pg) {
    pg.noLights();
  }

}
>>>>>>> 838e0fc1c7264c765788ad0b63032d7865e13f88
