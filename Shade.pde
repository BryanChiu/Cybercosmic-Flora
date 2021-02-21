class Shade {
  PGraphics circ;
  int posX;
  int posY;
  float opacity;

  Body sensor;

  Shade (int posX, int posY) {
    this.posX = posX;
    this.posY = posY;
    this.opacity = 0;
  }
  
  void Update(int contactCount) {
    opacity = constrain(contactCount/500.0, 0, 0.9);
  }
  
  void Display() {
    tint(255, int(opacity*255));
    image(circ, posX, posY, 50+opacity*1300, opacity*200);
  }

  void Display(float opac, int w, int h) {
    tint(255, int(opac*255));
    image(circ, posX, posY, w, h);
  }

  void setPGraphic(PGraphics pg) {
    this.circ = pg;
  }

  void setSensor(Body body) {
    this.sensor = body;
  }
  
  Body getSensor() {
    return sensor;
  }
}
