import org.apache.commons.math3.util.FastMath;

//----------------------------------------------------------------------------------------------------------------------------------
boolean btwn  	(int 		a,int 	 b,int 		c)		{ return a >= b && a <= c; 	}
boolean btwn  	(double 	a,double b,double 	c)		{ return a >= b && a <= c; 	}
float	interp 	(float a, float b, float c) { return (1-a)*b + a*c; }
float	randctr	(float a) { return random(a) - a*.5; }
float	min		(float a, float b, float c, float d) { return min(min(a,b),min(c,d)); 	}
float   pointDist(LXPoint p1, LXPoint p2) { return dist(p1.x,p1.y,p1.z,p2.x,p2.y,p2.z); 	}
float   xyDist   (LXPoint p1, LXPoint p2) { return dist(p1.x,p1.y,p2.x,p2.y); 				}
float 	distToSeg(float x, float y, float x1, float y1, float x2, float y2) {
	float A 			= x - x1, B = y - y1, C = x2 - x1, D = y2 - y1;
	float dot 			= A * C + B * D, len_sq	= C * C + D * D;
	float xx, yy,param 	= dot / len_sq;
	
	if (param < 0 || (x1 == x2 && y1 == y2)) { 	xx = x1; yy = y1; }
	else if (param > 1) {						xx = x2; yy = y2; }
	else {										xx = x1 + param * C;
												yy = y1 + param * D; }
	float dx = x - xx, dy = y - yy;
	return sqrt(dx * dx + dy * dy);
}


public class DBool {
	boolean def, b;
	String	tag;
	int		row, col;
	void 	reset() { b = def; }
	boolean set	(int r, int c, boolean val) { if (r != row || c != col) return false; b = val; return true; }
	boolean toggle(int r, int c) { if (r != row || c != col) return false; b = !b; return true; }
	DBool(String _tag, boolean _def, int _row, int _col) {
		def = _def; b = _def; tag = _tag; row = _row; col = _col;
	}
}

static public float angleBetween(PVector v1, PVector v2) {

  // We get NaN if we pass in a zero vector which can cause problems
  // Zero seems like a reasonable angle between a (0,0,0) vector and something else
  if (v1.x == 0 && v1.y == 0 && v1.z == 0 ) return 0.0f;
  if (v2.x == 0 && v2.y == 0 && v2.z == 0 ) return 0.0f;

  double dot = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
  double v1mag = FastMath.sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z);
  double v2mag = FastMath.sqrt(v2.x * v2.x + v2.y * v2.y + v2.z * v2.z);
  // This should be a number between -1 and 1, since it's "normalized"
  double amt = dot / (v1mag * v2mag);
  // But if it's not due to rounding error, then we need to fix it
  // http://code.google.com/p/processing/issues/detail?id=340
  // Otherwise if outside the range, acos() will return NaN
  // http://www.cppreference.com/wiki/c/math/acos
  if (amt <= -1) {
    return PConstants.PI;
  } else if (amt >= 1) {
    // http://code.google.com/p/processing/issues/detail?id=435
    return 0;
  }
  return (float) FastMath.acos(amt);
}
//----------------------------------------------------------------------------------------------------------------------------------
public abstract class DPat extends RadiaLumiaPattern
{
	ArrayList<DBool>  bools  = new ArrayList<DBool> ();
    PVector pTrans= new PVector(); 
	PVector		mMax, mCtr, mHalf;

	float		LastJog = -1;
	float[]		xWaveNz, yWaveNz;
	int 		nPoint	, nPoints;
	PVector		xyzJog = new PVector(), modmin;

	float			NoiseMove	= random(10000);
	CompoundParameter	pSpark, pWave, pRotX, pRotY, pRotZ, pSpin, pTransX, pTransY;
	BooleanParameter			pXsym, pYsym, pRsym, pXdup, pXtrip, pJog, pGrey;

	float		lxh		() 									{ return 360.0;  											} // Add parameter here
	int			c1c		 (float a) 							{ return round(100*constrain(a,0,1));								}
	float 		interpWv(float i, float[] vals) 			{ return interp(i-floor(i), vals[floor(i)], vals[ceil(i)]); 		}
	void 		setNorm (PVector vec)						{ vec.set(vec.x/mMax.x, vec.y/mMax.y, vec.z/mMax.z); 				}
	void		setRand	(PVector vec)						{ vec.set(random(mMax.x), random(mMax.y), random(mMax.z)); 			}
	void		setVec 	(PVector vec, LXPoint p)				{ vec.set(p.x, p.y, p.z);  											}
	void		interpolate(float i, PVector a, PVector b)	{ a.set(interp(i,a.x,b.x), interp(i,a.y,b.y), interp(i,a.z,b.z)); 	}
	void  		StartRun(double deltaMs) 					{ }
	float 		val		(CompoundParameter p) 					{ return p.getValuef();												}
	color		CalcPoint(PVector p) 						{ return lx.hsb(0,0,0); 											}
	color		blend3(color c1, color c2, color c3)		{ return PImage.blendColor(c1,PImage.blendColor(c2,c3,ADD),ADD); 					}

	void	rotateZ (PVector p, PVector o, float nSin, float nCos) { p.set(    nCos*(p.x-o.x) - nSin*(p.y-o.y) + o.x    , nSin*(p.x-o.x) + nCos*(p.y-o.y) + o.y,p.z); }
	void	rotateX (PVector p, PVector o, float nSin, float nCos) { p.set(p.x,nCos*(p.y-o.y) - nSin*(p.z-o.z) + o.y    , nSin*(p.y-o.y) + nCos*(p.z-o.z) + o.z    ); }
	void	rotateY (PVector p, PVector o, float nSin, float nCos) { p.set(    nSin*(p.z-o.z) + nCos*(p.x-o.x) + o.x,p.y, nCos*(p.z-o.z) - nSin*(p.x-o.x) + o.z    ); }

	CompoundParameter	addParam(String label, double value) 	{ CompoundParameter p = new CompoundParameter(label, value); addParameter(p); return p; }
    CompoundParameter  addParam(String label, double value, double min, double max)  { CompoundParameter p2 = new CompoundParameter(label, value, min, max); addParameter(p2); return p2; }
	PVector 	vT1 = new PVector(), vT2 = new PVector();
	float 		calcCone (PVector v1, PVector v2, PVector c) 	{	vT1.set(v1); vT2.set(v2); vT1.sub(c); vT2.sub(c);
																	return degrees(angleBetween(vT1,vT2)); }


	// void    onInactive()      {}

	// void 		onReset() 				{
	// 	for (int i=0; i<bools .size(); i++) bools.get(i).reset();
	// 	// presetManager.dirty(this); // How did presetManager change? 
	// //	updateLights(); now handled by patternControl UI
	// }

	DPat(LX lx) {
		super(lx);
		println("DPat created");

		pSpark		=	addParam("Sprk",  0);
		pWave		=	addParam("Wave",  0);
		pTransX		=	addParam("TrnX", .5);
		pTransY		=	addParam("TrnY", .5);
		pRotX 		= 	addParam("RotX", .5);
		pRotY 		= 	addParam("RotY", .5);
		pRotZ 		= 	addParam("RotZ", .5);
		pSpin		= 	addParam("Spin", .5);


    	pXsym = new BooleanParameter("X-SYM");
    	pYsym = new BooleanParameter("Y-SYM");
    	pRsym = new BooleanParameter("R-SYM");
    	pXdup = new BooleanParameter("X-DUP");
    	pJog = new BooleanParameter("JOG");
    	pGrey = new BooleanParameter("GREY");

    	addParameter(pXsym);
    	addParameter(pYsym);
    	addParameter(pRsym);
    	addParameter(pXdup);
    	addParameter(pJog);
    	addParameter(pGrey);

		nPoints 	=	model.size;
		
		// addMultipleParameterUIRow("Bools",pXsym,pYsym,pRsym,pXdup,pJog,pGrey);

		modmin		=	new PVector(model.xMin, model.yMin, model.zMin);
		mMax		= 	new PVector(model.xMax, model.yMax, model.zMax); mMax.sub(modmin);
		mCtr		= 	new PVector(); mCtr.set(mMax); mCtr.mult(.5);
		mHalf		= 	new PVector(.5,.5,.5);
		xWaveNz		=	new float[ceil(mMax.y)+1];
		yWaveNz		=	new float[ceil(mMax.x)+1];
	}

	float spin() {
	  float raw = val(pSpin);
	  if (raw <= 0.45) {
	    return raw + 0.05;
	  } else if (raw >= 0.55) {
	    return raw - 0.05;
    }
    return 0.5;
	}

	// void updateLights() {}

	void run(double deltaMs)
	{
		println("Noise run");
		if (deltaMs > 100) return;

		NoiseMove   	+= deltaMs; NoiseMove = NoiseMove % 1e7;
		StartRun		(deltaMs);
		PVector P 		= new PVector(), tP = new PVector(), pSave = new PVector();
		pTrans.set(val(pTransX)*200-100, val(pTransY)*100-50,0);
		nPoint 	= 0;

		if (pJog.getValueb()) {
			float tRamp	= (lx.tempo.rampf() % .25);
			if (tRamp < LastJog) xyzJog.set(randctr(mMax.x*.2), randctr(mMax.y*.2), randctr(mMax.z*.2));
			LastJog = tRamp; 
		}

		// precalculate this stuff
		float wvAmp = val(pWave), sprk = val(pSpark);
		if (wvAmp > 0) {
			for (int i=0; i<ceil(mMax.x)+1; i++)
				yWaveNz[i] = wvAmp * (noise(i/(mMax.x*.3)-(2e3+NoiseMove)/1500.) - .5) * (mMax.y/2.);

			for (int i=0; i<ceil(mMax.y)+1; i++)
				xWaveNz[i] = wvAmp * (noise(i/(mMax.y*.3)-(1e3+NoiseMove)/1500.) - .5) * (mMax.x/2.);
		}

		for (LXPoint p : model.points) { nPoint++;
			setVec(P,p);
			P.sub(modmin);
			P.sub(pTrans);
			if (sprk  > 0) {P.y += sprk*randctr(50); P.x += sprk*randctr(50); P.z += sprk*randctr(50); }
			if (wvAmp > 0) 	P.y += interpWv(p.x-modmin.x, yWaveNz);
			if (wvAmp > 0) 	P.x += interpWv(p.y-modmin.y, xWaveNz);
			if (pJog.getValueb())		P.add(xyzJog);


			color cNew, cOld = colors[p.index];
							{ tP.set(P); 				  					cNew = CalcPoint(tP);							}
 			if (pXsym.getValueb())	{ tP.set(mMax.x-P.x,P.y,P.z); 					cNew = PImage.blendColor(cNew, CalcPoint(tP), ADD);	}
			if (pYsym.getValueb()) 	{ tP.set(P.x,mMax.y-P.y,P.z); 					cNew = PImage.blendColor(cNew, CalcPoint(tP), ADD);	}
			if (pRsym.getValueb()) 	{ tP.set(mMax.x-P.x,mMax.y-P.y,mMax.z-P.z);		cNew = PImage.blendColor(cNew, CalcPoint(tP), ADD);	}
			if (pXdup.getValueb()) 	{ tP.set((P.x+mMax.x*.5)%mMax.x,P.y,P.z);		cNew = PImage.blendColor(cNew, CalcPoint(tP), ADD);	}
			if (pGrey.getValueb())	{ cNew = lx.hsb(0, 0, LXColor.b(cNew)); }
			colors[p.index] = cNew;
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------------------
public class NDat {
	float 	xz, yz, zz, hue, speed, angle, den;
	float	xoff,yoff,zoff;
	float	sinAngle, cosAngle;
	boolean isActive;
	NDat 		  () { isActive=false; }
	boolean	Active() { return isActive; }
	void	set 	(float _hue, float _xz, float _yz, float _zz, float _den, float _speed, float _angle) {
		isActive = true;
		hue=_hue; xz=_xz; yz=_yz; zz =_zz; den=_den; speed=_speed; angle=_angle;
		xoff = random(100e3); yoff = random(100e3); zoff = random(100e3);
     
	}
}

public class Noise extends DPat
{
	int				CurAnim, iSymm;
	int 			XSym=1,YSym=2,RadSym=3;
	float 			zTime , zTheta=0, zSin, zCos, rtime, ttime;
	CompoundParameter	pSpeed , pDensity, pSharp;
	DiscreteParameter 		pChoose, pSymm;
	int				_ND = 4;
	NDat			N[] = new NDat[_ND];

	Noise(LX lx) {
		super(lx);
		println("Noise created");
		pSpeed = new CompoundParameter("Speed", .55, -2, 2); 
		addParameter(pSpeed);
		pDensity	= addParam("Dens" 	 , .3);
		pSharp		= addParam("Shrp" 	 ,  0);
		pSymm 		= new DiscreteParameter("Symm" , new String[] {"None", "X", "Y", "Rad"}	);
		pChoose 	= new DiscreteParameter("Anim", new String[] {"Drip", "Cloud", "Rain", "Fire", "Mach", "Spark","VWav", "Wave"}	);
		pChoose.setValue(6);
		addParameter(pSymm);
		addParameter(pChoose);
    	// addSingleParameterUIRow(pChoose);
    	// addSingleParameterUIRow(pSymm);
		for (int i=0; i<_ND; i++) N[i] = new NDat();
	}

	void onActive() { zTime = random(500); zTheta=0; rtime = 0; ttime = 0; }

	void StartRun(double deltaMs) {
		zTime 	+= deltaMs*(1*val(pSpeed)-.50) * .002;
		zTheta	+= deltaMs*(spin()-.5)*.01	;
		rtime	+= deltaMs;
		iSymm	 = pSymm.getValuei();
		zSin	= sin(zTheta);
		zCos	= cos(zTheta);

		if (pChoose.getValuei() != CurAnim) {
			CurAnim = pChoose.getValuei(); ttime = rtime;
			pSpin		.reset();	zTheta 		= 0;
			pDensity	.reset();	pSpeed		.reset();
			for (int i=0; i<_ND; i++) { N[i].isActive = false; }
			
			switch(CurAnim) {
			//               hue xz  yz  zz den mph angle
			case 0: N[0].set(0  ,75 ,75 ,150,45 ,3  ,0  ); 
			        N[1].set(20, 25, 50, 50, 25, 1, 0 ); 
                    N[2].set(80, 25, 50, 50, 15, 2, 0 );  
                    pSharp.setValue(1 );   break;  // drip
			case 1: N[0].set(0  ,100,100,200,45 ,3  ,180); pSharp.setValue(0 ); break;	// clouds
			case 2: N[0].set(0  ,2  ,400,2  ,20 ,3  ,0  ); pSharp.setValue(.5); break;	// rain
			case 3: N[0].set(40 ,100,100,200,10 ,1  ,180); 
					N[1].set(0  ,100,100,200,10 ,5  ,180); pSharp.setValue(0 ); break;	// fire 1
			case 4: N[0].set(0  ,40 ,40 ,40 ,15 ,2.5,180);
					N[1].set(20 ,40 ,40 ,40 ,15 ,4  ,0  );
					N[2].set(40 ,40 ,40 ,40 ,15 ,2  ,90 );
                    N[3].set(60 ,40 ,40 ,40 ,15 ,3  ,-90); pSharp.setValue(.5); break; // machine				
			case 5: N[0].set(0  ,400,100,2  ,15 ,3  ,90 );
					N[1].set(20 ,400,100,2  ,15 ,2.5,0  );
					N[2].set(40 ,100,100,2  ,15 ,2  ,180);
					N[3].set(60 ,100,100,2  ,15 ,1.5,270); pSharp.setValue(.5); break; // spark
			}
		}
		
		for (int i=0; i<_ND; i++) if (N[i].Active()) {
			N[i].sinAngle = sin(radians(N[i].angle));
			N[i].cosAngle = cos(radians(N[i].angle));
		}
	}

	color CalcPoint(PVector p) {
		color c = 0;
		rotateZ(p, mCtr, zSin, zCos);
        //rotateY(p, mCtr, ySin, yCos);
        //rotateX(p, mCtr, xSin, xCos); 
		if (CurAnim == 6 || CurAnim == 7) {
			setNorm(p);
			return lx.hsb(lxh(),100, 100 * (
							constrain(1-50*(1-val(pDensity))*abs(p.y-sin(zTime*10  + p.x*(300))*.5 - .5),0,1) + 
			(CurAnim == 7 ? constrain(1-50*(1-val(pDensity))*abs(p.x-sin(zTime*10  + p.y*(300))*.5 - .5),0,1) : 0))
			);
		}			

		if (iSymm == XSym && p.x > mMax.x/2) p.x = mMax.x-p.x;
		if (iSymm == YSym && p.y > mMax.y/2) p.y = mMax.y-p.y;

		for (int i=0;i<_ND; i++) if (N[i].Active()) {
			NDat  n     = N[i];
			float zx    = zTime * n.speed * n.sinAngle,
				  zy    = zTime * n.speed * n.cosAngle;

			float b     = (iSymm==RadSym ? (zTime*n.speed+n.xoff-p.dist(mCtr)/n.xz)
										 : noise(p.x/n.xz+zx+n.xoff,p.y/n.yz+zy+n.yoff,p.z/n.zz+n.zoff))
							*1.8;

			b += 	n.den/100 -.4 + val(pDensity) -1;
 		c = 	PImage.blendColor(c,lx.hsb(lxh()+n.hue,100,c1c(b)),ADD);
		}
		return c;
	}
}