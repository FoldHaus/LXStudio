public PVector LXToPVector (LXVector lxv) {
	return new PVector (lxv.x, lxv.y, lxv.z);
}

public LXVector PToLXVector (PVector pv) {
	return new LXVector (pv.x, pv.y, pv.z);
}

// OGL Functions

public double min(double a, double b) {
  return a < b ? a : b;
}

public double max(double a, double b) {
  return a < b ? b : a;
}

public double clamp(double x, double range_min, double range_max) {
  return min(range_max, max(range_min, x));
}

// Convenience

float[] SPIKE_COVEREDRANGE_TOP = {.5, .2};
float[] SPIKE_COVEREDRANGE_BOTTOM = {0, 0};

public List<LXPoint> GetSpikePointsUnderUmbrella (Bloom b, boolean invert) {
  
  float spike_coveredRange_bottomPosition = ((float)b.umbrella.simulatedPosition * SPIKE_COVEREDRANGE_BOTTOM[0]) + ((1f - (float)b.umbrella.simulatedPosition) * SPIKE_COVEREDRANGE_BOTTOM[1]);
  float spike_coveredRange_topPosition = ((float)b.umbrella.simulatedPosition * SPIKE_COVEREDRANGE_TOP[0]) + ((1f - (float)b.umbrella.simulatedPosition) * SPIKE_COVEREDRANGE_TOP[1]);
  
  // TODO: need to do this in a more efficient way, since this is called inside a tight loop
  // on every animation frame, allocating a new dynamic list every time is going to be a bit
  // costly. Since there are a fixed number of LEDs on the spike, we can pre-compute a
  // look-up table/function from (double umbrellaPosition, int stripIndex) => mask
  List<LXPoint> retVal = new ArrayList<LXPoint>();
  for (LXPoint point : b.spike.getPoints()) {
    float point_distance = new LXVector(point.x, point.y, point.z).dist(b.center);
    float point_percentTotalDistance = (point_distance / b.maxSpikeDistance);
    
    boolean isUnderUmbrella = point_percentTotalDistance >= spike_coveredRange_bottomPosition && point_percentTotalDistance <= spike_coveredRange_topPosition;
    if (invert)
      isUnderUmbrella = !isUnderUmbrella;

    if (isUnderUmbrella) {
      retVal.add(point);
    }
  }

  return retVal;
}

float[] SPOKE_COVEREDRANGE_TOP = {.2, 1};
float[] SPOKE_COVEREDRANGE_BOTTOM = {0, 0};

public List<LXPoint> GetSpokePointsUnderUmbrella (Bloom b, boolean invert) {
  
  float spoke_coveredRange_bottomPosition = ((float)b.umbrella.simulatedPosition * SPOKE_COVEREDRANGE_BOTTOM[0]) + ((1f - (float)b.umbrella.simulatedPosition) * SPOKE_COVEREDRANGE_BOTTOM[1]);
  float spoke_coveredRange_topPosition = ((float)b.umbrella.simulatedPosition * SPOKE_COVEREDRANGE_TOP[0]) + ((1f - (float)b.umbrella.simulatedPosition) * SPOKE_COVEREDRANGE_TOP[1]);
  
  
  List<LXPoint> retVal = new ArrayList<LXPoint>();
  for (LXPoint point : b.spokePoints) {
    float point_distance = new LXVector(point.x, point.y, point.z).dist(b.center);
    float point_percentTotalDistance = (point_distance / b.maxSpokesDistance);
    
    boolean isUnderUmbrella = point_percentTotalDistance >= spoke_coveredRange_bottomPosition && point_percentTotalDistance <= spoke_coveredRange_topPosition;
    if (invert)
      isUnderUmbrella = !isUnderUmbrella;
    
    if (isUnderUmbrella) {
      retVal.add(point);
    }
  }

  return retVal;
}

// TODO(peter): write this
/*
public List<LXVector> GetSpokePointsUnderUmbrella (Bloom b, int spokeIndex) {

}*/
