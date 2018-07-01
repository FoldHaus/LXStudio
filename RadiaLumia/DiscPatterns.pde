public class RevolvingDiscs extends RadiaLumiaPattern {
  
  public final CompoundParameter rotation = 
    new CompoundParameter("rot", 0.3, 0, 6.28)
    .setDescription("The root rotation of the system.");

  public final CompoundParameter offset_Z =
    new CompoundParameter("offZ", 0.3, 0, 6.28)
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
    
  public final CompoundParameter offset_Y = 
    new CompoundParameter ("offY", 0, 0, 6.28); 
  
  public RevolvingDiscs (LX lx) {
    super(lx);
    addParameter(rotation);
    addParameter(offset_Z);
    addParameter(offset_Y);
    addParameter(num_discs);
    addParameter(disc_width);
    addParameter(effect_inner_radius);
    addParameter(effect_radius);
  }

  public void run (double deltaMs) {
    
    float theta_Z;
    float theta_Y;
    float width;
    
    LXVector center;
    LXVector c_normal;
    
    LXVector front_center;
    LXVector back_center;

    LXVector p_vec;
    LXVector front_to_p;
    LXVector back_to_p;
    float front_dot_n;
    float back_dot_n;
    
    double maxRadius = effect_radius.getValue();
    double minRadius = effect_inner_radius.getValue();
    
    LXVector[] front_centers = new LXVector[num_discs.getValuei()];
    LXVector[] back_centers = new LXVector[num_discs.getValuei()];
    LXVector[] normals = new LXVector[num_discs.getValuei()];
    
    for (int disc = 0; disc < num_discs.getValue(); disc++) {
       theta_Z = ((float)offset_Z.getValue() + (float)disc);
       theta_Y = (float)offset_Y.getValue() + (float)disc;
       
       width = (float)disc_width.getValue();

       center = new LXVector(0, 0, 0);
      
       c_normal = new LXVector(cos(theta_Z), 0.0, sin(theta_Z)).normalize();
       LXVector l_right = c_normal.copy().cross(new LXVector(0, 1, 0));
       c_normal = c_normal.rotate(theta_Y, l_right.x, l_right.y, l_right.z);
      
       normals[disc] = c_normal;
       front_centers[disc] = center.copy().add(c_normal.copy().mult(-width));
       back_centers[disc] = center.copy().add(c_normal.copy().mult(width));
    }
    
    for (LXPoint p : model.leds) {
      p_vec = new LXVector(p.x, p.y, p.z);
      
      boolean inAPlane = false;
      
      for (int d = 0; d < num_discs.getValuei(); d++) {
        LXVector to_front = p_vec.copy().add(front_centers[d]);
        LXVector to_back = p_vec.copy().add(back_centers[d]);  
        
        float p_dot_front = to_front.copy().normalize().dot(normals[d]);
        float p_dot_back = to_back.copy().normalize().dot(normals[d]);
        
        p_dot_front *= 1000;
        p_dot_front = 1 - constrain(p_dot_front, 0, 1);
        
        p_dot_back *= 1000;
        p_dot_back = constrain(p_dot_back, 0, 1);
        
        double distToCenter = p_vec.copy().mag();
        if (p_dot_front > 0 && p_dot_back > 0 && distToCenter < maxRadius && distToCenter > minRadius) {
          inAPlane = true;
          break;
        }
      }
      
      if (inAPlane) {
        colors[p.index] = LXColor.WHITE; 
      }else{
        colors[p.index] = LXColor.BLACK;
      }
    }
    

  }
}

@LXCategory("Commercial as Fuck")
public class PacMan extends RadiaLumiaPattern {
  
  public final CompoundParameter mouth_angle =
    new CompoundParameter("ang", 0, 0, 6.28);
    
  public final CompoundParameter spike_radius =
    new CompoundParameter("rad", 0, 0, 100000);
    
  public final ColorParameter pacman_color =
    new ColorParameter("col");
   
  public final CompoundParameter pill_offset =
    new CompoundParameter("pil", 0, 0, 1);
  
  public PacMan (LX lx)
  {
    super(lx); 
    addParameter(mouth_angle);
    addParameter(pacman_color);
    addParameter(spike_radius);
    addParameter(pill_offset);
  }
  
  public void run(double deltaMs)
  {
    float root_angle = (float)mouth_angle.getValue();
    float top_angle = root_angle;
    float bottom_angle = 3.14 - root_angle;
    LXVector front_normal = new LXVector(1, 0, 0);
    LXVector mouth_top = new LXVector(sin(top_angle), cos(top_angle), 0);
    LXVector mouth_bottom = new LXVector(sin(bottom_angle), cos(bottom_angle), 0);
    
    int col = pacman_color.getColor();
    
    float maxDist = (float)spike_radius.getValue();
    
    LXVector to_center;
    float to_center_dot_front;
    float to_center_dot_mouth_top;
    float to_center_dot_mouth_bottom;
    float distance;
    
    for (LXPoint point : model.leds) {
      to_center = LXPointToVector(point);
      distance = to_center.magSq();
      
      to_center_dot_front = to_center.dot(front_normal);
      to_center_dot_mouth_top = to_center.dot(mouth_top);
      to_center_dot_mouth_bottom = to_center.dot(mouth_bottom);
      
      int final_color = col;
      if ((to_center_dot_mouth_bottom > 0 && to_center_dot_mouth_top > 0)
        || distance > maxDist
      ) {
        final_color = LXColor.BLACK;
      }
      
      colors[point.index] = final_color;
    }
  }
}
