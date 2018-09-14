/** 
 * By using LX Studio, you agree to the terms of the LX Studio Software
 * License and Distribution Agreement, available at: http://lx.studio/license
 *
 * Please note that the LX license is not open-source. The license
 * allows for free, non-commercial use.
 *
 * HERON ARTS MAKES NO WARRANTY, EXPRESS, IMPLIED, STATUTORY, OR
 * OTHERWISE, AND SPECIFICALLY DISCLAIMS ANY WARRANTY OF
 * MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR A PARTICULAR
 * PURPOSE, WITH RESPECT TO THE SOFTWARE.
 */

// ---------------------------------------------------------------------------
//
// Welcome to LX Studio! Getting started is easy...
// 
// (1) Quickly scan this file
// (2) Look at "Model" to define your model
// (3) Move on to "Patterns" to write your animations
// 
// ---------------------------------------------------------------------------

// Reference to top-level LX instance
heronarts.lx.studio.LXStudio lx;

Config config;
Model model;
UIRadiaLumia umbrellaModel;

int RadiaNodeDatagramCount = 0;
RadiaNodeSpecialDatagram[] RadiaNodeDatagrams;

boolean USE_PROJECT_CONTROLLER = false;
ProjectController ProjController;
RadiaProjectListener ProjListener;

Sensors sensors;

// Global UI Objects
UIProjectControls uiProjectControls;
UISensors uiSensors;
UIDMXControls uiDMXControls;
// UIOutputControls uiOutputControls;

ArtHausPerformance artHaus;

void setup() {
    // Processing setup, constructs the window and the LX instance
    size(1200, 960, P3D);
    config = new Config();
    model = new Model(config);
    sensors = new Sensors();

    lx = new heronarts.lx.studio.LXStudio(this, model, MULTITHREADED);
    lx.ui.setResizable(RESIZABLE);

    sensors.config(lx);
    
    if (USE_PROJECT_CONTROLLER)
    {
        ProjController = new ProjectController(lx);
        ProjListener = new RadiaProjectListener();
        lx.addProjectListener((LX.ProjectListener)ProjListener);
        
        // NOTE (Trip) - Can't put in onUIReady...ProjController returning nullPointerException...
        uiProjectControls = (UIProjectControls)new UIProjectControls(
        lx.ui,
        lx.ui.leftPane.global.getContentWidth(),
        ProjController
        ).addToContainer((UIContainer)lx.ui.leftPane.global);
        lx.addProjectListener(uiProjectControls);
    }
    // Arthaus
    // TEMPORARY
    //artHaus = new ArtHausPerformance(lx);
}

void initialize(final heronarts.lx.studio.LXStudio lx, heronarts.lx.studio.LXStudio.UI ui) {
    RadiaNodeDatagrams = new RadiaNodeSpecialDatagram[42];
    buildOutput(lx);
    
    // Add a loop task to rate-limit and simulate umbrella position
    lx.engine.addLoopTask(new LXLoopTask() {
                          public void loop(double deltaMs) {
                          int[] colors = lx.getColors();
                          for (Bloom bloom : model.blooms) {
                          bloom.umbrella.update(deltaMs, colors);
                          }
                          }
                          });
    
    InitializeUmbrellaMask();
}

void onUIReady(heronarts.lx.studio.LXStudio lx, heronarts.lx.studio.LXStudio.UI ui) {
    /* TODO(peter): model.leds doesn't and shouldn't include the pin spots. Create a
    new ArrayList called displayedInPointCloud, and use it here. Grrrr
    */
    // TODO: Modify position of simulation in the screen
    // ui.preview.setRadius(80*FEET).setPhi(-PI/18).setTheta(PI/12);
    // ui.preview.setCenter(0, model.cy - 2*FEET, 0);
    ui.preview.pointCloud.setModel(new LXModel(model.displayPoints));
    ui.preview.addComponent(new UISimulation());

    // Narrow angle lens, for a fuller visualization
    ui.preview.perspective.setValue(30);


    // Add custom UI components here
    uiSensors = (UISensors)new UISensors(
    lx.ui,
    sensors,
    lx.ui.leftPane.global.getContentWidth()).addToContainer((UIContainer)lx.ui.leftPane.global);

    uiDMXControls = (UIDMXControls) new UIDMXControls(lx.ui, lx.ui.leftPane.global.getContentWidth()).addToContainer((UIContainer)lx.ui.leftPane.global);
    // uiOutputControls = (UIOutputControls) new UIOutputControls(
    // lx.ui,
    // lx.ui.leftPane.global.getContentWidth()
    // ).addToContainer((UIContainer)lx.ui.leftPane.global);
}

void draw() {
    // All is handled by LX Studio
    
}

// Configuration flags
final static boolean MULTITHREADED = true;
final static boolean RESIZABLE = true;

// Helpful global constants
final static float INCHES = 1;
final static float IN = INCHES;
final static float FEET = 12 * INCHES;
final static float FT = FEET;
final static float CM = IN / 2.54;
final static float MM = CM * .1;
final static float M = CM * 100;
final static float METER = M;

final static float PI = 3.1415;
final static float TWO_PI = PI * 2;

final static float SECONDS = 1000;

final static float UI_PADDING = 4;
