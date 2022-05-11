{$M 16384,0,90000}
{COMPILER DIRECTIVE TO ALTER MEMORY ALOCATED TO THE PROGRAMS HEAP}
Program Magigraph;
Uses
  Dos,Crt,Graph,Majkvars,Mousedrv,Menudrv,Fileopts,Drawopts,Redrawop,Prefopts;

procedure Initscreen;
{INITIALIZES GRAPHICS SCREEN AND ASSIGNS COMMONLY USED FUNCTIONS TO VARS}
begin
  Nosound;
  CHECKBREAK:=FALSE;
  GRDRIVER:=DETECT;                     {USE AUTO DETECTION}
  Initgraph(GRDRIVER,GRMODE,'');        {INITIATE GRAPHICS DRIVER}
  GRERROR:=Graphresult;
  if GRERROR<>GROK then                 {DID Initgraph WORK?}
  begin
    Writeln('Graphics error: ', Grapherrormsg(GRERROR));      {DISPLAY ERROR MESSAGE}
    Halt;                                                     {AND LEAVE PROGRAM}
  end;
  Settextstyle(DEFAULTFONT,HORIZDIR,1);
  if GRDRIVER=HERCMONO then HERC:=TRUE else HERC:=FALSE;    {WHICH MACHINE?}
  MAXX :=Getmaxx;
  MAXY :=Getmaxy;
  MAXC :=Getmaxcolor;
  TEXTH :=Textheight('M');
  TEXTW :=Textwidth('M');
  WINL :=30;
  WINT :=50;
  WINR :=MAXX-30;
  WINB :=MAXY-77;
  xoff :=MAXX div 2;
  yoff :=MAXY div 2;
  EXOFF:=xoff;
  EYOFF:=yoff;
  if not Minit then                     {TEST FOR MOUSE'S PRESENTS}
  begin
    Closegraph;                         {DISPLAY ERROR MESSAGE IF NO MOUSE AND EXIT PROGRAM}
    Writeln('Mouse not present.  Program does not function without a mouse, YET!');
    Sound(400);Delay(200);Nosound;
    Halt;
  end;
  Cleardevice;
  Showbar;                              {DRAW THE MENUBAR}
  Savemenubar;                          {& STORE IT FOR PUTIMAGE}
  Rectangle(0,0,MAXX,MAXY);
  if HERC then Mratio(1,1);             {DUE TO SPECIAL PROBLEM WITH THE MOUSE ON THE HERCULES}
  Mdomain(0,0,MAXX,MAXY);               {SET MOUSE MOVEMENT LIMITS TO WHOLE SCREEN}
  Mnewpointer(WANDXHOT,WANDYHOT,wand);  {DEFINES A NEW CURSOR, EGA ONLY}
  Mshow(TRUE);                          {SHOW THE MOUSE}
end;

begin
  Initscreen;
  Help;
  repeat
    mode:=1;
    if Mstatus=RIGHTBUT then            {IF THE RIGHT MOUSE BUTTON IS PRESSED}
      case Getmenu of                   {GO INTO MENU ROUTINES AND TEST RESULTS}
        0 : Filemenu;
        1 : Drawmenu;                   {THE FOUR MENUS, WHICH ARE REPRESENTED IN}
        2 : Redrawmenu;                 {FOUR SEPERATE UNITS}
        3 : Prefmenu;
      end;
    if Keypressed then Servkeys;        {ACCESS TO HELP}
  until FALSE;                          {INFINITE LOOP}
end.

