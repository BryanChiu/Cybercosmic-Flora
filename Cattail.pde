class Cattail extends Flora {
  color stemCol = color(160, 110, 30);
  color headCol = color(110, 60, 10);

  Cattail(int _POSX, int _POSY) {
    this.species = FloraType.CATTAIL;
    this.POSX = _POSX;
    this.POSY = _POSY;

    this.age = 0;
    this.MAX_AGE = 65+int(random(-10, 10));
    this.GROWTH_RATE = 2;
    this.DECAY_RATE = 6;
    this.FERTILITY = 2;
    this.SPREAD = 150;
    this.water = 2;
    this.MAX_WATER = 4;
    this.WATER_RADIUS = new Vec2(50, 100);
    this.mature = false;
    this.setDynamic = false;

    Segments = new ArrayList<FloraSegDef>();
    BodyList = new ArrayList<Body>();
    SegGrownList = new ArrayList<Integer>();
  }

  ArrayList<FloraSegDef> InitSegments(boolean fullGrown) {
    Vec2 stemdim = new Vec2(4, 12);
    Vec2 headdim = new Vec2(6, 12);
    FloraSegDef segdef;
    int parentID = -1;

    float angle = random(-PI/64, PI/64);
    Vec2 branchVec = new Vec2(cos(angle+PI/2)*stemdim.y, sin(angle+PI/2)*stemdim.y);

    //stem
    int plantHeight = int(random(7, 10));
    for (int i = 0; i < plantHeight; ++i) {
      Vec2 cen = new Vec2(branchVec.x+branchVec.x*2*i, branchVec.y+branchVec.y*2*i);
      if (i<plantHeight-2) {
        segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 50, cen, stemdim, angle, new Colour().offset(stemCol, 20));
      } else {
        segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 50, cen, headdim, angle, new Colour().offset(headCol, 10));
      }
      Segments.add(segdef);
      parentID = segdef.ID;
    }

    if (fullGrown) {
      for (int i=0; i<Segments.size(); i++) {
        SegGrownList.add(i);
      }
      return Segments;
    }

    ArrayList<FloraSegDef> returnList = new ArrayList<FloraSegDef>();
    returnList.add(Segments.get(0));
    SegGrownList.add(0); //add first segment to grown list
    return returnList;
  }
  
  void BranchOff(FloraSegDef parent, int maxLength) {}
  
  int getLifeState() {
    if (age<MAX_AGE) return 0; // still living
    if (age<MAX_AGE+8) return 1; // dead, decaying, bodies w/o joints
    if (age==MAX_AGE+12 && mature) return 3; // propagate if not dead early
    if (age<MAX_AGE+16) return 2; // destroy bodies from world
    return 4;
  }
}
