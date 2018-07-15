// Pattern: RadiaWindProtect
//
// Controlled by output from an anemometer that triggers the entire sphere to contract
// its shells in an elegant fashion whenever the wind picks up.
//

@LXCategory("Umbrella")
public class RadiaWindProtect extends UmbrellaEffect {
	
	private final static float CLOSE_THRESHOLD = 0.5; 	// more than this and we'll close

	// NATHALIE: these aren't used right now
	// private final static float OPEN_THRESHOLD = 0.3; 	// more than this and we'll reopen
	// private final static float WAVE_WIDTH = 0.3;		// how much blending do we do into the shells below

	// input from the anemometer sent to us in the range of 0 (no wind) to 1 (time to freak out)
	public final CompoundParameter windState = 
	  new CompoundParameter ("wind", 0.1, 0, 1).setDescription("How strong is the wind right now");

	// how fast the entire sphere will close in seconds -- NATHALIE: currently unused
	public final CompoundParameter patternSpeed = 
	  new CompoundParameter ("speed", 5000, 30000, 0).setDescription("How quickly in milliseconds the animation flows through the sphere");

	// value determines the vertical cross section of shells being affected
	public final SinLFO waveValue =
    new SinLFO(0, 1, patternSpeed);

	public RadiaWindProtect(LX lx) {
  	super(lx);
    	    
		addParameter(windState);
		addParameter(patternSpeed);
		startModulator(waveValue);
	}

	public void run (double deltaMs, double amount) {
		float windState = this.windState.getValuef();
		
		// contract the shells if windy
		if (windState > CLOSE_THRESHOLD) {
		  for (Bloom b : model.blooms) {
				setUmbrella(b, 255);
	    }
	  }
	  // otherwise let the other animation channels do their thing
	}
}
