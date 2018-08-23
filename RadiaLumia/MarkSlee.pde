@LXCategory("Form")
public class CrossSections extends RadiaLumiaPattern {
  
  public final SinLFO x = new SinLFO(model.xMin, model.xMax, 5000);
  public final SinLFO y = new SinLFO(model.yMin, model.yMax, 6000);
  public final SinLFO z = new SinLFO(model.zMin, model.zMax, 7000);

  public final CompoundParameter xw = new CompoundParameter("XWID", 0.3);
  public final CompoundParameter yw = new CompoundParameter("YWID", 0.3);
  public final CompoundParameter zw = new CompoundParameter("ZWID", 0.3);  
  public final CompoundParameter xr = new CompoundParameter("XRAT", 0.7);
  public final CompoundParameter yr = new CompoundParameter("YRAT", 0.6);
  public final CompoundParameter zr = new CompoundParameter("ZRAT", 0.5);
  public final CompoundParameter xl = new CompoundParameter("XLEV", 1);
  public final CompoundParameter yl = new CompoundParameter("YLEV", 1);
  public final CompoundParameter zl = new CompoundParameter("ZLEV", 0.5);
  
  public CrossSections(LX lx) {
    super(lx);
    println("[ CrossSections ] | Constructor");
    startModulator(x);
    startModulator(y);
    startModulator(z);
    addParams();
  }
  
  protected void addParams() {
    addParameter(xr);
    addParameter(yr);
    addParameter(zr);    
    addParameter(xw);
    addParameter(xl);
    addParameter(yl);
    addParameter(zl);
    addParameter(yw);    
    addParameter(zw);
  }
  
  void onParameterChanged(LXParameter p) {
    if (p == xr) {
      x.setPeriod(10000 - 8800*p.getValuef());
    } else if (p == yr) {
      y.setPeriod(10000 - 9000*p.getValuef());
    } else if (p == zr) {
      z.setPeriod(10000 - 9000*p.getValuef());
    }
  }
  
  float xv, yv, zv;
  
  protected void updateXYZVals() {
    xv = x.getValuef();
    yv = y.getValuef();
    zv = z.getValuef();    
  }

  public void run(double deltaMs) {
    updateXYZVals();
    
    float xlv = 100*xl.getValuef();
    float ylv = 100*yl.getValuef();
    float zlv = 100*zl.getValuef();
    
    float xwv = 100. / (10 + 40*xw.getValuef());
    float ywv = 100. / (10 + 40*yw.getValuef());
    float zwv = 100. / (10 + 40*zw.getValuef());
    
    for (LXPoint p : model.displayPoints) {
      color c = 0;
      c = PImage.blendColor(c, lx.hsb(
      lx.palette.getHuef() + p.x/10 + p.y/3, 
      constrain(140 - 1.1*abs(p.x - model.xMax/2.), 0, 100), 
      max(0, xlv - xwv*abs(p.x - xv))
        ), ADD);
      c = PImage.blendColor(c, lx.hsb(
      lx.palette.getHuef() + 80 + p.y/10, 
      constrain(140 - 2.2*abs(p.y - model.yMax/2.), 0, 100), 
      max(0, ylv - ywv*abs(p.y - yv))
        ), ADD); 
      c = PImage.blendColor(c, lx.hsb(
      lx.palette.getHuef() + 160 + p.z / 10 + p.y/2, 
      constrain(140 - 2.2*abs(p.z - model.zMax/2.), 0, 100), 
      max(0, zlv - zwv*abs(p.z - zv))
        ), ADD); 
      colors[p.index] = c;
    }
  }
}