// Globals

int MAX_TEMPO_MULTIPLIER = 32;
int NUM_MUSICIANS = 4;
int MUSICIAN_MAX_PATTERN_REPETITION = 32;

// PATTERNS NEEDED
/*
*  - Quarter Structure turns on at a time
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
public class Empty extends ArtHausPattern
{
    public Empty(LX lx)
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
    
    public final BooleanParameter P_OneAtATime =
        new BooleanParameter("One", false);
    
    public final CompoundParameter P_CutoffBrightness =
        new CompoundParameter("Cutoff", 15, 1, 100)
        .setDescription("The brightness level below which the lights will shut off");
    
    public UmbrellaLightSteps (LX lx)
    {
        super(lx);
        addParameter(P_NumSteps);
        addParameter(P_OneAtATime);
        addParameter(P_CutoffBrightness);
    }
    
    public void ResetPattern ()
    {
        
    }
    
    public void run (double deltaMs)
    {
        float Period = TempoMultiplier.getValuef();
        float Progress = lx.tempo.beatCount() % Period;
        
        float ProgressPercent = (Progress + lx.tempo.rampf()) / Period;
        
        if (lx.tempo.beat())
        {
            if (!P_OneAtATime.getValueb() || Progress == 0)
            {
                int NewBloomCount = P_NumSteps.getValuei();
                for (int NewBloom = 0; NewBloom < NewBloomCount; NewBloom++)
                {
                    int BloomIndex = (int)random(0, 42);
                    for (LXPoint p : model.blooms.get(BloomIndex).leds)
                    {
                       colors[p.index] = LXColor.WHITE; 
                    }
                }
            }
        }

        for (LXPoint p : model.leds)
        {
           colors[p.index] = LXColor.lerp(colors[p.index], LXColor.BLACK, ProgressPercent * ProgressPercent); 
        }
        
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

@LXCategory("ArtHaus")
public class PinwheelTempo extends ArtHausPattern
{
  
   public final DiscreteParameter P_NumSteps =
     new DiscreteParameter("Count", 3, 0, 42);
     
   int[] PinwheelProgress = new int[42];
     
   public PinwheelTempo (LX lx)
   {
      super(lx); 
      addParameter(P_NumSteps);
      
      for(int i = 0; i < 42; i++)
      {
         PinwheelProgress[i] = -1; 
      }
   }
   
   public void ResetPattern ()
   {
     
   }
   
   public void run (double deltaMs)
   {
      float Period = TempoMultiplier.getValuef();
      float Progress = lx.tempo.beatCount() % Period;
      
      if (lx.tempo.beat())
      {
        
          for (int BloomIndex = 0; BloomIndex < 42; BloomIndex++)
          {
             if (PinwheelProgress[BloomIndex] >= 0)
             {
                 PinwheelProgress[BloomIndex] += 1;
                 if (PinwheelProgress[BloomIndex] >= model.blooms.get(BloomIndex).spokes.size())
                 {
                    PinwheelProgress[BloomIndex] = -1; 
                 }
                 else
                 {
                    for (LXPoint p : model.blooms.get(BloomIndex).spokes.get(PinwheelProgress[BloomIndex]).points)
                    {
                       colors[p.index] = LXColor.WHITE;   
                    }
                 }
                 
             }
          }
          
          if (Progress == 0)
          {
              int NewBloomCount = P_NumSteps.getValuei();
              for (int NewBloom = 0; NewBloom < NewBloomCount; NewBloom++)
              {
                  int BloomIndex = (int)random(0, 42);
                  PinwheelProgress[BloomIndex] = 1;
                  for (LXPoint p : model.blooms.get(BloomIndex).spokes.get(0).points)
                  {
                     colors[p.index] = LXColor.WHITE; 
                  }
              }
          }
      }
      
      
      for (LXPoint p : model.leds)
      {
         colors[p.index] = LXColor.multiply(colors[p.index], LXColor.hsb(0, 0, 100 - (1 + (int)(((int)Period / 100) * deltaMs)))); 
      }
   }
}

@LXCategory("ArtHaus")
public class BrightenPopAsleep extends ArtHausPattern 
{
   public final CompoundParameter P_BrightenSpeed =
     new CompoundParameter ("spd", .03, 0, 1);
     
   public final DiscreteParameter P_OffCount =
     new DiscreteParameter ("count", 13, 0, 42);
   
   public BrightenPopAsleep (LX lx)
   {
     super(lx);
     addParameter(P_BrightenSpeed);
     addParameter(P_OffCount);
   }
   
   public void ResetPattern ()
   {
     
   }
   
   public void run (double deltaMs)
   {
       float Period = TempoMultiplier.getValuef();
       float Progress = lx.tempo.beatCount() % Period;
       
       float BrightenAmt = (float)(P_BrightenSpeed.getValue() * deltaMs);
       int AddColor = LXColor.hsb(0, 0, BrightenAmt);
       
       for (LXPoint p : model.leds)
       {
          colors[p.index] = LXColor.add(colors[p.index], AddColor);  
       }
       
       if (lx.tempo.beat())
       {
         if (Progress == 0)
         {
             int NewBloomCount = P_OffCount.getValuei();
             for (int NewBloom = 0; NewBloom < NewBloomCount; NewBloom++)
             {
                int BloomIndex = (int)random(0, 42);
                for (LXPoint p : model.blooms.get(BloomIndex).leds)
                {
                   colors[p.index] = LXColor.BLACK; 
                }
             }
         }
       }
   }
}

@LXCategory("ArtHaus")
public class ArtHausColor extends ArtHausPattern 
{
    float Base_StartHueRange = 330f;
    float Base_EndHueRange = 160f;
    float Base_NoiseBasis = 0f;
    
    public final CompoundParameter P_BaseScale = 
      new CompoundParameter("Base Scale", 2.5, 1, 10);
    
    public final CompoundParameter P_BaseSpeed = (CompoundParameter)
      new CompoundParameter("Base Speed", .5, -1, 1)
      .setPolarity(LXParameter.Polarity.BIPOLAR);
      
    
    float Contrast_StartHueRange = 200f;
    float Contrast_EndHueRange = 300f;
    float Contrast_NoiseBasis = 0f;
    
    public final CompoundParameter P_ContrastPresence =
      new CompoundParameter("Contrast", 0, 0, 1);
      
    public final CompoundParameter P_ContrastScale =
      new CompoundParameter("ConScale", 2.5, 1, 10);
    
    public final CompoundParameter P_ContrastSpeed = (CompoundParameter)
      new CompoundParameter("ConSpeed", .5, -1, 1)
      .setPolarity(LXParameter.Polarity.BIPOLAR);
      
    
    public ArtHausColor (LX lx)
    {
        super(lx);
        addParameter(P_BaseScale);
        addParameter(P_BaseSpeed);
        
        addParameter(P_ContrastPresence);
        addParameter(P_ContrastScale);
        addParameter(P_ContrastSpeed);
    }
    
    public void ResetPattern ()
    {
      
    }
    
    final float MOTION_MOD = .005;
    
    public void run (double deltaMs)
    {
        Base_NoiseBasis += deltaMs * MOTION_MOD * P_BaseSpeed.getValuef();
        Contrast_NoiseBasis += deltaMs * MOTION_MOD * P_ContrastSpeed.getValuef();
        
        AddColorNoise((float)deltaMs, Base_StartHueRange, Base_EndHueRange, P_BaseScale.getValuef(), Base_NoiseBasis, 0, 1);
        AddColorNoise((float)deltaMs, Contrast_StartHueRange, Contrast_EndHueRange, P_ContrastScale.getValuef(), Contrast_NoiseBasis, 1f - P_ContrastPresence.getValuef(), 1f);
    }
    
    void AddColorNoise (float deltaMs, float StartHueRange, float EndHueRange, float Scale, float NoiseBasis, float NoiseMinRange, float NoiseMaxRange)
    {
        float Adjusted_StartHueRange = StartHueRange;
        float Adjusted_EndHueRange = EndHueRange;
        if (Adjusted_StartHueRange > Adjusted_EndHueRange)
          Adjusted_StartHueRange -= 360f;
        
        for(LXPoint p : model.leds)
        {
           float nv = noise(
              (p.xn * Scale) + p.xn + NoiseBasis,
              (p.yn * Scale) + p.yn + NoiseBasis, 
              (p.zn * Scale) + p.zn + NoiseBasis
            ); 
            nv = sin(nv);
            nv *= nv;
            
            float presence = 0f;
            float xBase = (p.xn * Scale) + p.zn + NoiseBasis;
            float yBase = (p.yn * Scale) + p.xn + NoiseBasis;
            float zBase = (p.zn * Scale) + p.zn + NoiseBasis;

            presence = noise(xBase + 1f * Scale, yBase + 1f * Scale, zBase + 1f * Scale);
            presence = sin(presence);
            
            if (presence < NoiseMinRange || presence > NoiseMaxRange)
              continue;
            
            presence = sin(presence);
            
            float Hue = lerp(Adjusted_StartHueRange, Adjusted_EndHueRange, nv);
            
            colors[p.index] = LXColor.lerp(colors[p.index], LXColor.hsb(Hue, 100, 100), presence);
        }
    }
}

@LXCategory("ArtHaus")
public class BloomTransition extends ArtHausPattern
{
   
   double TargetPosition = 1;
   boolean[] BloomsTransitioning = new boolean[42];
   
   public BloomTransition (LX lx)
   {
       super(lx);
       for (int i = 0; i < 42; i++)
       {
          BloomsTransitioning[i] = false; 
       }
   }
   
   public void ResetPattern ()
   {
     
   }
   
   public void run(double deltaMs)
   {
       if (lx.tempo.beat() && 
           lx.tempo.beatCount() % TempoMultiplier.getValuef() == 0)
       {
          // Begin transition for umbrella
          int BloomIndex = (int)random(0f, 42f);
          BloomsTransitioning[BloomIndex] = true;
       }
       
       TransitionUmbrellas();
       TargetPosition = UpdateCurrentTargetPosition();
       println(TargetPosition); 
   }
   
   void TransitionUmbrellas()
   {
       int BloomIndex = 0;
       for (Bloom b : model.blooms)
       {
           if (BloomsTransitioning[BloomIndex])
           {
               setUmbrella(model.blooms.get(BloomIndex), TargetPosition);
           }
           BloomIndex++;
       }
   }
   
   double UpdateCurrentTargetPosition ()
   {
       int BloomsAtTarget = 0;
       for (Bloom b: model.blooms)
       {
           if (abs(b.umbrella.simulatedPosition - TargetPosition) < .001)
           {
               BloomsAtTarget++;
           }
       }
       if (BloomsAtTarget == 42)
       {
          return 1. - TargetPosition; 
       } 
       
       return TargetPosition;
   }
}

@LXCategory("ArtHaus")
public class Fireworks extends ArtHausPattern
{
  
   public final CompoundParameter P_FireworkSize =
       new CompoundParameter("Size", 100, 0, 500);
   
   LXVector FireworkOrigin;
   
   public Fireworks (LX lx)
   {
       super(lx);
       addParameter(P_FireworkSize);
       
       int RandomBloom = (int)random(0, 42);
       FireworkOrigin = model.blooms.get(RandomBloom).center;
   }
   
   public void ResetPattern ()
   {
     
   }
   
   public void run (double deltaMs)
   {
       float Period = TempoMultiplier.getValuef();
       float Progress = lx.tempo.beatCount() % Period;
       float ProgressPercent = (Progress + lx.tempo.rampf()) / Period;
       
       if (lx.tempo.beat() && 
           Progress == 0)
       {
          int RandomBloom = (int)random(0, 42);
          FireworkOrigin = model.blooms.get(RandomBloom).center;
       }
       
       float Brightness = constrain(1f - (((ProgressPercent * ProgressPercent) * 1.2) - .2), 0, 1) * 100;
       float Size = ProgressPercent * P_FireworkSize.getValuef();
       
       for (LXPoint p : model.leds)
       {
          LXVector PointVector = LXPointToVector(p);
          float DistanceToCenter = PointVector.dist(FireworkOrigin);
          if (DistanceToCenter < Size)
          {
             colors[p.index] = LXColor.hsb(0, 0, Brightness); 
          }
          else
          {
             colors[p.index] = LXColor.BLACK; 
          }
       }
   }
}


@LXCategory("ArtHaus")
public class UmbrellaOneAtATimeOnTime extends ArtHausPattern
{
  
   public int LastFrameIndex;
   
   public UmbrellaOneAtATimeOnTime (LX lx)
   {
     super(lx);
     LastFrameIndex = 0;
   }
   
   public void ResetPattern ()
   {
   }
   
   public void run(double deltaMs)
   {
     
       float Period = TempoMultiplier.getValuef();
       float Progress = lx.tempo.beatCount() % Period;
       
       int Index = LastFrameIndex;
       
       if (Progress == 0 && lx.tempo.beat())
       {
           Index++;
           Index = Index % 42;
       }
       
       setUmbrella(model.blooms.get(Index), 1f);
       
       if (Index != LastFrameIndex)
       {
          setUmbrella(model.blooms.get(LastFrameIndex), 0f);
       }
       
       LastFrameIndex = Index;
   }
  
}
