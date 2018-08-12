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
        float Sat = palette.getSaturationf();
        
        for (LXPoint p : model.heart.points)
        {
            colors[p.index] = LXColor.hsb(Hue, Sat, 100); 
        }
    }
}
