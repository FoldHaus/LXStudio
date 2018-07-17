// Sets all umbrellas to a universal position
@LXCategory("Umbrella")
public class UmbrellaUniversalState extends RadiaLumiaPattern {
    
    // Position of the umbrellas
    public final CompoundParameter position =
        new CompoundParameter("Position", 0)
        .setDescription("How extended are the umbrellas");
    
    public UmbrellaUniversalState(LX lx) {
        super(lx);
        addParameter("position", this.position);
    }
    
    public void run (double deltaMs) {
        double position = this.position.getValue();
        for (Bloom b : model.blooms) {
            setUmbrella(b, position);
        }
    }
}

// UmbrellaTest1
/*
  Umbrellas are 100% open at bottom and closed at top
  
  Increase complexity w/ selectable start top / bottom. Can make 100% a selectable spot (in middle). 
  */ 

@LXCategory("Umbrella")
public class yPositionOpen extends RadiaLumiaPattern {  
    private float lowestUmbrella;
    private float highestUmbrella;
    private float umbrellaDelta;
    
    public final CompoundParameter yPositionOpen =
        new CompoundParameter ("yPosOpen", 0, 1)
        .setDescription ("What percent verticle in y direction");
    
    public final CompoundParameter ySquash =
        new CompoundParameter ("ySquash", 0.01, 1)
        .setDescription ("How large of a gradient is created");
    
    public yPositionOpen (LX lx) {
        super(lx);
        addParameter (yPositionOpen);
        addParameter (ySquash);
        
        lowestUmbrella = 0;
        highestUmbrella = 0;
        
        for (Bloom b : model.blooms) {
            
            if (b.center.y < lowestUmbrella)
                lowestUmbrella = b.center.y;
            
            if (b.center.y > highestUmbrella)
                highestUmbrella = b.center.y;
        }
        
        umbrellaDelta = highestUmbrella - lowestUmbrella;
        
    }
    public void run (double deltaMs) {
        
        float yPositionOpen = (float)this.yPositionOpen.getValue();
        float ySquash = (float)this.ySquash.getValue(); 
        
        for (Bloom b : model.blooms) {
            float centerPoint = b.center.y;
            float pct = (centerPoint - lowestUmbrella) / umbrellaDelta;
            float yPosDistance = (1-abs(pct - yPositionOpen)); //inverse gives out 1 at ypos
            float yPosPCT = 1-yPosDistance/ySquash; 
            setUmbrella(b, constrain(yPosPCT, 0, 1));
        }
    }
    
}


// UmbrellaVerticalWave
/*
  Visualizes a sin wave on the umbrellas.
  Oscilation is defined by waveValue
  Frequency is waveSize, period is waveSeed
 */
@LXCategory("Umbrella")
public class UmbrellaVerticalWave extends RadiaLumiaPattern {
    
    private float lowestUmbrella;
    private float highestUmbrella;
    private float umbrellaDelta;
    
    // half the distance away from the current position that is considered 'on'
    public final CompoundParameter waveSize =
        new CompoundParameter ("size", .05, 0, 1)
        .setDescription ("How wide the area turned on is.");
    
    public final CompoundParameter waveSpeed =
        new CompoundParameter ("speed", 0, 25000)
        .setDescription ("How fast the wave moves");
    
    // value determines the center of the area that is "on"
    public final SinLFO waveValue =
        new SinLFO (0, 1, waveSpeed);
    
    public UmbrellaVerticalWave (LX lx) {
        super(lx);
        
        addParameter (waveSize);
        addParameter (waveSpeed);
        startModulator(waveValue);
        
        lowestUmbrella = 0;
        highestUmbrella = 0;
        
        for (Bloom b : model.blooms) {
            
            if (b.center.y < lowestUmbrella)
                lowestUmbrella = b.center.y;
            
            if (b.center.y > highestUmbrella)
                highestUmbrella = b.center.y;
        }
        
        umbrellaDelta = highestUmbrella - lowestUmbrella;
    }
    
    public void run (double deltaMs) {
        
        float waveValue = (float)this.waveValue.getValue();
        float waveWidth = (float)this.waveSize.getValue();
        
        for (Bloom b : model.blooms) {
            float h = b.center.y;
            float pct = (h - lowestUmbrella) / umbrellaDelta;
            
            float pctDist = constrain ((abs(pct - waveValue) / waveWidth), 0, 1);
            
            setUmbrella(b, pctDist);
        }
    }
}

@LXCategory("Umbrella")
public class UmbrellaPath extends RadiaLumiaPattern {
    
    int GoalNode;
    double LastFrameTravel;
    
    public List<Bloom> Trail;
    
    public final CompoundParameter TravelPeriod =
        new CompoundParameter("per", 5000, 0, 10000)
        .setDescription("How long it takes to get from one node to the next");
    
    public final DiscreteParameter TrailLength = 
        new DiscreteParameter("len", 1, 0, 10)
        .setDescription("How long the trail behind the traveler is");
    
    public final SawLFO TravelModulator =
        new SawLFO(0, 1, TravelPeriod);
    
    public UmbrellaPath (LX lx)
    {
        super(lx);
        
        addParameter(TravelPeriod);
        addParameter(TrailLength);
        
        startModulator(TravelModulator);
        
        Trail = new ArrayList<Bloom>();
        
        // Set Initial Values
        // LastFrameTravel here is 1 so that it immediately resets upon startup
        LastFrameTravel = 1;
        GoalNode = model.blooms.get(0).neighbors.get(0).id;
    }
    
    public boolean BloomInTrail(
        int checkForId
        )
    {
        for (Bloom b : Trail)
        {
            if (b.id == checkForId)
                return true;
        }
        return false;
    }
    
    public void run (double deltaMs)
    {
        double CurrentTravel = TravelModulator.getValue();
        int MaxTrailLength = TrailLength.getValuei();
        
        // If the Travel period has been exhausted, update Origin and find a new goal
        if(CurrentTravel < LastFrameTravel ||
           1.0 - CurrentTravel < .001)
        {
            int LastOrigin = GoalNode;
            
            for (int i = Trail.size() - 1; i > 0; i--)
            {
                if (i >= MaxTrailLength)
                {
                    println("Removing at Index: " + i);
                    println("Trail Size: " + Trail.size());
                    
                    setUmbrella(Trail.get(i), 0);
                    Trail.remove(i);
                }
            }
            
            print("Adding at 0: ");
            Trail.add(0, model.blooms.get(LastOrigin));
            for (int b = 0; b < Trail.size(); b++)
            {
                print(Trail.get(b).id + " : ");
            }
            println();
            
            
            boolean FoundNewGoal = false;
            int RandomGoalIndex;
            int RandomGoalId;
            
            int NumNeighbors = model.blooms.get(LastOrigin).neighbors.size();
            int RandomStartingIndex = int(random(0, NumNeighbors));
            int NumChecked = 0;
            
            while (!FoundNewGoal || NumChecked < NumNeighbors)
            {
                RandomGoalIndex = (RandomStartingIndex + NumChecked) % NumNeighbors;
                RandomGoalId = model.blooms.get(LastOrigin).neighbors.get(RandomGoalIndex).id;
                
                if(RandomGoalId != LastOrigin &&
                   !BloomInTrail(RandomGoalId))
                {
                    GoalNode = RandomGoalId;
                    FoundNewGoal = true;
                }
                
                NumChecked++;
            }
            println();
        }
        
        // NOTE(peter): This doubles as the open pct of the Goal
        double GoalPct = CurrentTravel;
        double TrailPct = GoalPct;
        double TrailPctStep = TrailPct / (double)Trail.size();
        /*
        println("Num Trail " + MaxTrailLength + " Trail Members " + Trail.size());
        println("Travel Pct " + GoalPct + " Pct " + TrailPct + " Step " + TrailPctStep);
        */
        int TrailLength = min(Trail.size(), MaxTrailLength);
        for (int trail = 0; trail < TrailLength; trail++)
        {
            TrailPct = 1.0 - ((1.0 / TrailLength) * trail) - (CurrentTravel * (1.0 / TrailLength));
            //println(GoalPct + " : " + trail + " : " + TrailPct);
            setUmbrella(Trail.get(trail), TrailPct); 
        }
        
        setUmbrella(model.blooms.get(GoalNode), GoalPct);
        
        for (int bloom = 0; bloom < model.blooms.size(); bloom++)
        {
            colors[model.blooms.get(bloom).spike.pinSpot.index] =
                LXColor.rgb(0, 0, 0);
        }
        
        int redValue = 0;
        for (int trail = 0; trail < min(Trail.size(), MaxTrailLength); trail++)
        {
            TrailPct = 1.0 - ((1.0 / TrailLength) * trail) - (CurrentTravel * (1.0 / TrailLength));
            redValue = (int)(255.0f * TrailPct);
            colors[Trail.get(trail).spike.pinSpot.index] = LXColor.rgb(redValue, 0, 0);
        }
        
        colors[model.blooms.get(GoalNode).spike.pinSpot.index] = LXColor.rgb(0, 0, 255);
        
        LastFrameTravel = CurrentTravel;
    }
}

// NOTE(peter): This is an ongoing collaboration with Noah, EK's son. I'm not sure
// where it will go, so if in doubt, ask him what it does. ;P
@LXCategory("Umbrella")
public class NoahsPattern extends RadiaLumiaPattern {
    
    // Position of the umbrellas
    public final CompoundParameter half_A =
        new CompoundParameter("A", 0)
        .setDescription("How extended are the umbrellas");
    
    public final CompoundParameter half_B = 
        new CompoundParameter("B", 0);
    
    public NoahsPattern(LX lx) {
        super(lx);
        addParameter(this.half_A);
        addParameter(this.half_B);
    }
    
    public void run (double deltaMs) {
        double position_A = this.half_A.getValue();
        double position_B = this.half_B.getValue();
        
        for (Bloom b : model.blooms) {
            if (b.center.x < 0) {
                setUmbrella(b, position_A);
            }else{
                setUmbrella(b, position_B);
            }
        }
    }
}