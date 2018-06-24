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
    
    // Debug three blooms, with the ips in the array
    boolean BLOOM_DEBUG_THREE = false;
    String[] DEBUG_THREE_IPS = {
      "192.168.1.229",
      "192.168.1.230",
      "192.168.1.231"
      };
    
    int mappedBloomCount = 0;
    int universe = 0;
    for (Bloom bloom : model.blooms) {
      if (bloom.spokes.size() == 5)
        continue;
      
      JSONObject bloomConfig = config.getBloom(bloom.id);
      String ip = bloomConfig.getString("ip");
      if (ip == null) {
        println("No IP address specified for Bloom #" + bloomConfig.getInt("id"));
      } else if (!BLOOM_DEBUG_ONE || (mappedBloomCount < 1)) {
        
        buildBloomOutput(lx, output, config, bloomConfig, bloom, "192.168.1.229");

        // TODO: add DMX umbrella control outputs
        ++mappedBloomCount;
      } else if (!BLOOM_DEBUG_ONE && BLOOM_DEBUG_THREE && (mappedBloomCount < 3)) {
        if (stringIn(bloomConfig.getString("ip"), DEBUG_THREE_IPS)){
          buildBloomOutput(lx, output, config, bloomConfig, bloom, bloomConfig.getString("ip"));
        }
      }
    }
    
    lx.engine.addOutput(output);
    
  } catch (Exception x) {
    throw new RuntimeException(x);
  }
}

int calculateStartUniverseFromIp (String ip) {
  int UNIVERSES_PER_PIXLITE = 24;
  int INITIAL_IP_OFFSET = 200;
  
  String lastThree = ip.substring(ip.length() - 4, 3);
  int id = int(lastThree) - INITIAL_IP_OFFSET; // Get the zero based index

  return UNIVERSES_PER_PIXLITE * id; // Every pixlite takes up 24 universes
}

void buildBloomOutput (LX lx, LXDatagramOutput output, Config config, JSONObject bloomConfig, Bloom bloom, String ip)
{
  int universe = calculateStartUniverseFromIp(ip);
  
  List<Bloom.Spoke> shortSpokes = new ArrayList<Bloom.Spoke>();
  List<Bloom.Spoke> longSpokes = new ArrayList<Bloom.Spoke>();
  
  // Find Short Struts
  // Find Long Struts
  for (Bloom.Spoke spoke : bloom.spokes) {
    if (spoke.isShort) {
      shortSpokes.add(spoke);
    }else{
      longSpokes.add(spoke);
    }
  }
  
  println("Spoke Numbers (l:s) : " + longSpokes.size() + " : " + shortSpokes.size());
  StreamingACNDatagram datagram;
  
  try {
    // Short   
    int[] indices = makeSpokeIndices(bloom, shortSpokes.get(0), universe, 102);
    output.addDatagram(new StreamingACNDatagram(++universe, indices).setAddress(ip));
    println("Short Output: " + universe);
    
    // Spike
    output.addDatagram(new StreamingACNDatagram(++universe, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
    println("Spike Output: " + universe);
    output.addDatagram(new StreamingACNDatagram(++universe, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
    println("Spike Output: " + universe);
    output.addDatagram(new StreamingACNDatagram(++universe, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
    println("Spike Output: " + universe);
  
    // Long 
    indices = makeSpokeIndices(bloom, longSpokes.get(0), universe, 123);
    output.addDatagram(new StreamingACNDatagram(++universe, indices).setAddress(ip));
    println("Long Output: " + universe);
    
    // Long
    indices = makeSpokeIndices(bloom, longSpokes.get(1), universe, 123);
    output.addDatagram(new StreamingACNDatagram(++universe, indices).setAddress(ip));
    println("Long Output: " + universe);

    // Short
    indices = makeSpokeIndices(bloom, shortSpokes.get(0), universe, 102);
    output.addDatagram(new StreamingACNDatagram(++universe, indices).setAddress(ip));
    println("Short Output: " + universe);
    
    // Spike
    output.addDatagram(new StreamingACNDatagram(++universe, makeIndices(bloom.spike.stripB, 170, 0)).setAddress(ip));
    println("Spike Output: " + universe);
    output.addDatagram(new StreamingACNDatagram(++universe, makeIndices(bloom.spike.stripB, 170, 170)).setAddress(ip));
    println("Spike Output: " + universe);
    output.addDatagram(new StreamingACNDatagram(++universe, makeIndices(bloom.spike.stripB, 6, 340)).setAddress(ip));
    println("Spike Output: " + universe);
    
    // Long 
    indices = makeSpokeIndices(bloom, longSpokes.get(2), universe, 123);
    output.addDatagram(new StreamingACNDatagram(++universe, indices).setAddress(ip));
    println("Long Output: " + universe);
    
    // Long
    indices = makeSpokeIndices(bloom, longSpokes.get(3), universe, 123);
    output.addDatagram(new StreamingACNDatagram(++universe, indices).setAddress(ip));
    println("Long Output: " + universe);
    
    // Set up DMX output
    output.addDatagram(new RadiaNodeSpecialDatagram(bloom).setAddress(ip));
    
    println ("Universe end: " + universe);
    
  } catch (Exception x) {
    println("Runtime Exception: " + x);
    throw new RuntimeException(x);
  }
  
}

Bloom.Spoke getCorrespondingNeighborSpoke(Bloom.Spoke _spoke, int bloomIndex) {
  Bloom neighborBloom = model.blooms.get(_spoke.pointsAtBloomIndex);
  for (Bloom.Spoke n_spoke : neighborBloom.spokes) {
    if (n_spoke.pointsAtBloomIndex == bloomIndex)
      return n_spoke;
  }
  return null;
}

int[] makeSpokeIndices(Bloom _bloom, Bloom.Spoke _spoke, int _startUniverse, int num) {
  int[] indices = new int[num];
  int curr_index = 0;

  Bloom.Spoke neighborSpoke = getCorrespondingNeighborSpoke(_spoke, _bloom.id);
  
  for (int src = 0; src < _spoke.outPoints.size(); src++) {
    indices[curr_index] = _spoke.outPoints.get(src).index;
    curr_index++;
  }
  for (int src = neighborSpoke.inPoints.size() - 1; src >= 0; src--) {
    indices[curr_index] = neighborSpoke.inPoints.get(src).index;
    curr_index++;
  }
  
  return indices;
}

int[] makeIndices(LXFixture fixture, int num, int offset) {
  List<LXPoint> points = fixture.getPoints();
  return makeIndices(points, num, offset);
}

int[] makeIndices(List<LXPoint> leds, int num, int offset) {
  int[] indices = new int[num];
  for (int i = 0; i < indices.length; ++i) {
    indices[i] = leds.get(offset + (i % leds.size())).index;
  }
  return indices;
}
