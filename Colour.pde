class Colour {
  color offset(color col, int amt) {
    color retcolor = color((col >> 16 & 0xFF)+random(-amt, amt), (col >> 8 & 0xFF)+random(-amt, amt), (col & 0xFF)+random(-amt, amt));
    return retcolor;
  }
}
