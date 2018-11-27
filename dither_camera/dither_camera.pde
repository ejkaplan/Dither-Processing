import processing.video.*;
Capture cam;
int[][] matrix = new int[][]{
  {0, 0, 0, 7, 5}, 
  {3, 5, 7, 5, 3}, 
  {1, 3, 5, 3, 1}
};


float pixelSize = 5;
boolean dither = false;
boolean pause = false;

void setup() {
  size(640, 480);
  frameRate(20);
  cam = new Capture(this, 640, 480);
  cam.start();
}

void draw() {
  if (cam == null) return;
  if (!pause) { 
    cam.read();
  }
  if (dither) {
    image(bw_dither(cam, matrix), 0, 0);
  } else
    image(cam, 0, 0);
}

void keyPressed() {
  if (key == ' ') dither = !dither;
  else if (keyCode == UP) pixelSize++;
  else if (keyCode == DOWN) pixelSize = max(1, pixelSize-1);
  else if (key == 's') save("dither.png");
  else if (key == 'p') pause = !pause;
  else return;
}

PGraphics bw_dither(PImage img, int[][] matrix) {
  int total = 0;
  for (int[] row : matrix) {
    for (int i : row) total += i;
  }
  PGraphics out = createGraphics(img.width, img.height);
  img = img.copy();
  img.resize(int(img.width/pixelSize), int(img.height/pixelSize));
  img.loadPixels();
  float size = float(width) / img.width;
  float[][] imgGrid = new float[img.width][img.height];
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      imgGrid[x][y] = brightness(img.pixels[y*img.width+x]);
    }
  }
  out.noSmooth();
  out.beginDraw();
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      float oldPixel = imgGrid[x][y];
      float newPixel = oldPixel > 128 ? 255 : 0;
      out.fill(newPixel);
      out.stroke(newPixel);
      out.rect(map(x, 0, img.width, 0, width), map(y, 0, img.height, 0, height), size, size);
      float error = oldPixel - newPixel;
      for (int r = 0; r < matrix.length; r++) {
        for (int c = 0; c < matrix[r].length; c++) {
          int x2 = x + c - 2;
          int y2 = y + r;
          if (x2 >= 0 && x2 < img.width && y2 >= 0 && y2 < img.height) {
            imgGrid[x2][y2] += error * matrix[r][c] / total;
          }
        }
      }
    }
  }
  out.endDraw();
  return out;
}
