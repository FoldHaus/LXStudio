@LXCategory("Color")
public class VoronoiColor extends RadiaLumiaPattern {
  public VoronoiColor (LX lx) {
    super(lx);
  }

  public void run (double deltaMs) {
    
  }
  
  public float hash(float in) {
    float a = in * 0.3183099;
    a = a - floor(a);
    a = in * 17.0 * a;
    a = a - floor(a);
    return a;
  }
}
