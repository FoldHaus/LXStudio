// Globals

int MAX_TEMPO_MULTIPLIER = 32;
int NUM_MUSICIANS = 4;
int MUSICIAN_MAX_PATTERN_REPETITION = 32;

// PATTERNS NEEDED
/*
*  - 
*/

// General Controls

public class ArtHausPerformance
{
    /* TODO(peter): ArtHausPerformance
    
     Beat
     - Need to be able to control what part of the structure is displaying the pulse
     
     
     
    */
    
    public LXPattern[] BeatPatterns;
    public int NumMusicianPatterns;
    
    public ArtHausMusician BeatMusician;
    public ArtHausMusician[] Musicians;
    
    public LX lx;
    
    public ArtHausPerformance (
        LX _LX
        )
    {
        this.lx = _LX;
        
        InitPerformance(NUM_MUSICIANS);
    }
    
    public void InitPerformance (int _NumMusicians)
    {
        // Initialize the ArtHaus Performance Patterns
        BeatPatterns = new LXPattern[] {
            new BeatPinSpots(lx),
            new BeatSpikes(lx)
        };
        
        // Create the Musicians
        BeatMusician = InitMusician(
            BeatPatterns,
            "Beat");
        
        Musicians = new ArtHausMusician[_NumMusicians];
        for (int muse = 0; muse < _NumMusicians; muse++)
        {
            Musicians[muse] = InitMusician(
                InitMusicianPatterns(),
                "Musician " + muse);
        }
    }
    
    public ArtHausMusician InitMusician (
        LXPattern[] _Patterns,
        String _MusicianName
        )
    {
        LXChannel MusicianChannel = lx.engine.addChannel(_Patterns);
        MusicianChannel.label.setValue(_MusicianName);
        MusicianChannel.fader.setValue(1);
        
        ArtHausMusician Result = new ArtHausMusician(
            MusicianChannel
            );
        
        SetMusicianPattern(
            Result,
            (int)random(0, NumMusicianPatterns),
            (int)random(0, MUSICIAN_MAX_PATTERN_REPETITION)
            );
        
        return Result;
    }
    
    // NOTE(peter): Add ArtHaus Performance Patterns Here
    public LXPattern[] InitMusicianPatterns ()
    {
        LXPattern[] Patterns = new LXPattern[]{
            new UmbrellaLightSteps(lx),
            new RotatingColorFade(lx),
            new GlowingBlossoms(lx)
        };
        
        this.NumMusicianPatterns = Patterns.length;
        
        return Patterns;
    }
    
    public void OnPatternCompleted (
        ArtHausMusician _Musician
        )
    {
        _Musician.ElapsedRepetitions += 1;
        if (_Musician.ElapsedRepetitions >= _Musician.TotalRepetitions)
        {
            ChooseNewPattern(_Musician);
        }
    }
    
    public void ChooseNewPattern (
        ArtHausMusician _Musician
        )
    {
        SetMusicianPattern(
            _Musician,
            (int)random(0, NumMusicianPatterns),
            (int)random(0, MUSICIAN_MAX_PATTERN_REPETITION)
            );
    }
    
    public void SetMusicianPattern (
        ArtHausMusician _Musician,
        int _PatternIndex,
        int _Repetitions
        )
    {
        _Musician.TotalRepetitions = _Repetitions;
        _Musician.ElapsedRepetitions = 0;
        _Musician.Channel.goIndex(_PatternIndex);
        
        ArtHausPattern newPattern = (ArtHausPattern)_Musician.Channel.getPattern(_PatternIndex);
        newPattern.Musician = _Musician;
    }
    
    public void FadeToMusicians (float _FadeDuration)
    {
        
    }
    
    public void FadeToScriptedPatterns (float _FadeDuration)
    {
        
    }
}

public class ArtHausMusician
{
    public int TotalRepetitions;
    public int ElapsedRepetitions;
    public LXChannel Channel;
    
    public ArtHausMusician (
        LXChannel _Channel
        )
    {
        this.Channel = _Channel;
    }
}

// Patterns

public abstract class ArtHausPattern extends RadiaLumiaPattern
{
    
    // TODO(peter): Needed fields
    // - channelMode - the blend mode of the channel while this pattern is on
    // - musician - track which musician is playing 
    
    public final DiscreteParameter TempoMultiplier =
        new DiscreteParameter("tempo", 4, 1, MAX_TEMPO_MULTIPLIER);
    
    public ArtHausMusician Musician;
    public boolean HasPassedFirstFrame;
    
    public ArtHausPattern (LX lx)
    {
        super(lx);
        addParameter(TempoMultiplier);
        HasPassedFirstFrame = false;
    }
    
    public abstract void ResetPattern ();
    
    public void PatternCompleted ()
    {
        this.ResetPattern();
        if (artHaus != null)
        {
            artHaus.ChooseNewPattern(this.Musician);
        }
    }
}

@LXCategory("ArtHaus")
public class NoPattern extends ArtHausPattern
{
    public NoPattern(LX lx)
    {
        super(lx);
    }
    public  void ResetPattern ()
    {
    }
    public void run(double deltaMs)
    {
    }
}

@LXCategory("ArtHaus")
public class BeatPinSpots extends ArtHausPattern 
{
    public boolean[] BloomPinspotOn;
    
    public BeatPinSpots (LX lx) {
        super(lx);
        
        BloomPinspotOn = new boolean[42];
        
        ResetPattern();
    }
    
    int BeatsSinceUpdate = 0;
    
    public void ResetPattern ()
    {
        BeatsSinceUpdate = 0;
        
        for (int i = 0; i < 42; i++) {
            // Turn roughly 1/4 of the pinspots on at a time.
            if (random(0, 1) > .75)
            {
                BloomPinspotOn[i] = true;
                setPinSpot(model.blooms.get(i), 255);
            }
        }
    }
    
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
    
    public void ResetPattern ()
    {
        
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
    
    public void ResetPattern ()
    {
        
    }
    
    public void run (double deltaMs)
    {
        // TODO(peter): Make it so that umbrellas can be lit and fade over more than one beat
        int Period = TempoMultiplier.getValuei();
        int Progress = lx.tempo.beatCount() % Period;
        float ProgressPercent = (float)lx.tempo.ramp();
        
        if (lx.tempo.beat())
        {
            if (Progress == 0)
            {
                // Init new Pattern
                IlluminatedUmbrellas[0] = (int)random(0, 42);
                for (int i = 1; i < P_NumSteps.getValuei(); i++)
                {
                    Bloom previousBloom = model.blooms.get(IlluminatedUmbrellas[i-1]);
                    
                    IlluminatedUmbrellas[i] = previousBloom.neighbors.get((int)random(0, previousBloom.neighbors.size())).id;
                }
            }
            
            if (HasPassedFirstFrame)
            {
                PatternCompleted();
            }
        }
        
        // Fade all illuminated umbrellas
        IlluminateUmbrella(IlluminatedUmbrellas[Progress], ProgressPercent);
        this.HasPassedFirstFrame = true;
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

// a rotating plane, that, at its edge, takes whatever color is currently in the led,
// and adds some value to it
@LXCategory("ArtHaus")
public class RotatingColorFade extends ArtHausPattern
{
    
    public final CompoundParameter FadeAngle = 
        new CompoundParameter("angle", .6, 0.0, TWO_PI);
    
    public final CompoundParameter AdditiveHueStrength =
        new CompoundParameter("hue", 6, 0, 360);
    
    public final SawLFO Rotator = 
        new SawLFO(0, TWO_PI, this.TempoMultiplier);
    
    public RotatingColorFade (LX lx)
    {
        super(lx);
        addParameter(FadeAngle);
        addParameter(AdditiveHueStrength);
        startModulator(Rotator);
        
        TempoMultiplier.setValue(16);
    }
    
    public void ResetPattern ()
    {
        
    }
    
    public void run (double deltaMs)
    {
        float TrailAngle = FadeAngle.getValuef();
        float BaseHue = AdditiveHueStrength.getValuef();
        float AdditiveHue = BaseHue * TrailAngle;
        // Each frame, add a percent of the desired hue shift, so that the trailing edge represents that hue.
        
        int Period = TempoMultiplier.getValuei();
        int Progress = lx.tempo.beatCount() % Period;
        
        float ProgressPercent = (float)lx.tempo.ramp();
        ProgressPercent += (float) Progress;
        ProgressPercent = ProgressPercent / (float)Period;
        
        float ProgressAngle = ProgressPercent * TWO_PI;
        
        float FrontCosAngle = cos(ProgressAngle);
        float FrontSinAngle = sin(ProgressAngle);
        float TrailCosAngle = cos(ProgressAngle - TrailAngle);
        float TrailSinAngle = sin(ProgressAngle - TrailAngle);
        
        LXVector Normal = new LXVector(FrontCosAngle, 0, FrontSinAngle);
        LXVector Forward = new LXVector(TrailCosAngle, 0, TrailSinAngle);
        
        LXVector Center = new LXVector(0, 0, 0);
        
        LXVector pointVector;
        
        for (LXPoint p : model.leds)
        {
            pointVector = LXPointToVector(p);
            float PointDotNormal = constrain(pointVector.dot(Normal), 0, 1);
            float PointDotForward = constrain(pointVector.dot(Forward), 0, 1);
            
            float AdditiveAmount = constrain((PointDotNormal - PointDotForward), 0, 1);
            
            float FinalHue = (LXColor.h(colors[p.index]) + AdditiveHue) % 360;
            if (AdditiveAmount > 0)
                colors[p.index] = LXColor.hsb(FinalHue, 100, 100);
        }
    }
}

@LXCategory("ArtHaus")
public class GlowingBlossoms extends ArtHausPattern
{
    public int BeatsTracked = 0;
    
    public GlowingBlossoms (LX lx)
    {
        super(lx);
    }
    
    public void ResetPattern ()
    {
        BeatsTracked = 0;
    }
    
    public void run(double deltaMs)
    {
        UpdateUmbrellaMask();
        
        for (Bloom b : model.blooms)
        {
            double UmbrellaBrightness = clamp(1 - (1.2 * b.umbrella.simulatedPosition), 0, 1);
            int ColorValues = (int)(UmbrellaBrightness * 255);
            
            for (LXPoint p : b.leds)
            {
                if (POINT_COVEREDBYUMBRELLA[p.index])
                {
                    colors[p.index] = LXColor.rgb(ColorValues, ColorValues, ColorValues);
                }
            }
        }
        
        if (lx.tempo.beat())
        {
            BeatsTracked++;
            if (BeatsTracked > TempoMultiplier.getValuei())
            {
                PatternCompleted();
            }
        }
    }
}

@LXCategory("ArtHaus")
public class BeatHeart extends ArtHausPattern
{
    public BeatHeart(LX lx)
    {
        super(lx);
    }
    
    public void ResetPattern ()
    {
        
    }
    
    public void run (double deltaMs)
    {
        int Period = TempoMultiplier.getValuei();
        int Progress = lx.tempo.beatCount() % Period;
        
        float ProgressPercent = (float)lx.tempo.ramp();
        ProgressPercent += (float) Progress;
        ProgressPercent = ProgressPercent / (float)Period;
        
        for (LXPoint p : model.heart.points)
        {
            colors[p.index] = LXColor.hsb(0, 0, ProgressPercent * 100);
        }
    }
}