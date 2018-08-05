public PVector LXToPVector (LXVector lxv) {
	return new PVector (lxv.x, lxv.y, lxv.z);
}

public LXVector PToLXVector (PVector pv) {
	return new LXVector (pv.x, pv.y, pv.z);
}

public LXVector LXPointToVector(LXPoint p) {
    return new LXVector(p.x, p.y, p.z);
}

public boolean stringIn (String val, String[] array) {
    for (String s : array) {
        if (s.equals(val)) {
            return true;
        }
    }
    return false;
}

// OGL Functions
public static double min(double a, double b) {
    return a < b ? a : b;
}

public static double max(double a, double b) {
    return a < b ? b : a;
}

public static double clamp(double x, double range_min, double range_max) {
    return min(range_max, max(range_min, x));
}

public static double sin(double v)
{
    return (double)sin((float)v);
}

public static double lerp(double a, double b, double pct)
{
    return (a * pct) + (b * (1.0 - pct));
}

public static double sign(double val)
{
    return val < 0 ? -1 : 1;
}

public static double pow(double val, double exp)
{
    return (double)pow((float)val, (float)exp);
}

public static double abs(double val)
{
    return (double)abs((float)val);
}

// Convenience

float[] PENTA_SPIKE_COVEREDRANGE_TOP = {.25, .018};float[] PENTA_SPIKE_COVEREDRANGE_BOTTOM = {0, 0};

float[] PENTA_SPOKE_COVEREDRANGE_TOP = {.2, 1};
float[] PENTA_SPOKE_COVEREDRANGE_BOTTOM = {0, 0};


// Was .3 and .05
float[] HEXA_SPIKE_COVEREDRANGE_TOP = {.3, .05};
float[] HEXA_SPIKE_COVEREDRANGE_BOTTOM = {0, 0};

float[] HEXA_SPOKE_COVEREDRANGE_TOP = {.2, 1};
float[] HEXA_SPOKE_COVEREDRANGE_BOTTOM = {0, 0};

public boolean[] POINT_COVEREDBYUMBRELLA;
public boolean UmbrellaMask_UpdatedThisFrame = false;

public void InitializeUmbrellaMask () {
    
    //TODO(peter): there has got to be a better way to do this
    //NOTE(peter): Figure out what owns colors and grab its length
    int maxIndex = -1;
    for (LXPoint p : model.points) {
        if (p.index > maxIndex)
            maxIndex = p.index;
    }
    
    POINT_COVEREDBYUMBRELLA = new boolean[maxIndex + 1];
    
    for (int p=0; p<maxIndex+1; p++) {
        POINT_COVEREDBYUMBRELLA[p] = false;
    }
}

public void UpdateUmbrellaMask () 
{
    
    if (UmbrellaMask_UpdatedThisFrame)
        return;
    
    float spike_coveredRange_bottomPosition;
    float spike_coveredRange_topPosition;
    float spoke_coveredRange_bottomPosition;
    float spoke_coveredRange_topPosition;
    
    float point_distance;
    float point_percentTotalDistance;
    
    float[] Working_SpikeCoveredRange_Top;
    float[] Working_SpikeCoveredRange_Bottom;
    float[] Working_SpokeCoveredRange_Top;
    float[] Working_SpokeCoveredRange_Bottom;
    
    for (Bloom b : model.blooms) {
        if (b.spokes.size() == 6)
        {
            Working_SpikeCoveredRange_Top = HEXA_SPIKE_COVEREDRANGE_TOP ;
            Working_SpikeCoveredRange_Bottom = HEXA_SPIKE_COVEREDRANGE_BOTTOM;
            Working_SpokeCoveredRange_Top = HEXA_SPOKE_COVEREDRANGE_TOP;
            Working_SpokeCoveredRange_Bottom = HEXA_SPOKE_COVEREDRANGE_BOTTOM;
        }
        else
        {
            Working_SpikeCoveredRange_Top = PENTA_SPIKE_COVEREDRANGE_TOP ;
            Working_SpikeCoveredRange_Bottom = PENTA_SPIKE_COVEREDRANGE_BOTTOM;
            Working_SpokeCoveredRange_Top = PENTA_SPOKE_COVEREDRANGE_TOP;
            Working_SpokeCoveredRange_Bottom = PENTA_SPOKE_COVEREDRANGE_BOTTOM;
        }
        
        // Calculate Spike Covered Range
        spike_coveredRange_bottomPosition = ((float)b.umbrella.simulatedPosition * Working_SpikeCoveredRange_Bottom[0]) + ((1f - (float)b.umbrella.simulatedPosition) * Working_SpikeCoveredRange_Bottom[1]);
        spike_coveredRange_topPosition = ((float)b.umbrella.simulatedPosition * Working_SpikeCoveredRange_Top[0]) + ((1f - (float)b.umbrella.simulatedPosition) * Working_SpikeCoveredRange_Top[1]);
        
        // Calculate Spoke Covered Range
        spoke_coveredRange_bottomPosition = ((float)b.umbrella.simulatedPosition * Working_SpokeCoveredRange_Bottom[0]) + ((1f - (float)b.umbrella.simulatedPosition) * Working_SpokeCoveredRange_Bottom[1]);
        spoke_coveredRange_topPosition = ((float)b.umbrella.simulatedPosition * Working_SpokeCoveredRange_Top[0]) + ((1f - (float)b.umbrella.simulatedPosition) * Working_SpokeCoveredRange_Top[1]);
        
        for (Bloom.Spoke s : b.spokes) {
            for (LXPoint p : s.points) {
                point_distance = LXPointToVector(p).dist(b.center);
                point_percentTotalDistance = (point_distance / s.maxLedDistance);
                
                POINT_COVEREDBYUMBRELLA[p.index] = point_percentTotalDistance >= spoke_coveredRange_bottomPosition && point_percentTotalDistance <= spoke_coveredRange_topPosition;
            }
        }
        
        for (LXPoint p : b.spike.leds) {
            point_distance = LXPointToVector(p).dist(b.center);
            point_percentTotalDistance = (point_distance / b.maxSpikeDistance);
            
            POINT_COVEREDBYUMBRELLA[p.index] = point_percentTotalDistance >= spike_coveredRange_bottomPosition && point_percentTotalDistance <= spike_coveredRange_topPosition;
        }
        
    }
    
    UmbrellaMask_UpdatedThisFrame = true;
}

public void UmbrellaMaskEndFrame () {
    UmbrellaMask_UpdatedThisFrame = false;
}
