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