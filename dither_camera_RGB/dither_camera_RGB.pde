import processing.video.*;
Capture cam;
int[][] matrix = new int[][]{
  {0, 0, 0, 7, 5}, 
  {3, 5, 7, 5, 3}, 
  {1, 3, 5, 3, 1}
};
//int[][] matrix = new int[][]{
//  {0, 0, 1}, 
//  {0, 0, 0}
//}; // What the heck is happening here?


float pixelSize = 5;
int mode = 0;
boolean pause = false;
boolean mirror = false;

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
  PImage disp;
  if (mode == 0) {
    disp = cam;
  } else if (mode == 1) {
    disp = bw_dither(cam, matrix);
  } else {
    disp = rgb_dither(cam, matrix);
  }
  if (mirror) {
    pushMatrix();
    scale(-1, 1);
    image(disp, -disp.width, 0, width, height);
    popMatrix();
  } else {
    image(disp, 0, 0, width, height);
  }
}

void keyPressed() {
  if (key == ' ') mode = (mode+1)%3;
  else if (keyCode == UP) pixelSize++;
  else if (keyCode == DOWN) pixelSize = max(1, pixelSize-1);
  else if (key == 's') save("dither.png");
  else if (key == 'p') pause = !pause;
  else if (key == 'm') mirror = !mirror;
  else return;
}

PImage[] channels(PImage img) {
  PImage[] out = new PImage[3];
  img.loadPixels();
  for (int i = 0; i < 3; i++) {
    out[i] = createImage(img.width, img.height, RGB);
    out[i].loadPixels();
    if (i == 0)
      for (int j = 0; j < img.pixels.length; j++) 
        out[i].pixels[j] = color(img.pixels[j] >> 16 & 0xFF);
    else if (i == 1)
      for (int j = 0; j < img.pixels.length; j++) 
        out[i].pixels[j] = color(img.pixels[j] >> 8 & 0xFF);
    else
      for (int j = 0; j < img.pixels.length; j++) 
        out[i].pixels[j] = color(img.pixels[j] & 0xFF);
    out[i].updatePixels();
  }
  return out;
}

PGraphics rgb_dither(PImage img, int[][] matrix) {
  PImage[] channels = channels(img);
  PGraphics[] dithered = new PGraphics[3];
  for (int i = 0; i < 3; i++) {
    dithered[i] = bw_dither(channels[i], matrix);
    dithered[i].loadPixels();
  }
  PImage out = createImage(img.width, img.height, RGB);
  out.loadPixels();
  for (int i = 0; i < out.pixels.length; i++) {
    out.pixels[i] = color(brightness(dithered[0].pixels[i]), 
      brightness(dithered[1].pixels[i]), 
      brightness(dithered[2].pixels[i]));
  }
  out.updatePixels();
  PGraphics pgOut = createGraphics(out.width, out.height);
  pgOut.beginDraw();
  pgOut.image(out,0,0);
  pgOut.endDraw();
  return pgOut;
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
          int x2 = x + c - matrix[r].length/2;
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
