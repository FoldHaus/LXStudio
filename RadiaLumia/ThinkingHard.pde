@LXCategory("Takeover")
public class ThinkingHard extends RadiaLumiaPattern 
{
    public final CompoundParameter TestA =
        new CompoundParameter("TestA", 0, 0, 5);
    
    public final CompoundParameter TestB=
        new CompoundParameter("TestB", 0, 0, 1);
    
    public final CompoundParameter TestC =
        new CompoundParameter("TestC", 0, 0, 50);
    
    public ThinkingHard (LX lx)
    {
        super(lx);
        
        addParameter(TestA);
        addParameter(TestB);
        addParameter(TestC);
    }
    
    public void run(double deltaMs)
    {
        float Radius = model.blooms.get(0).center.mag();
        float Size = TestC.getValuef();
        float Falloff = TestA.getValuef();
        
        LXVector center = new LXVector(sin(TestB.getValuef()) * Radius,
                                       cos(TestB.getValuef()) * Radius,
                                       0);
        
        LXVector v;
        float d;
        
        for (LXPoint p : model.leds)
        {
            v = LXPointToVector(p);
            d = v.dist(center) / Size;
            d = 1.0f - (d * Falloff);
            d = constrain(d, 0, 1);
            
            colors[p.index] = LXColor.hsb(0, 0, d * 100);
        }
    }
}