public PVector LXToPVector (LXVector lxv) {
	return new PVector (lxv.x, lxv.y, lxv.z);
}

public LXVector PToLXVector (PVector pv) {
	return new LXVector (pv.x, pv.y, pv.z);
}

float[] SPIKE_COVEREDRANGE_TOP = {.5, .2};
float[] SPIKE_COVEREDRANGE_BOTTOM = {0, 0};

public List<LXPoint> GetSpikePointsUnderUmbrella (Bloom b, boolean invert) {
  
  float spike_coveredRange_bottomPosition = ((float)b.umbrella.GetPercentClosed() * SPIKE_COVEREDRANGE_BOTTOM[0]) + ((1f - (float)b.umbrella.GetPercentClosed()) * SPIKE_COVEREDRANGE_BOTTOM[1]);
  float spike_coveredRange_topPosition = ((float)b.umbrella.GetPercentClosed() * SPIKE_COVEREDRANGE_TOP[0]) + ((1f - (float)b.umbrella.GetPercentClosed()) * SPIKE_COVEREDRANGE_TOP[1]);
  
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
  
  float spoke_coveredRange_bottomPosition = ((float)b.umbrella.GetPercentClosed() * SPOKE_COVEREDRANGE_BOTTOM[0]) + ((1f - (float)b.umbrella.GetPercentClosed()) * SPOKE_COVEREDRANGE_BOTTOM[1]);
  float spoke_coveredRange_topPosition = ((float)b.umbrella.GetPercentClosed() * SPOKE_COVEREDRANGE_TOP[0]) + ((1f - (float)b.umbrella.GetPercentClosed()) * SPOKE_COVEREDRANGE_TOP[1]);
  
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
