public abstract class UmbrellaEffect extends LXModelEffect<Model> {
  public UmbrellaEffect(LX lx) {
    super(lx);
  }
  
  public void setUmbrella(Bloom bloom, double position) {
    int positionByte = 0xff & (int) (255 * position);
    this.colors[bloom.umbrella.position.index] = 0xff000000 | positionByte;
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
