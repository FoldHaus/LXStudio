@LXCategory("Color")
public class ColorSpheres extends RadiaLumiaPattern {
  
  public final CompoundParameter sphereBaseSize = 
    new CompoundParameter("size", 1, 0, 350);
  
  public final CompoundParameter deltaMag =
    new CompoundParameter("dmag", 0, 0, 300);
  
  public final CompoundParameter offset =
    new CompoundParameter("off", 0, 0, 300);
  
  public final ColorParameter colorA =
    new ColorParameter("A");
  
  
  
  public ColorSpheres (LX lx) {
    super(lx);
    addParameter(sphereBaseSize);
    addParameter(deltaMag);
    addParameter(offset);
    addParameter(colorA);
  }

  public void run (double deltaMs) {
    
    double diameter = sphereBaseSize.getValue();
    float theta = (float)(offset.getValue());
    float delta_mag = (float)(deltaMag.getValue());
    
    LXVector sphereA_pos = new LXVector(sin(theta), sin(.835 * (theta + .3251)), cos(theta)).normalize().mult(delta_mag);
    LXVector sphereB_pos = new LXVector(sin(-theta + .3), cos(.831 * (theta + .3415) + .3), cos(-theta + .3)).normalize().mult(delta_mag);
    
    double a_distance = 0;
    double a_pct_diameter = 0;
    double b_distance = 0;
    double b_pct_diameter = 0;
    
    LXVector light_pos;

    int hueA = (int)(sin(theta * .1) * 360);
    int hueB = (int)(sin(theta * .162 + .138) * 360);
    int hueC = (int)(sin(theta - .183) * 360);
    
    for (LXPoint light : model.leds) {
      light_pos = new LXVector(light.x, light.y, light.z);
      
      a_distance = light_pos.dist(sphereA_pos);
      a_pct_diameter = clamp((a_distance / diameter), 0, 1);
      
      b_distance = light_pos.dist(sphereB_pos);
      b_pct_diameter = clamp((b_distance / diameter), 0, 1);
            
      int colA = LXColor.lerp(LXColor.hsb(hueA, 100, 100), LXColor.BLACK, a_pct_diameter);
      int colB = LXColor.lerp(LXColor.hsb(hueB, 100, 100), LXColor.BLACK, b_pct_diameter);
      
      int colC = LXColor.hsb(hueC, 100, 25);
      
      int finalCol = LXColor.add(colA, LXColor.add(colB, colC));
      double brightnessPct = (double)(LXColor.b(finalCol)) / 100;
      finalCol = LXColor.lerp(colC, finalCol, brightnessPct);
//LXColor.lerp(colA, colB, a_pct_diameter / (a_pct_diameter + b_pct_diameter));
      //finalCol = LXColor.lerp(colC, finalCol, c_pct_diameter / (a_pct_diameter + b_pct_diameter + c_pct_diameter));
      
      colors[light.index] = finalCol;
    }
  }
}
