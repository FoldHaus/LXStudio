// sACN E1.31 Protocol http://tsp.esta.org/tsp/documents/docs/E1-31-2016.pdf
// LXStudio API for StreamingACNDatagram http://lx.studio/api/heronarts/lx/output/StreamingACNDatagram.html#StreamingACNDatagram-int:A-
// Each E1.31 packet specifies a single universe = 512 channels = 170 LEDs
// Each PixLite 4 MkII supports 24 universe of pixel output over 8 physical output channels, up to 4080 LEDs
// Each hub will have between 1320 - 2328 LEDs || 8-14 universes || 8-14 Datagrams per frame per Hub

// Sample Setup
// 1 Output per Geodesic Edge = 5-6 Outputs, each with 2m LEDs = 288 LEDs
// Universes 1-12 = Geodesic Edges
// Universe 14-16 = Spike (2 Output, 300 LEDs each)
// Universe 24 = DMX Motor Control


void buildOutput(LX lx) {
  try {
    LXDatagramOutput output = new LXDatagramOutput(lx);
    
    // Only debug first bloom output...
    boolean BLOOM_DEBUG_ONE = true;
    int mappedBloomCount = 0;
    
    for (Bloom bloom : model.blooms) {
      JSONObject bloomConfig = config.getBloom(bloom.id);
      String ip = bloomConfig.getString("ip");
      if (ip == null) {
        println("No IP address specified for Bloom #" + bloomConfig.getInt("id"));
      } else if (!BLOOM_DEBUG_ONE || (mappedBloomCount < 1)) {
        int universe = 1;
        for (Bloom.Spoke spoke : bloom.spokes) {
          output.addDatagram(new StreamingACNDatagram(universe, makeIndices(spoke, 170)).setAddress(ip));
          output.addDatagram(new StreamingACNDatagram(universe + 1, makeIndices(spoke, 118)).setAddress(ip));
          universe += 2;
        }
        output.addDatagram(new StreamingACNDatagram(14, LXFixture.Utils.getIndices(bloom.spike)).setAddress(ip));
        
        // TODO: add DMX umbrella control outputs
        ++mappedBloomCount;
      }
    }
    
    lx.engine.addOutput(output);
    
  } catch (Exception x) {
    throw new RuntimeException(x);
  }
}

int[] makeIndices(LXFixture fixture, int num) {
  List<LXPoint> points = fixture.getPoints();
  int[] indices = new int[num];
  for (int i = 0; i < indices.length; ++i) {
    indices[i] = points.get(i % points.size()).index;
  }
  return indices;
}
