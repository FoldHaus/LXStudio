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

float[] SPOKE_COVEREDRANGE_TOP = {.2, 1};
float[] SPOKE_COVEREDRANGE_BOTTOM = {0, 0};

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

public void UpdateUmbrellaMask () {

  if (UmbrellaMask_UpdatedThisFrame)
    return;
  
  float spike_coveredRange_bottomPosition;
  float spike_coveredRange_topPosition;
  float spoke_coveredRange_bottomPosition;
  float spoke_coveredRange_topPosition;

  float point_distance;
  float point_percentTotalDistance;
  
  for (Bloom b : model.blooms) {
    // Calculate Spike Covered Range
    spike_coveredRange_bottomPosition = ((float)b.umbrella.simulatedPosition * SPIKE_COVEREDRANGE_BOTTOM[0]) + ((1f - (float)b.umbrella.simulatedPosition) * SPIKE_COVEREDRANGE_BOTTOM[1]);
    spike_coveredRange_topPosition = ((float)b.umbrella.simulatedPosition * SPIKE_COVEREDRANGE_TOP[0]) + ((1f - (float)b.umbrella.simulatedPosition) * SPIKE_COVEREDRANGE_TOP[1]);
  
    // Calculate Spoke Covered Range
    spoke_coveredRange_bottomPosition = ((float)b.umbrella.simulatedPosition * SPOKE_COVEREDRANGE_BOTTOM[0]) + ((1f - (float)b.umbrella.simulatedPosition) * SPOKE_COVEREDRANGE_BOTTOM[1]);
    spoke_coveredRange_topPosition = ((float)b.umbrella.simulatedPosition * SPOKE_COVEREDRANGE_TOP[0]) + ((1f - (float)b.umbrella.simulatedPosition) * SPOKE_COVEREDRANGE_TOP[1]);

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
