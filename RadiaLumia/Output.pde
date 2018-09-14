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

int DMX_UNIVERSE_OFFSET = 24;


void buildOutput(LX lx) {
    try {
        LXDatagramOutput output = new LXDatagramOutput(lx);
        
        // Only debug first bloom output...
        boolean BLOOM_DEBUG_ONE = false;
        String DEBUG_ONE_IP = "192.168.1.215";
        
        // Debug three blooms, with the ips in the array
        boolean BLOOM_DEBUG_THREE = true;
        String[] DEBUG_MULTIPLE_IPS = {
            // Top Triangle
            "192.168.1.226",
            "192.168.1.229",
            "192.168.1.236",
            
            // Ring 1
            "192.168.1.209", // Connects 36 and 29 (Betelgeuse)
            "192.168.1.206", // Connects 26 and 36 (Hale Bop)
            "192.168.1.203", // Connects 26 and 29 (Mercury)
            
            // Ring 2
            "192.168.1.234", // Connects 9 and 36 (Apophis)
            "192.168.1.240", // Connects 9 and 29 (Darik)
            "192.168.1.233", // Connects 6 and 36 (Oort)
            "192.168.1.222", // Connects 6 and 26 (Curiosity)
            "192.168.1.228", // Connects 3 and 29 (Atlantis)  
            "192.168.1.221", // Connects 3 and 26 (Earth)
            
            // Ring 3
            "192.168.1.237", // Connects 6, 22, 33 (ISS)
            "192.168.1.202", // Penta, Connects 22 and 21 (Discovery)
            "192.168.1.227", // Connects 3, 21, 28(Challenger)
            "192.168.1.208", // Penta, Connects 40 and 28 (Venus)
            "192.168.1.216", // Connects 40, 9, 34 (Gemini)
            "192.168.1.205", // Penta, Connects 33 and 34 (Pluto)
            
            "192.168.1.238",
            "192.168.1.224",
            "192.168.1.223",
            "192.168.1.214", // (Luna)
            "192.168.1.215", // (Phobos)
            "192.168.1.225", // (Rama)
            "192.168.1.218", // (Rocinante)
            "192.168.1.219", // (Galactica)
            "192.168.1.235", // (Uranus)
            "192.168.1.210", // (Philae)
            "192.168.1.200", // (Endeavor)
            "192.168.1.241", // (Icarus)
            "192.168.1.231", // (Uranus) aligned
            "192.168.1.207", // (James Webb)
            
            "192.168.1.212", // Connects 17 and 1 (Big Dipper)
            "192.168.1.213", // Connects 17 and 4 (Tycho) NOTE: We should probably replace this board
            "192.168.1.230", // Connects 32 and 4 (Serenity)
            "192.168.1.239", // Connects 32 and 11 (Apollo XIII)
            //"192.168.1.241", // Connects 11 and 20
            
            // Bottom Triangles
            "192.168.1.217", // alignedSDA
            "192.168.1.220", // aligned
            "192.168.1.232", // aligned
            
            // Manual Shells
            "192.168.1.201", // Connects 17 and 20 aligned
            "192.168.1.204", // Connects 17 and 32 aligned
            "192.168.1.211", // Connects 20 and 32 aligned
        };
        
        int mappedBloomCount = 0;
        
        for (Bloom bloom : model.blooms) {
            
            JSONObject bloomConfig = config.getBloom(bloom.id);
            String ip = bloomConfig.getString("ip");
            
            if (ip == null) {
                println("No IP address specified for Bloom #" + bloomConfig.getInt("id"));
            } else if (BLOOM_DEBUG_ONE && (mappedBloomCount < 1)) {
                
                if (bloom.spokes.size() == 6)
                {
                    buildHexaBloomOutput(lx, output, config, bloomConfig, bloom, DEBUG_ONE_IP);
                }else{
                    buildPentaBloomOutput(lx, output, config, bloomConfig, bloom, DEBUG_ONE_IP);
                }
                
                ++mappedBloomCount;
            } else if (!BLOOM_DEBUG_ONE && BLOOM_DEBUG_THREE && (mappedBloomCount < DEBUG_MULTIPLE_IPS.length)) {
                if (stringIn(bloomConfig.getString("ip"), DEBUG_MULTIPLE_IPS)){
                    
                    if (bloom.spokes.size() == 6)
                    {
                        buildHexaBloomOutput(lx, output, config, bloomConfig, bloom, bloomConfig.getString("ip"));
                    }
                    else
                    {
                        buildPentaBloomOutput(lx, output, config, bloomConfig, bloom, bloomConfig.getString("ip"));
                    }
                    
                    mappedBloomCount++;
                }
            }
        }
        
        // Heart
        String[] HeartIPs = {
          "192.168.1.150",
          "192.168.1.151"
        };
        
        boolean OutputHeart = true;
        if (OutputHeart)
        {
          int HeartStartUniverse = 2000;
          
          int HeartUniverse = HeartStartUniverse;
          int Accumulator = 0;
          int HeartIPIndex = 0;
          String HeartIP = HeartIPs[HeartIPIndex];
          
          for (Heart.Spine spine : model.heart.spines)
          {
              if (Accumulator++ >= 8)
              {
                 HeartIPIndex = 1;
              }
              HeartIP = HeartIPs[HeartIPIndex];
              
              println("Spine: " + Accumulator + " IP: " + HeartIP + " Universe: " + HeartUniverse);
              output.addDatagram(new StreamingACNDatagram(HeartUniverse++, makeIndices(spine, 170, 0)).setAddress(HeartIP));
              println("Spine: " + Accumulator + " IP: " + HeartIP + " Universe: " + HeartUniverse);
              output.addDatagram(new StreamingACNDatagram(HeartUniverse++, makeIndices(spine, 170, 170)).setAddress(HeartIP));
              println("Spine: " + Accumulator + " IP: " + HeartIP + " Universe: " + HeartUniverse);
              output.addDatagram(new StreamingACNDatagram(HeartUniverse++, makeIndices(spine, 6, 340)).setAddress(HeartIP));
          }
        }
        lx.engine.addOutput(output);
        
    } catch (Exception x) {
        throw new RuntimeException(x);
    }
}

int calculateStartUniverseFromIp (String ip) {
    int UNIVERSES_PER_PIXLITE = 25;
    int INITIAL_IP_OFFSET = 200;
    String lastThree = ip.substring(ip.length() - 3);
    int id = int(lastThree) - INITIAL_IP_OFFSET; // Get the zero based index
    return (UNIVERSES_PER_PIXLITE * id); // Every pixlite takes up 24 universes
}


int[] PENTA_BASE_SPOKE_ORDER = {0, 1, 2, 3, 4 };
int[] PENTA_MIRRORED_SPOKE_ORDER = { 4, 3, 2, 1, 0};

void buildPentaBloomOutput (LX lx, 
                            LXDatagramOutput output,
                            Config config,
                            JSONObject bloomConfig,
                            Bloom bloom, String ip)
{
    int start_universe = calculateStartUniverseFromIp(ip);
    int universe = start_universe;
    if(universe == 0)
        universe++;
    
    println("IP: " + ip + " Start Universe: " + start_universe + " DMX: " + (start_universe + DMX_UNIVERSE_OFFSET));
    
    int OrderedSpikeIndex = 0;
    int[] SpikeIndexOrder = PENTA_BASE_SPOKE_ORDER;
    if (bloom.MirrorOutputs)
    {
        SpikeIndexOrder = PENTA_MIRRORED_SPOKE_ORDER;
    }
    
    int[] CopyArray = new int[5];
    
    println();
    println("Remapping");
    println(SpikeIndexOrder);
    println();
    
    for (int i = 0; i < SpikeIndexOrder.length; i++)
    {
        int inValue = i;
        int outValue = (i + bloom.FlipValue) % SpikeIndexOrder.length;
        int valAtIndex = SpikeIndexOrder[outValue];
        
        println(" - " + inValue + " : " + outValue + " : " + valAtIndex);
        
        CopyArray[inValue] = SpikeIndexOrder[outValue];
    }
    
    SpikeIndexOrder = CopyArray;
    
    println();
    println(SpikeIndexOrder);
    println();
    
    try {
        // Mod 5 to ensure the value is always within 0-5 range
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " + universe);
        int[] indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        // Spike
        println("Spike 1" + ": " + universe);
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " + universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " +  universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " +  universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        // Spike
        println("Spike 2" + ": " + universe);
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " + universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        // Set up DMX output
        if (RadiaNodeDatagramCount == 9)
          println("CREATING #9");
        RadiaNodeDatagrams[RadiaNodeDatagramCount] = new RadiaNodeSpecialDatagram(start_universe + DMX_UNIVERSE_OFFSET, bloom);
        RadiaNodeDatagrams[RadiaNodeDatagramCount].setAddress(ip);
        output.addDatagram((LXDatagram)RadiaNodeDatagrams[RadiaNodeDatagramCount]);
        RadiaNodeDatagramCount++;
        
    } catch (Exception x) {
        println("Runtime Exception: " + x);
        throw new RuntimeException(x);
    }
}

int[] HEXA_BASE_SPOKE_ORDER = {0, 1, 2, 3, 4, 5};
int[] HEXA_FLIPPED_SPOKE_ORDER = {3, 4, 5, 0, 1, 2};
int[] HEXA_MIRRORED_SPOKE_ORDER = {0, 5, 4, 3, 2, 1};
int[] HEXA_FLIPPED_MIRRORED_SPOKE_ORDER = {3, 2, 1, 0, 5, 4};

void buildHexaBloomOutput (LX lx, LXDatagramOutput output, Config config, JSONObject bloomConfig, Bloom bloom, String ip)
{
    int start_universe = calculateStartUniverseFromIp(ip);
    int universe = start_universe;
    
    println("IP: " + ip + " Start Universe: " + start_universe + " DMX: " + (start_universe + DMX_UNIVERSE_OFFSET));
    
    int OrderedSpokeIndex = 0;
    int[] SpokeIndexOrder = HEXA_BASE_SPOKE_ORDER;
    if (bloom.FlipValue > 0)
    {
        if (bloom.MirrorOutputs)
        {
            println("MIRRORED + FLIPPED");
            SpokeIndexOrder = HEXA_FLIPPED_MIRRORED_SPOKE_ORDER;
        }
        else
        {
            println("FLIPPED");
            SpokeIndexOrder = HEXA_FLIPPED_SPOKE_ORDER;
        }
    }
    else
    {
        if (bloom.MirrorOutputs)
        {
            println("MIRRORED");
            SpokeIndexOrder = HEXA_MIRRORED_SPOKE_ORDER;
        }
        else
        {
            // Base Order
        }
    }
    
    try {
        
        // Short
        println("Short 0: " + SpokeIndexOrder[OrderedSpokeIndex]);
        int[] indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Spike
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        // Long 
        println("Long 0: " + SpokeIndexOrder[OrderedSpokeIndex]);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Long
        println("Long 1: " + SpokeIndexOrder[OrderedSpokeIndex]);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Short
        println("Short 1: " + SpokeIndexOrder[OrderedSpokeIndex]);
        println("SpokeIndex: " + SpokeIndexOrder[OrderedSpokeIndex] + " Universe: " + universe +" Before: " + OrderedSpokeIndex);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        
        OrderedSpokeIndex++;
        println("SpokeIndex: " + SpokeIndexOrder[OrderedSpokeIndex] + " Universe: " + universe + " After: " + OrderedSpokeIndex);
        
        // Spike
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 6, 340)).setAddress(ip));
        
        // Long 
        println("Long 2: " + SpokeIndexOrder[OrderedSpokeIndex]);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Long
        println("Long 3: " + SpokeIndexOrder[OrderedSpokeIndex]);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Set up DMX output
        RadiaNodeDatagrams[RadiaNodeDatagramCount] = new RadiaNodeSpecialDatagram(start_universe + DMX_UNIVERSE_OFFSET, bloom);
        RadiaNodeDatagrams[RadiaNodeDatagramCount].setAddress(ip);
        output.addDatagram((LXDatagram)RadiaNodeDatagrams[RadiaNodeDatagramCount]);
        RadiaNodeDatagramCount++;
        
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
