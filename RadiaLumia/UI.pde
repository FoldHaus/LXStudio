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