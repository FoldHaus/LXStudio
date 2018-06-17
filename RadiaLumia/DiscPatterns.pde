public class RevolvingDiscs extends RadiaLumiaPattern {
  
  public final CompoundParameter rotation = 
    new CompoundParameter("rot", 0.3, 0, 6.28)
    .setDescription("The root rotation of the system.");

  public final CompoundParameter rotation_offset =
    new CompoundParameter("off", 0.3, 0, 6.28)
    .setDescription("The offset from the root for each successive disc");

  public final DiscreteParameter num_discs = 
    new DiscreteParameter("num", 1, 1, 10)
    .setDescription("The number of discs.");  

  public final CompoundParameter disc_width = 
    new CompoundParameter("wid", .2, 0.0, 200.0);

  public final CompoundParameter effect_inner_radius = 
    new CompoundParameter("inRad", 0, 0, 320);
  
  public final CompoundParameter effect_radius = 
    new CompoundParameter("rad", 320, 0, 320);
  
  public RevolvingDiscs (LX lx) {
    super(lx);
    addParameter(rotation);
    addParameter(rotation_offset);
    addParameter(num_discs);
    addParameter(disc_width);
    addParameter(effect_inner_radius);
    addParameter(effect_radius);
  }

  public void run (double deltaMs) {
    
    float theta;
    float width;
    
    PVector center;
    PVector c_normal;
    
    PVector front_center;
    PVector back_center;

    PVector p_vec;
    PVector front_to_p;
    PVector back_to_p;
    float front_dot_n;
    float back_dot_n;
    
    double maxRadius = effect_radius.getValue();
    double minRadius = effect_inner_radius.getValue();
    
    for(int i = 0; i < num_discs.getValue(); i++) {
      theta = (float)rotation.getValue() + ((float)rotation_offset.getValue() * (float)i);
      width = (float)disc_width.getValue();

      center = new PVector(0, 0, 0);
      c_normal = new PVector(cos(theta), 0.0, sin(theta)).normalize();

      front_center = center.copy().add(c_normal.copy().mult(width));
      back_center = center.copy().sub(c_normal.copy().mult(width));
      
      for (LXPoint p : model.leds) {
        p_vec = new PVector(p.x, p.y, p.z);
        
        PVector to_front = p_vec.copy().sub(front_center);
        PVector to_back = p_vec.copy().sub(back_center);
        
        float p_dot_front = to_front.copy().normalize().dot(c_normal);
        float p_dot_back = to_back.copy().normalize().dot(c_normal);
        
        p_dot_front *= 1000;
        p_dot_front = 1 - constrain(p_dot_front, 0, 1);
        
        p_dot_back *= 1000;
        p_dot_back = constrain(p_dot_back, 0, 1);
        
        double distToCenter = p_vec.copy().mag();
        
        if (p_dot_front > 0 && p_dot_back > 0 && distToCenter < maxRadius && distToCenter > minRadius) {
          colors[p.index] = LXColor.WHITE;
        }else{
          colors[p.index] = LXColor.BLACK;
        }
//        colors[p.index] = LXColor.rgb((int)(p_dot_front * 255), 0, (int)(p_dot_back * 255));
      }
    }
  }
}
  
