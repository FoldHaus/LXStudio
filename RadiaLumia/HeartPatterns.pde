@LXCategory("Heart")
public class HeartGradient extends RadiaLumiaPattern
{
    public HeartGradient(LX lx)
    {
        super(lx);
    }
    
    public void run (double deltaMs)
    {
        float Hue = palette.getHuef();
        float Sat = palette.getSatf();
        
        for (LXPoint p : model.heart.points)
        {
            colors[p.index] = LXColor.hsb(Hue, Sat, 100); 
        }
    }
}

