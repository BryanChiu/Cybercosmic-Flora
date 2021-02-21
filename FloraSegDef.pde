class FloraSegDef {
  int ID;
  int parentID;
  ShapeType sType;
  float density;
  Vec2 cen;
  Vec2 dim;
  float ang;
  color col;
  
  FloraSegDef(int ID, int parentID, ShapeType sType, float density, Vec2 cen, Vec2 dim, float ang, color col) {
    this.ID = ID;
    this.parentID = parentID;
    this.density = density;
    this.sType = sType;
    this.cen = cen;
    this.dim = dim;
    this.ang = ang;
    this.col = col;
  }
}
    
      
