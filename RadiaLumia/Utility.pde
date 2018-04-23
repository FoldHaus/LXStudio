public PVector LXToPVector (LXVector lxv) {
	return new PVector (lxv.x, lxv.y, lxv.z);
}

public LXVector PToLXVector (PVector pv) {
	return new LXVector (pv.x, pv.y, pv.z);
}
