PImage img;
float pixelSize = 5;
boolean dither;
boolean dirty;
int[][] matrix = new int[][]{
  {0, 0, 0, 7, 5}, 
  {3, 5, 7, 5, 3}, 
  {1, 3, 5, 3, 1}
};


void setup() {
  size(640, 480);
  selectInput("Select an image to dither:", "fileSelected");
  colorMode(HSB, 1.0);
  dither = false;
  dirty = true;
  noSmooth();
}

void fileSelected(File selection) {
  try {
    img = loadImage(selection.getAbsolutePath());
    surface.setSize(img.width, img.height);
  } 
  catch (Exception e) {
  }
}

void draw() {
  if (dirty && img != null) {
    update();
    dirty = false;
  }
}

void update() {
  if (dither) {
    bw_dither(img, matrix);
  } else {
    image(img, 0, 0);
  }
}

void keyPressed() {
  if (key == ' ') dither = !dither;
  else if (keyCode == UP) pixelSize++;
  else if (keyCode == DOWN) pixelSize = max(1, pixelSize-1);
  else if (key == 's') save("dither.png");
  else if (key == 'l') selectInput("Select an image to dither:", "fileSelected");
  else return;
  dirty = true;
}

PGraphics bw_dither(PImage img, int[][] matrix) {
  PGraphics out = createGraphics(img.width, img.height);
  int total = 0;
  for (int[] row : matrix) {
    for (int i : row) total += i;
  }
  out.beginDraw();
  out.background(0);
  img = img.copy();
  img.resize(int(img.width/pixelSize), int(img.height/pixelSize));
  float size = 1. * width / img.width;
  float[][] imgGrid = new float[img.width][img.height];
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      imgGrid[x][y] = brightness(img.get(x, y));
    }
  }
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      float oldPixel = imgGrid[x][y];
      float newPixel = oldPixel > 0.5 ? 1 : 0;
      fill(newPixel);
      stroke(newPixel);
      rect(map(x, 0, img.width, 0, width), map(y, 0, img.height, 0, height), size, size);
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
  return out;
}
