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
    new CompoundParameter("wid", .2, 0.0, 5.0);

  public RevolvingDiscs (LX lx) {
    super(lx);
    addParameter(rotation);
    addParameter(rotation_offset);
    addParameter(num_discs);
    addParameter(disc_width);
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

    for(int i = 0; i < num_discs.getValue(); i++) {
      theta = (float)rotation.getValue() + ((float)rotation_offset.getValue() * (float)i);
      width = (float)disc_width.getValue();

      center = new PVector(0, 0, 0);
      c_normal = new PVector(cos(theta), 0.0, sin(theta)).normalize();

      front_center = center.add(c_normal.mult(width));
      back_center = center.sub(c_normal.mult(width));
      
      for (LXPoint p : model.points) {
        p_vec = new PVector(p.x, p.y, p.z);
        PVector to_center = p_vec.sub(center);
        float dot_center = to_center.normalize().dot(c_normal);
        dot_center = constrain(dot_center, 0, 1);
        colors[p.index] = LXColor.hsb(0, 0, dot_center * 100);
      }
    }
  }
}
  
