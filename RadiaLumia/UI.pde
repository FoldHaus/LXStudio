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
