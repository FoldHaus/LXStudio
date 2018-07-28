// Globals

int MAX_TEMPO_MULTIPLIER = 32;

// Patterns

public abstract class ArtHausPattern extends RadiaLumiaPattern
{
    
    public final DiscreteParameter TempoMultiplier =
        new DiscreteParameter("tempo", 4, 1, MAX_TEMPO_MULTIPLIER);
    
    public ArtHausPattern (LX lx)
    {
        super(lx);
        addParameter(TempoMultiplier);
    }
}

@LXCategory("ArtHaus")
public class BeatPinSpots extends ArtHausPattern 
{
    public boolean[] BloomPinspotOn;
    
    public BeatPinSpots (LX lx) {
        super(lx);
        
        BloomPinspotOn = new boolean[42];
        
        for (int i = 0; i < 42; i++) {
            // Turn roughly 1/4 of the pinspots on at a time.
            if (random(0, 1) > .75)
            {
                BloomPinspotOn[i] = true;
                setPinSpot(model.blooms.get(i), 255);
            }
        }
    }
    
    int BeatsSinceUpdate = 0;
    
    public void run (double deltaMs) {
        if (lx.tempo.beat())
        {
            BeatsSinceUpdate++;
            
            if (BeatsSinceUpdate >= TempoMultiplier.getValuei())
            {
                BeatsSinceUpdate = 0;
                
                for (Bloom b : model.blooms) {
                    
                    if (BloomPinspotOn[b.id])
                    {
                        // If the pinspot is on, turn it off
                        setPinSpot(b, 0);
                        BloomPinspotOn[b.id] = false;
                    }
                    else
                    {
                        // If the pinspot is off, there is a 1/3 chance it will turn on
                        if (random(0, 1) > .66)
                        {
                            BloomPinspotOn[b.id] = true;
                            setPinSpot(b, 255);
                        }
                    } 
                }
            }
        }
    }
}

@LXCategory("ArtHaus")
public class BeatSpikes extends ArtHausPattern
{
    
    public final CompoundParameter P_TrailLength =
        new CompoundParameter("Length", .25, 0.01, 1);
    
    public final DiscreteParameter P_TrailsPerBeat =
        new DiscreteParameter("Count", 10, 0, 42);
    
    public BeatSpikes (LX lx) {
        super(lx);
        addParameter(P_TrailLength);
    }
    
    public void run (double deltaMs) {
        float Period = (float)TempoMultiplier.getValuei();
        float TrailLength = P_TrailLength.getValuef();
        
        float CurrentPercent = ((float)(lx.tempo.beatCount()) % Period) / Period;
        CurrentPercent += lx.tempo.ramp() / Period;
        
        for (Bloom b : model.blooms)
        {
            for (LXPoint p : b.spike.leds)
            {
                LXVector pointVector = LXPointToVector(p);
                float PercentDistance = (pointVector.dist(b.center) * 2 * TrailLength) / (b.maxSpikeDistance);
                
                float Brightness = CurrentPercent - PercentDistance;
                Brightness = (TrailLength - Brightness) / TrailLength;
                if (Brightness > 1)
                    Brightness = 0;
                Brightness = constrain(Brightness, 0, 1);
                
                colors[p.index] = LXColor.hsb(0, 0, Brightness * 100);
            }
        }
    }
}

@LXCategory("ArtHaus")
public class UmbrellaLightSteps extends ArtHausPattern
{
    
    public final DiscreteParameter P_NumSteps = 
        new DiscreteParameter("Count", 3, 1, 42);
    
    public int[] IlluminatedUmbrellas;
    
    public UmbrellaLightSteps (LX lx)
    {
        super(lx);
        addParameter(P_NumSteps);
        
        IlluminatedUmbrellas = new int[42];
    }
    
    public void run (double deltaMs)
    {
        int Period = TempoMultiplier.getValuei();
        int Progress = lx.tempo.beatCount() % Period;
        float ProgressPercent = (float)lx.tempo.ramp();
        
        if (lx.tempo.beat())
        {
            println(0);
            if (Progress == 0)
            {
                println(1);
                // Init new Pattern
                IlluminatedUmbrellas[0] = (int)random(0, 42);
                println("Step: " + IlluminatedUmbrellas[0]);
                for (int i = 1; i < P_NumSteps.getValuei(); i++)
                {
                    Bloom previousBloom = model.blooms.get(IlluminatedUmbrellas[i-1]);
                    
                    IlluminatedUmbrellas[i] = previousBloom.neighbors.get((int)random(0, previousBloom.neighbors.size())).id;
                    
                    println("Step: " + IlluminatedUmbrellas[i]);
                }
            }
        }
        
        // Fade all illuminated umbrellas
        IlluminateUmbrella(IlluminatedUmbrellas[Progress], ProgressPercent);
    }
    
    public void IlluminateUmbrella (
        int _ID,
        float _Percent
        )
    {
        Bloom b = model.blooms.get(_ID);
        for (LXPoint p : b.leds)
        {
            if (POINT_COVEREDBYUMBRELLA[p.index])
            {
                colors[p.index] = LXColor.hsb(0, 0, 100 * (1 - _Percent));
            }
        }
    }
}