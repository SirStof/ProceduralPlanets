FirstPersonPerspective fpp;

int resolution = 256;

boolean rotate = false;

int shade = 1;

Planet planet;

PShader shaders[];

void setup()
{
  fullScreen(P3D, 1);
  fpp = new FirstPersonPerspective(this);
  fpp.toggle();
  
  noStroke();
  planet = new Planet(0,0,-150,50,resolution); // Original test values (0,0,-150,50, resolution)
  
  // My failed beginnings of writing a shader for Processing.
  // Shader on startup works as if there is a sun. 
  // Other shader (toggle with y) will act as if the camera has a flashlight.
  // It is not supposed to, but can be handy to look at some details.
  shaders = new PShader[2];
  
  shaders[0] = loadShader("pixlightfrag.glsl", "pixlightvert.glsl");
  
  shaders[1] = loadShader("testfrag.glsl", "testvert.glsl");

  
  fixPerspective();
}
void draw()
{
  if(rotate)
    planet.rotate(0.005);

  if(shade == shaders.length)
    resetShader();
  else
    shader(shaders[shade]);
    
  directionalLight(200, 200, 200, 0, 0, -1);
  ambientLight(10,10,10);
  
  background(0);

  planet.drawShape();
  fpp.update();
}

// Increases the height of the frustum, allowing the camera to get closer before clipping in the near plane.
public void fixPerspective()
{
  float cameraFOV = 60 * DEG_TO_RAD; // at least for now
  float cameraY = height / 2.0f;
  float cameraZ = cameraY / ((float) Math.tan(cameraFOV / 2.0f));
  float cameraNear = cameraZ / 100.0f;
  float cameraFar = cameraZ * 10.0f;
  float cameraAspect = (float) width / (float) height;
  
  perspective(cameraFOV, cameraAspect, cameraNear, cameraFar);
}

void keyPressed()
{
  fpp.keyPressed();

  if(key == 'y')
    shade = (shade+1) % (shaders.length+1);
  
  if(resolution <= 128) // higher can be slow. Remove this and try.
  {
    if(key == 'o')
      planet.changeBiomeBlend(0.01);
    if(key == 'p')
      planet.changeBiomeBlend(-0.01);
  }
    
  if(key == 'i')
    rotate = !rotate;
    
  if(key == 'l')
    planet.toggleElevation();
  
  
  // Might prove slow or even unsuccesful (i.e. the program might crash) if the resolution is too high.
  if(key == 'g')
    planet = new Planet(0,0,-150,50,resolution);
  
}

void keyReleased()
{
  fpp.keyReleased();
}
