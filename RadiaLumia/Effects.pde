public abstract class UmbrellaEffect extends LXModelEffect<Model> {
  public UmbrellaEffect(LX lx) {
    super(lx);
  }
}

@LXCategory("Umbrella")
public class UmbrellaMute extends UmbrellaEffect {
  public UmbrellaMute(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs, double enabledAmount) {
    for (Bloom b : model.blooms) {
      int i = b.umbrella.position.index;
      int alpha = colors[i] >> 24;
      alpha = (int) (alpha * (1. - enabledAmount));
      colors[i] = (alpha << 24) | (colors[i] & 0xffffff);  
    }
  }
}
