// Pattern: RadiaWindProtect
//
// Controlled by output from an anemometer that triggers the entire sphere to contract
// its shells in an elegant fashion whenever the wind picks up.
//
public static int SECONDS = 1000;			// converts from milliseconds to seconds

public class RadiaWindProtect extends BaseUmbrellaPattern {
	
	private final static float CLOSE_THRESHOLD = 0.7; 	// more than this and we'll close
	private final static float OPEN_THRESHOLD = 0.3; 	// more than this and we'll reopen
	private final static float WAVE_WIDTH = 0.3;		// how much blending do we do into the shells below

	private float lowestUmbrella = 0;
	private float highestUmbrella = 0;
	private float umbrellaDelta;
	private int closed = 0;

	// input from the anemometer sent to us in the range of 0 (no wind) to 1 (time to freak out)
	public final CompoundParameter windState = 
	new CompoundParameter ("wind", 0, 0, 1).setDescription("How strong is the wind right now");

	// how fast the entire sphere will close in seconds
	public final CompoundParameter patternSpeed = 
	new CompoundParameter ("speed", 5000, 30000, 0).setDescription("How quickly the animation flows through the sphere");

	// value determines the vertical cross section of shells being affected

	public final SinLFO waveValue =
    	new SinLFO(0, 1, patternSpeed);

	public RadiaWindProtect(LX lx) {
    	super(lx);
    	    
		addParameter(windState);
		addParameter(patternSpeed);
		startModulator(waveValue);
  	
		lowestUmbrella = 0;
		highestUmbrella = 0;
    
	    // determine the y coordinates of the highest and lowest shells
	    for (Bloom b : model.blooms) {
	
	      if (b.center.y < lowestUmbrella)
	        lowestUmbrella = b.center.y;
	
	      if (b.center.y > highestUmbrella)
	        highestUmbrella = b.center.y;
	    }
	
	    // distance in the y-axis from highest to lowest shells
	    umbrellaDelta = highestUmbrella - lowestUmbrella;
	}

  	public void run (double deltaMs) {

  		float waveValue = (float)this.waveValue.getValue();
  		float windState = (float)this.windState.getValue();
  		
  		if (closed == 0 && windState > CLOSE_THRESHOLD) {
		  	for (Bloom b : model.blooms) {
/*
	  			float h = b.center.y;
	  			float pct = (h - lowestUmbrella) / umbrellaDelta;	// what % up the sphere's y-axis is this shell
	
	  			float pctDist = constrain(((pct - waveValue) / WAVE_WIDTH), 0, 1);
	
	  			SetUmbrellaPercentClosed(b.umbrella, pctDist);
*/
				SetUmbrellaPercentClosed(b.umbrella, 0);
	    	}
	    }	
	}
}