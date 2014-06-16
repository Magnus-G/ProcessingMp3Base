import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;
Rewind rewind;
Forward ffwd;
Play play;

FFT fft;

int width = 800;
int height = 450;
int centerWidth = width / 2;
int centerHeight = height / 2;
int padding = 120;

//////////////////////////////////////////////////////////////////////////////////////////////////////////// 

void setup()
{
  size(width, height);
 
  // always start Minim first!
  minim = new Minim(this);
 
  // specify 512 for the length of the sample buffers
  // the default buffer size is 1024
  song = minim.loadFile("klockorna.mp3", 512);
  song.play();

  play = new Play(width/2 - 50, height - 20, 20, 10);
  rewind = new Rewind(width/2, height - 20, 20, 10);
  ffwd = new Forward(width/2 + 50, height - 20, 20, 10);
 
  // an FFT needs to know how 
  // long the audio buffers it will be analyzing are
  // and also needs to know 
  // the sample rate of the audio it is analyzing
  fft = new FFT(song.bufferSize(), song.sampleRate());
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
void draw()
{
  // background(0);
  // first perform a forward fft on one of song's buffers
  // I'm using the mix buffer
  //  but you can use any one you like
  fft.forward(song.mix);
 
    float hej = fft.getBand(100)*4;
    background(hej);

  stroke(255, 0, 0, 128);
  // draw the spectrum as a series of vertical lines
  // I multiple the value of getBand by 4 
  // so that we can see the lines better
  for(int i = 0; i < width *2; i++) {
    line(i, height - 3, i, height - 3 - fft.getBand(i)*4);
  }
 
  stroke(255);
  // I draw the waveform by connecting 
  // neighbor values with a line. I multiply 
  // each of the values by 50 
  // because the values in the buffers are normalized
  // this means that they have values between -1 and 1. 
  // If we don't scale them up our waveform 
  // will look more or less like a straight line.
  for(int i = 0; i < song.left.size() - 1; i++)
  {
    line(i, 50 + song.left.get(i)*50, i+1, 50 + song.left.get(i+1)*50);
    line(i, 150 + song.right.get(i)*50, i+1, 150 + song.right.get(i+1)*50);
  }



  // draw the position in the song
  // the position is in milliseconds,
  // to get a meaningful graphic, we need to map the value to the range [0, width]
  float x = map(song.position(), 0, song.length(), 0, width);
  stroke(255);
  line(x, height - 4, x, height + 4);

  play.update();
  play.draw();
  rewind.update();
  rewind.draw();
  ffwd.update(); 
  ffwd.draw();
}

void mousePressed() {
  play.mousePressed();
  rewind.mousePressed();
  ffwd.mousePressed();
}

void mouseReleased() {
  play.mouseReleased();
  rewind.mouseReleased();
  ffwd.mouseReleased();
}

void stop() {
  // always close Minim audio classes when you are done with them
  song.close();
  minim.stop();
  
  super.stop();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

abstract class Button {
  int x, y, hw, hh;
  
  Button(int x, int y, int hw, int hh) {
    this.x = x;
    this.y = y;
    this.hw = hw;
    this.hh = hh;
  }
  
  boolean pressed() {
    return mouseX > x - hw && mouseX < x + hw && mouseY > y - hh && mouseY < y + hh;
  }
  
  abstract void mousePressed();
  abstract void mouseReleased();
  abstract void update();
  abstract void draw();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Play extends Button {
  boolean play;
  boolean invert;
  
  Play(int x, int y, int hw, int hh) { 
    super(x, y, hw, hh); 
    play = true;
  }
  
  // code to handle playing and pausing the file
  void mousePressed() {
    if ( pressed() ) {
      invert = true;
      if ( song.isPlaying()) {
        song.pause();
        play = true;
      }
      else {
        song.loop();
        play = false;
      }
    }
  }
  
  void mouseReleased() {
    invert = false;
  }
  
  // play is a boolean value used to determine what to draw on the button
  void update()
  {
    if ( song.isPlaying() ) play = false;
    else play = true;
  }
  
  void draw()
  {
    if ( invert ) {
      fill(255);
      stroke(0);
    }

    else {
      noFill();
      stroke(255);
    }
    rect(x - hw, y - hh, hw*2, hh*2);
    if ( invert ) {
      fill(0);
      stroke(255);
    }
    else {
      fill(255);
      noStroke();
    }
    if ( play ) {
      triangle(x - hw/3, y - hh/2, x - hw/3, y + hh/2, x + hw/2, y);
    }
    else {
      rect(x - hw/3, y - hh/2, hw/4, hh);
      rect(x + hw/8, y - hh/2, hw/4, hh);
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Rewind extends Button {
  boolean invert;
  boolean pressed;
  
  Rewind(int x, int y, int hw, int hh)
  {
    super(x, y, hw, hh);
    invert = false;
  }
  
  // code used to scrub backward in the file
  void update()
  {
    // if the rewind button is currently being pressed
    if (pressed)
    {
      // get the current song position
      int pos = song.position();
      // if it greater than 200 milliseconds
      if ( pos > 200 )
      {
        // rewind the song by 200 milliseconds
        song.skip(-200);
      }
      else
      {
        // if the song hasn't played more than 100 milliseconds
        // just rewind to the beginning
        song.rewind();
      }
    }
  }
  
  void mousePressed()
  {
    pressed = pressed();
    if ( pressed ) 
    {
      invert = true;
      // if the song isn't currently playing, rewind it to the beginning
      if ( !song.isPlaying() ) song.rewind();      
    }
  }
  
  void mouseReleased()
  {
    pressed = false;
    invert = false;
  }

  void draw()
  {
    if ( invert )
    {
      fill(255);
      stroke(0);
    }
    else
    {
      noFill();
      stroke(255);
    }
    rect(x - hw, y - hh, hw*2, hh*2);
    if ( invert )
    {
      fill(0);
      stroke(255);
    }
    else
    {
      fill(255);
      noStroke();
    }
    triangle(x - hw/2, y, x, y - hh/2, x, y + hh/2);
    triangle(x, y, x + hw/2, y - hh/2, x + hw/2, y + hh/2);    
  }  
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Forward extends Button {
  boolean invert;
  boolean pressed;
  
  Forward(int x, int y, int hw, int hh)
  {
    super(x, y, hw, hh);
    invert = false;
  }
  
  void update()
  {
    // if the forward button is currently being pressed
    if (pressed)
    {
      // get the current position of the song
      int pos = song.position();
      // if the song's position is more than 40 milliseconds from the end of the song
      if ( pos < song.length() - 40 )
      {
        // forward the song by 40 milliseconds
        song.skip(190);
      }
      else
      {
        // otherwise, cue the song at the end of the song
        song.cue( song.length() );
      }
      // start the song playing
      song.play();
    }
  }
  
  void mousePressed()
  {
    pressed = pressed();
    if ( pressed ) 
    {
      invert = true;      
    }
  }
  
  void mouseReleased()
  {
    pressed = false;
    invert = false;
  }

  void draw()
  {
    if ( invert )
    {
      fill(255);
      stroke(0);
    }
    else
    {
      noFill();
      stroke(255);
    }
    rect(x - hw, y - hh, hw*2, hh*2);
    if ( invert )
    {
      fill(0);
      stroke(255);
    }
    else
    {
      fill(255);
      noStroke();
    }
    triangle(x, y, x - hw/2, y - hh/2, x - hw/2, y + hh/2);
    triangle(x, y - hh/2, x, y + hh/2, x + hw/2, y);    
  }  
}


