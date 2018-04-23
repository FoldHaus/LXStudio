// UmbrellaBasePattern
/* This file contains the base classes from which you inherit to create a Pattern
   which can control Umbrellas. 
   
   TO CREATE AN UMBRELLA PATTERN
   - Simply extend BaseUmbrellaPattern
   - Call SetUmbrellaPercentClosed(Umbrella, double) in your run function to update the position

   Remarks:
   Every BaseUmbrellaPattern relies on a post-processing effect which, after all Updates to the 
   umbrella effects are made, each request is merged with the others. This happens in the
   SingletonUmbrellaUpdater. This Effect is added to the main channel when any BaseUmbrellaPattern
   is created. Each subsequent Pattern checks to see if it exists. If it does, it does nothing, otherwise
   it is created. Because this is handled in the BaseUmbrellaPattern's constructor, Pattern authors
   dont need to worry about it at all.
 */

// BaseUmbrellaPattern
// The base class from which all Patterns which control umbrellas should inherit
public abstract class BaseUmbrellaPattern extends LXModelPattern<Model> {

  private LXChannel channel;
  
  private boolean isTransitioningIn;
  private boolean isActive;

  public BaseUmbrellaPattern (LX lx) {
    super(lx);
    channel = this.getChannel();
    
    if (umbrellaUpdater == null) {
      lx.engine.masterChannel.addEffect(new SingletonUmbrellaUpdater(lx));
    }
    
    isTransitioningIn = false;
    isActive = false;
  }
  
  @Override
  public void onTransitionStart() {
    isTransitioningIn = true;
  }
  
  @Override
  public void onTransitionEnd() {
    isTransitioningIn = false;
  }
  
  @Override
  public void onActive () {
    isActive = true;
  }
  
  @Override
  public void onInactive () {
    isActive = false;
  }
  
  public double getWeight (boolean printWeightProgress) {
     double weight = channel.fader.getNormalized();
     double progress = channel.getTransitionProgress();
      
     if (isTransitioningIn && !(progress > 0)) { 
       weight = 0;
     } else if (progress > 0) {
       if (!isTransitioningIn && progress < .998) {
         weight *= 1 - progress;
       }else if (isTransitioningIn){
         weight *= progress;
       }
     }
      
     if (printWeightProgress)
       println (getIndex() + " : " + progress + " : " + weight);
      
     return weight;
  }
  
  public void SetUmbrellaPercentClosed (Bloom.Umbrella u, double pctClosed) {
    if (channel == null)
      channel = this.getChannel();

    double weight = getWeight(false);

    u.RequestPercentClosed(pctClosed, weight);
  }
}

// SingletonUmbrellaUpdater
// Added to the Main Channel by the first UmbrellaPattern created
// At the end of every frame, goes through and calls UpdateUmbrellas for each
// umbrella
public class SingletonUmbrellaUpdater extends LXModelEffect<Model> {
  public SingletonUmbrellaUpdater (LX lx) {
   super(lx);
   umbrellaUpdater = this;
   this.enable();
  }
  
  public void run (double deltaMs, double enabledAmount) {
    for (Bloom b : model.blooms) {
      b.umbrella.UpdateUmbrella(deltaMs);
    }
  }
}
