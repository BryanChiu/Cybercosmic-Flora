class Bush extends Flora {
  color bushCol = color(50, 150, 50);

  Bush(int _POSX, int _POSY) {
    this.species = FloraType.BUSH;
    this.POSX = _POSX;
    this.POSY = _POSY;

    this.age = 0;
    this.MAX_AGE = 90+int(random(-10, 10));
    this.GROWTH_RATE = 3;
    this.DECAY_RATE = 6;
    this.FERTILITY = 2;
    this.SPREAD = 100;
    this.water = 2;
    this.MAX_WATER = 8;
    this.WATER_RADIUS = new Vec2(100, 150);
    this.mature = false;
    this.setDynamic = false;

    Segments = new ArrayList<FloraSegDef>();
    BodyList = new ArrayList<Body>();
    SegGrownList = new ArrayList<Integer>();
  }

  ArrayList<FloraSegDef> InitSegments(boolean fullGrown) {
    ArrayList<FloraSegDef> returnList = new ArrayList<FloraSegDef>();
    Vec2 segdim = new Vec2(2.5, 6);
    FloraSegDef segdef;
    int parentID;

    float angle = random(-PI/45, PI/45);

    //stem
    int plantHeight = int(random(7, 9));

    int[] arr = {0, 1, -1};
    for (int j : arr) {
      Vec2 branchVec = new Vec2(cos(angle+(PI/4)*j+PI/2)*segdim.y, sin(angle+(PI/4)*j+PI/2)*segdim.y);
      parentID = -1;

      for (int i = 0; i < plantHeight; ++i) {
        Vec2 cen = new Vec2(branchVec.x+branchVec.x*2*i, branchVec.y+branchVec.y*2*i);
        segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 30, cen, segdim, angle+(PI/4)*j, new Colour().offset(bushCol, 40));
        Segments.add(segdef);

        if (parentID==-1 && !fullGrown) {
          returnList.add(segdef);
          SegGrownList.add(Segments.size()-1);
        }

        if (random(1f)>0.1) {
          BranchOff(segdef, plantHeight-(plantHeight/4)*abs(j)-1-i);
        }

        parentID = segdef.ID;
      }

      //bulb/head
      //if (j==0) {
      //  Vec2 cen = new Vec2(branchVec.x+branchVec.x*2*plantHeight, branchVec.y+branchVec.y*2*plantHeight);
      //  segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.CIRCLE, 2, cen, new Vec2(10, 10), 0f, color(50, 0, 100));
      //  Segments.add(segdef);
      //}
    }

    if (fullGrown) {
      for (int i=0; i<Segments.size(); i++) {
        SegGrownList.add(i);
      }
      return Segments;
    }

    return returnList;
  }

  void BranchOff(FloraSegDef parent, int maxLength) {
    if (maxLength==0) return;

    FloraSegDef segdef;
    Vec2 segdim = new Vec2(3, 10);
    int parentID = parent.ID;
    int branchLength = int(random(max(1, maxLength-1), maxLength));
    int leftright = int(random(2))*2-1;
    float angle = leftright*random(3*PI/8, 5*PI/8)+parent.ang;
    Vec2 branchVec = new Vec2(cos(angle+PI/2)*segdim.y, sin(angle+PI/2)*segdim.y);

    for (int i = 0; i < branchLength; ++i) {
      Vec2 cen = new Vec2(branchVec.x+branchVec.x*2*i+parent.cen.x, branchVec.y+branchVec.y*2*i+parent.cen.y);

      segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 5, cen, segdim, angle, new Colour().offset(bushCol, 40));
      Segments.add(segdef);
      if (random(1f)>0.1 && i>0) {
        BranchOff(segdef, branchLength-1-i);
      }

      parentID = segdef.ID;
    }
  }
  
  int getLifeState() {
    if (age<MAX_AGE) return 0; // still living
    if (age<MAX_AGE+10) return 1; // dead, decaying, bodies w/o joints
    if (age==MAX_AGE+15 && mature) return 3; // propagate if not dead early
    if (age<MAX_AGE+20) return 2; // destroy bodies from world
    return 4;
  }
}
