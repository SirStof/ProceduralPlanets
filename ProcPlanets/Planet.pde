class Planet
{
  private float x,y,z;
  
  private float angle = 0;
  
  private float r;
  
  private int reso;
  
  // If true, it keeps all of the sea at the same level, the radius of the sphere.
  // If false, it decreases the elevation of the sea based on the noise.
  private boolean clamp = true;
  
  
  private NoiseGenerator noiseGenerator;
  private BiomeGenerator biomeGenerator;
  
  private PShape shape;

  private boolean elevation = true;
  
  private boolean heightBiome = true;
  
  // Making the base icosahedron with the so called 'golden rectangles' of each x,y,z axis.
  private final float PHI = (float)((sqrt(5) + 1.0) / 2.0);
  private final int[] baseT = new int[]
  {
      0,2,1, 0,3,2, 0,4,3, 0,5,4, 0,1,5,
      1,2,7, 2,3,8, 3,4,9, 4,5,10, 5,1,6,
      1,7,6, 2,8,7, 3,9,8, 4,10,9, 5,6,10,
      11,6,7, 11,7,8, 11,8,9, 11,9,10, 11,10,6
  };
  
  private PVector[][] verts;
  private color[][] colours; 
  private int[][] triangles;
  private float[][] elevMap;
  
  private PVector[] baseVerts;
  
  public Planet(float x, float y, float z, float ra, int reso)
  {
    this.x = x;
    this.y = y;
    this.z = z;
    this.r = ra;
    this.reso = reso;
    
    noiseGenerator = new NoiseGenerator();
    biomeGenerator = new BiomeGenerator(true);
    
    verts = new PVector[20][];
    colours = new color[20][];
    triangles = new int[20][];
    elevMap = new float[20][];
    
    biomeGenerator.addBiome(new Biome(color(194,187,130), 0.1));
    //biomeGenerator.addBiome(new Biome(color(114,107,64), 0.2));
    biomeGenerator.addBiome(new Biome(color(60,120,36), 0.7));
    biomeGenerator.addBiome(new Biome(color(30, 71, 9), 0.9));
    biomeGenerator.addBiome(new Biome(color(255, 255, 255), 1.2));
    
    // base triangles of the icosahedron
    baseVerts = new PVector[12];
    baseVerts[0] = new PVector(-1f, PHI, 0f);
    baseVerts[1] = new PVector(1f, PHI, 0f);
    baseVerts[2] = new PVector(0f, 1f, PHI);
    baseVerts[3] = new PVector(-PHI, 0f, 1f);
    baseVerts[4] = new PVector(-PHI, 0f, -1f);
    baseVerts[5] = new PVector(0f, 1f, -PHI);
    baseVerts[6] = new PVector(PHI, 0f, -1f);
    baseVerts[7] = new PVector(PHI, 0f, 1f);
    baseVerts[8] = new PVector(0f, -1f, PHI);
    baseVerts[9] = new PVector(-1f, -PHI, 0f);
    baseVerts[10] = new PVector(0f, -1f, -PHI);
    baseVerts[11] = new PVector(1f, -PHI, 0f);
    
    for(int i=0;i<baseVerts.length;i++)
      baseVerts[i].normalize();
    
    makeShape();
  }
  public void makeShape()
  {
    shape = createShape();
    System.gc();
    shape.beginShape(TRIANGLE);

    
    for(int i=0;i<20;i++)
    {
      PVector[] vertices = new PVector[3];
      for (int j = 0; j < 3; j++)
          vertices[j] = baseVerts[baseT[3 * i + j]];
          
      makePartShape(vertices, i);
      addElevation(i);
      generateBiomes(i);
      fillShape(i);
    }
    shape.endShape();
  }
  private void makePartShape(PVector[] baseTriangle, int arrOffset)
  {
    verts[arrOffset] = new PVector[(reso + 1) * (reso + 2) / 2];
    colours[arrOffset] = new color[(reso + 1) * (reso + 2) / 2];
    triangles[arrOffset] = new int[reso * reso * 3];
    elevMap[arrOffset] = new float[(reso + 1) * (reso + 2) / 2];
    PVector up = (PVector.sub(baseTriangle[1], baseTriangle[0])).div(reso);
    PVector right = (PVector.sub(baseTriangle[2], baseTriangle[1])).div(reso);
    int triIndex = 0;
    int i=0;
    
    for (int y = 0; y <= reso; y++)
    {
      PVector pointOnEdge = PVector.add(baseTriangle[0], PVector.mult(up, y));
      for (int x = 0; x <= y; x++)
      {
        PVector pointOnTriangle = PVector.add(pointOnEdge, PVector.mult(right, x));
        
        verts[arrOffset][i] = pointOnTriangle;
        verts[arrOffset][i].normalize();
        
        elevMap[arrOffset][i] = noiseGenerator.getNoise(verts[arrOffset][i].x, verts[arrOffset][i].y, verts[arrOffset][i].z) * r/50.0; // The factor is to scale the noise appropriate to the radius

        if (y != reso)
        {
          triangles[arrOffset][triIndex] = i;
          triangles[arrOffset][triIndex + 1] = i + y + 1;
          triangles[arrOffset][triIndex + 2] = i + y + 2;
          triIndex += 3;
        
          if(x != 0)
          {
            triangles[arrOffset][triIndex] = i;
            triangles[arrOffset][triIndex + 1] = i - 1;
            triangles[arrOffset][triIndex + 2] = i + y + 1;
            triIndex += 3;
          }
        }
        i++;
      }
    }
  }
  private void addElevation(int arrOffset)
  {
    for (int j = 0; j < (reso + 1) * (reso + 2) / 2; j++)
    {
      verts[arrOffset][j].normalize();
      float noise = elevMap[arrOffset][j];
      if(elevation)
      {
        if(clamp && noise < 0)
          verts[arrOffset][j].mult(r);
        else
          verts[arrOffset][j].mult(r + noise);
      }
      else
        verts[arrOffset][j].mult(r);
    }
  }
  private void generateBiomes(int arrOffset)
  {
    for (int j = 0; j < (reso + 1) * (reso + 2) / 2; j++)
    {
      if(elevMap[arrOffset][j] > 0)
        colours[arrOffset][j] = biomeGenerator.getColor(verts[arrOffset][j].x-x, verts[arrOffset][j].y-y, verts[arrOffset][j].z-z, r);
      else // range[0,-4]
        colours[arrOffset][j] = color( map(elevMap[arrOffset][j], -1.75, 0, 2, 35), map(elevMap[arrOffset][j], -1.75, 0, 49, 177), map(elevMap[arrOffset][j], -1.75, 0, 136, 254));
        
      if(heightBiome && elevMap[arrOffset][j] > 0)
      {
        colours[arrOffset][j] = lerpColor(colours[arrOffset][j], color(139,69,19), map(elevMap[arrOffset][j], 0, 2, 0,.8));
        if(elevMap[arrOffset][j] > 1.7)
          //colours[arrOffset][j] = lerpColor(colours[arrOffset][j], color(255,255,255), map(elevMap[arrOffset][j], 2, 2.5, .8,1));
          colours[arrOffset][j] = color(255,255,255);
      }
    }
  }
  private void fillShape(int arrOffset)
  {
    for(int j=0;j<triangles[arrOffset].length;j+=3)
    {
      // For low resolution the blending of vertex colours can be ugly around the coastlines.
      if(resolution <= 192)
      {
        if( (elevMap[arrOffset][triangles[arrOffset][j]] <= 0 || elevMap[arrOffset][triangles[arrOffset][j+1]] <= 0 || elevMap[arrOffset][triangles[arrOffset][j+2]] <= 0) && // if at least one vertex is 'water'
          !(elevMap[arrOffset][triangles[arrOffset][j]] <= 0 && elevMap[arrOffset][triangles[arrOffset][j+1]] <= 0 && elevMap[arrOffset][triangles[arrOffset][j+2]] <= 0))    // but not all of them are
        {
          if(blue(colours[arrOffset][triangles[arrOffset][j]]) < blue(colours[arrOffset][triangles[arrOffset][j+1]]))
            shape.fill(colours[arrOffset][triangles[arrOffset][j]]);
          else if(blue(colours[arrOffset][triangles[arrOffset][j+1]]) < blue(colours[arrOffset][triangles[arrOffset][j+2]]))
            shape.fill(colours[arrOffset][triangles[arrOffset][j+1]]);
          else
            shape.fill(colours[arrOffset][triangles[arrOffset][j+2]]);
        
          shape.vertex(verts[arrOffset][triangles[arrOffset][j]].x, verts[arrOffset][triangles[arrOffset][j]].y, verts[arrOffset][triangles[arrOffset][j]].z);
          shape.vertex(verts[arrOffset][triangles[arrOffset][j+1]].x, verts[arrOffset][triangles[arrOffset][j+1]].y, verts[arrOffset][triangles[arrOffset][j+1]].z);
          shape.vertex(verts[arrOffset][triangles[arrOffset][j+2]].x, verts[arrOffset][triangles[arrOffset][j+2]].y, verts[arrOffset][triangles[arrOffset][j+2]].z);
        }
        else
        {
          shape.fill(colours[arrOffset][triangles[arrOffset][j]]);
          shape.vertex(verts[arrOffset][triangles[arrOffset][j]].x, verts[arrOffset][triangles[arrOffset][j]].y, verts[arrOffset][triangles[arrOffset][j]].z);
          shape.fill(colours[arrOffset][triangles[arrOffset][j+1]]);
          shape.vertex(verts[arrOffset][triangles[arrOffset][j+1]].x, verts[arrOffset][triangles[arrOffset][j+1]].y, verts[arrOffset][triangles[arrOffset][j+1]].z);
          shape.fill(colours[arrOffset][triangles[arrOffset][j+2]]);
          shape.vertex(verts[arrOffset][triangles[arrOffset][j+2]].x, verts[arrOffset][triangles[arrOffset][j+2]].y, verts[arrOffset][triangles[arrOffset][j+2]].z);
        }
      }
      else
      {
        shape.fill(colours[arrOffset][triangles[arrOffset][j]]);
        shape.vertex(verts[arrOffset][triangles[arrOffset][j]].x, verts[arrOffset][triangles[arrOffset][j]].y, verts[arrOffset][triangles[arrOffset][j]].z);
        shape.fill(colours[arrOffset][triangles[arrOffset][j+1]]);
        shape.vertex(verts[arrOffset][triangles[arrOffset][j+1]].x, verts[arrOffset][triangles[arrOffset][j+1]].y, verts[arrOffset][triangles[arrOffset][j+1]].z);
        shape.fill(colours[arrOffset][triangles[arrOffset][j+2]]);
        shape.vertex(verts[arrOffset][triangles[arrOffset][j+2]].x, verts[arrOffset][triangles[arrOffset][j+2]].y, verts[arrOffset][triangles[arrOffset][j+2]].z);
      }
    }
  }
  public void changeBiomeBlend(float bf)
  {
    biomeGenerator.changeBlendRatio(bf);
    
    shape = createShape();
    System.gc();
    shape.beginShape(TRIANGLE);
    
    for(int i=0;i<20;i++)
    {
      generateBiomes(i);
      fillShape(i);
    }
    shape.endShape();
  }
  public void drawShape()
  {
    pushMatrix();
    translate(x,y,z);
    rotateY(angle);
    shape(shape);
    popMatrix();
  }
  public void changeResolution(int c)
  {
    reso += c;
    if(reso < 1)
      reso = 1;
    
    makeShape();
  }
  
  public void rotate(float a)
  {
    angle = (angle+a);
    if(angle >= TWO_PI)
      angle -= TWO_PI;
   
  }
  
  public void toggleElevation()
  {
    elevation = !elevation;
    
    shape = createShape();
    System.gc();
    shape.beginShape(TRIANGLE);

    for(int i=0;i<20;i++)
    {
      addElevation(i);
      generateBiomes(i);
      fillShape(i);
    }
    shape.endShape();
  }
}

class NoiseGenerator
{
  private float baseFrequency;
  private float baseIntensity;
  private float octaves;
  
  private float xOff, yOff, zOff;
  
  public NoiseGenerator()
  {
    xOff = random(-1000,1000);
    yOff = random(-1000,1000);
    zOff = random(-1000,1000);
    
    baseFrequency = 0.012;
    baseIntensity = 2.0;
    octaves = 7;
  }
  public float getNoise(float x, float y, float z)
  {
    float noise = 0;
    float frequency = baseFrequency;
    float intensity = baseIntensity;
    for(int i=0;i<octaves;i++)
    {
      // The constant factor of 100 is so that each sphere gets treated as a 100 radius sphere.
      // This way the x,y,z values aren't extremely close if the resolution is very high.
      //
      noise += intensity*( (2.0*noise((x + xOff)*100*frequency, (y + yOff)*100*frequency, (z + zOff)*100*frequency))-1.0 );
      frequency *= 2;
      intensity /= 2;
    }
    return noise;
  }
  public void changeOctaves(int i)
  {
    octaves += i;
    if(octaves < 1)
      octaves = 1;
  }
}

// basically a final struct
class Biome
{
  public final color colour; // general color of the biome
  public final float mid; // offset from the equator,

  public Biome(color c, float m)
  {
    colour = c;
    mid = m;
  }
}

class BiomeGenerator
{
  private ArrayList<Biome> biomes; // all the biomes, must be sorted from close to far from equator
  private boolean symmetrical; // mirror biomes on both sides of the equator. Default, as asymmetrical is not implemented.
  
  private float xOff, yOff, zOff;
  
  private float blendRatio;
  
  public BiomeGenerator(boolean sym)
  {
    symmetrical = sym;
    biomes = new ArrayList<Biome>();
    
    xOff = random(-1000,1000);
    yOff = random(-1000,1000);
    zOff = random(-1000,1000);
    
    blendRatio = 0.3;
  }
  public void addBiome(Biome b)
  {
    biomes.add(b);
  }
  public color getColor(float x, float y, float z, float r)
  {
    float noise = (noise((x+xOff)*0.03,(y+yOff)*0.03,(z+zOff)*0.03)-0.5);
    color newColour = -1;
    for (int k=0; k<biomes.size()-1; k++)
    {
      float adjusted_y = abs(y)+(r/2-r*(biomes.get(k).mid+noise));
      
      float inter = map(adjusted_y, (blendRatio)*r, r-((blendRatio)*r), 0, 1);
      color c = lerpColor(biomes.get(k).colour, biomes.get(k+1).colour, inter);
      if(newColour == -1)
        newColour = c;
      else
        newColour = lerpColor(newColour, c, inter);
    }/*
    float inter = map(abs(y)+(r/2-r*biomes.get(0).mid), (blendRatio)*r, r-((blendRatio)*r), 0, 1);
    color c = lerpColor(biomes.get(0).colour, biomes.get(1).colour, inter);*/

    return newColour;
  }
  public void changeBlendRatio(float b)
  {
    if(blendRatio + b > 0 && blendRatio + b < 0.5)
      blendRatio += b;
  }
}
