Unit Redrawop;

Interface

Uses
  Dos,Crt,Graph,Mousedrv,Majkvars;

procedure Redrawmenu;
procedure Refresh(barback : boolean);
procedure Savemenubar;
procedure Replacemenubar;
procedure Printonbar(strn : string; penst : shortint);
procedure Servkeys;
procedure Help;

Implementation

var
  ply       : array[0..7] of integer;

procedure Help;
var
  srbuf : pointer;
  srsiz : word;
begin
  ply[0]:=(MAXX div 2)-(25*TEXTW);
  ply[2]:=ply[0];
  ply[4]:=(MAXX div 2)+(25*TEXTW);
  ply[6]:=ply[4];
  ply[1]:=(MAXY div 2)-TEXTH*3;
  ply[3]:=(MAXY div 2)+TEXTH*2;
  ply[5]:=ply[3];
  ply[7]:=ply[1];
  Setfillstyle(SOLIDFILL,0);
  Mshow(FALSE);
  srsiz:=Imagesize(ply[0],ply[1],ply[4],ply[3]);
  Getmem(srbuf,srsiz);
  Getimage(ply[0],ply[1],ply[4],ply[3],srbuf^);
  Fillpoly(4,ply);
  Outtextxy(ply[0]+5,ply[1]+5,HELPMSGS[mode,0]);
  Outtextxy(ply[0]+5,ply[1]+5+TEXTH+3,HELPMSGS[mode,1]);
  Outtextxy(ply[0]+5,ply[1]+5+((TEXTH+3)*2),HELPMSGS[mode,2]);
  while (not Keypressed) do;
  Putimage(ply[0],ply[1],srbuf^,NORMALPUT);
  Freemem(srbuf,srsiz);
  Mshow(TRUE);
end;

procedure Servkeys;
{
READS KEYBOARD, IF BACKSPACE HAS BEEN PRESSED THEN THE LAST OBJECT DRAWN IS
REMOVED BY DECREASING curobj
 LOCALS : ch = CHAR READ FROM KEYBOARD
}
var
  ch : char;
begin
  ch :=Readkey;
  case ch of
    #0     : begin
               ch :=Readkey;
               if ch = #59 then Help;
             end;
    BKSPC  : if (mode>1) then
             begin
               drawingchanged:=TRUE;
               Sound(600);Delay(50);Nosound;
               if curobj>0 then
               begin
                 Dec(curobj);
                 Refresh(NOBAR);
               end;
             end;
  end;
end;

procedure Savemenubar;
{
STORES MENUBAR IN A GLOBAL BUFFER
}
begin
  Mshow(false);
  barsiz :=Imagesize(0,0,BARRIGHT,BARBOT);
  Getmem(barbuf,barsiz);
  Getimage(0,0,BARRIGHT,BARBOT,barbuf^);
  Mshow(true);
end;

procedure Replacemenubar;
{
PUTS THE MENUBAR BACK ONTO THE SCREEN
}
begin
  Mshow(false);
  Putimage(0,0,barbuf^,NORMALPUT);
  Mshow(true);
end;

procedure Printonbar(strn : string; penst : shortint);
{
CLEARS THE MENUBAR AND PRINTS A STRING OVER IT, ALSO PEN STATE AND CURRENT OBJECT
IF REQUIRED
 PARAMS : strn = STRING TO BE PRINTED
          penst = STATUS OF PEN
 LOCALS : curstr = OBJECT NUMBER STRING FOR PRINTING
}
var
  curstr : string[30];
begin
  Mshow(FALSE);
  Setfillstyle(1,0);
  Fillpoly(4,BARBOX);
  Outtextxy(TEXTW*2,2,strn);
  case penst of
    PENON : Outtextxy(TEXTW*40,2,PENDMSG);
    PENOFF : Outtextxy(TEXTW*40,2,PENUMSG);
    NOPEN : ;
  end;
  curstr:='Object No='+I2S(curobj);
  if penst<>NOPEN then Outtextxy(MAXX-Textwidth(curstr),2,curstr);     {DISPLAYS OBJECT NUMBER IF REQUIRED}
  Mshow(TRUE);
end;

procedure Refresh(barback : boolean);
{
REDRAWS ALL OBJECTS UP TO CURRENT OBJECT
 LOCALS : a = COUNTER
}
var
  a : word;
begin
  Mshow(FALSE);
  Mremove;
  if not gridcall then
  begin
    options[3,0]:='Grid ON';
    grdst :=FALSE;
  end;
  Cleardevice;
  if curobj>0 then
    for a:=0 to curobj-1 do
    begin
      case picobject[a].objectype of         {SCAN ALL OBJECTS AND REDRAW THE ONES FOUND}
        POINT : with picobject[a] do
                Putpixel(Round(px*scale)+xoff,Round(py*scale)+yoff,MAXC);
        LIN : with picobject[a] do
                Line(Round(lx1*scale)+xoff,Round(ly1*scale)+yoff,
                     Round(lx2*scale)+xoff,Round(ly2*scale)+yoff);
        ELLIPS : with picobject[a] do
                Ellipse(Round(ex1*scale)+xoff,Round(ey1*scale)+yoff,
                        0,360,Round(ex2*scale),Round(ey2*scale));
        RECT : with picobject[a] do
                Rectangle(Round(rx1*scale)+xoff,Round(ry1*scale)+yoff,
                          Round(rx2*scale)+xoff,Round(ry2*scale)+yoff);
      end;
  end;
  if barback then Replacemenubar;
  Rectangle(0,0,MAXX,MAXY);
  Mshow(TRUE);
end;

procedure Clear;
{
CLEARS ALL OBJECTS BY SETTING CUROBJ TO ZERO
}
begin
  Printonbar('Are you sure about clearing the memory?              LEFT = YES  RIGHT = NO',NOPEN);
  repeat until Mstatus<>0;
  if regs.bx<>LEFTBUT then
  begin
    Replacemenubar;
    exit;
  end;
  picobject[0].objectype :=NULL;
  curobj :=0;
  scale:=2;
  drawingchanged:=false;
  xoff:=EXOFF;
  yoff:=EYOFF;
  Refresh(BAR);
end;

procedure Zoom;
{
ALLOWS USER TO ZOOM IN ON OBJECTS
 LOCALS : jump = STEP SIZE OF SCALE
          count = COUNTS NUMBER OF JUMPS
          pol = AREA TO CLEAR BY USING FILLPOLY TO PRINT STRING
          prntstr = STRING TO PASS TO PRINTONBAR
          ch = FOR READKEY
}
var
  jump      : real;
  count     : byte;
  pol       : array[0..7] of integer;
  prntstr   : string;
  ch        : char;
begin
  mode:=7;
  ch:=#255;
  prntstr:='Zoom active.  Escape Exit.  Both buttons Refresh.  Left Zoom Out.  Right Zoom In.';
  Mshow(FALSE);
  jump:=0.01;
  count:=1;
  Mremove;
  Printonbar(prntstr,NOPEN);
  pol[0]:=50;                                       pol[1]:=50;
  pol[2]:=pol[0]+Textwidth('Scale=')+TEXTW*7;       pol[3]:=pol[1];
  pol[4]:=pol[2];                                   pol[5]:=pol[1]+TEXTH+4;
  pol[6]:=pol[0];                                   pol[7]:=pol[5];
  Mremove;
  Fillpoly(4,pol);
  Outtextxy(pol[0]+4,pol[1]+3,'Scale='+R2S(scale));
  Mremove;
  repeat
    while (Mstatus=LEFTBUT) and (scale-jump>1) do
    begin
      scale:=scale-jump;               {REDUCES SCALE}
      Inc(count);
      Mremove;
      Fillpoly(4,pol);
      Outtextxy(pol[0]+4,pol[1]+3,'Scale='+R2S(scale));
      Mremove;
      if count>10 then                 {EVERY 10TH INCREASE THE STEP SIZE IS DOUBLED}
      begin
        count:=1;
        jump:=jump*2;
      end;
    end;
    while (Mstatus=RIGHTBUT) and (scale+jump<100) do
    begin
      scale:=scale+jump;               {INCREASES SCALE}
      Inc(count);
      Mremove;
      Fillpoly(4,pol);
      Outtextxy(pol[0]+4,pol[1]+3,'Scale='+R2S(scale));
      Mremove;
      if count>10 then
      begin
        count:=1;
        jump:=jump*2;
      end;
    end;
    count:=1;
    jump:=0.01;
    if Mstatus=BOTHBUT then
    begin
      Refresh(NOBAR);
      Printonbar(prntstr,NOPEN);
      Mremove;
      Fillpoly(4,pol);
      Outtextxy(pol[0]+4,pol[1]+3,'Scale='+R2S(scale));
      Mremove;
    end;
    if Keypressed then ch:=Readkey;
    if ch=#59 then Help;
  until ch=ESC;
  Refresh(BAR);
  Mshow(TRUE);
  Mremove;
end;

procedure Moveobj;
{
ALLOWS USER TO MOVE ALL OF THE OBJECTS AROUND THE SCREEN
 LOCALS : step = DISTANCE TO OFFSET OBJECT BY
}
var
  step : integer;
  ch   : char;
begin
  mode:=8;
  Printonbar('Move Active.  Leftbutton to RECENTER,  Rightbutton to EXIT.',NOPEN);
  Mshow(FALSE);
  Line((MAXX div 2)-20,MAXY div 2,(MAXX div 2)+20,MAXY div 2);
  Line(MAXX div 2,(MAXY div 2)-15,MAXX div 2,(MAXY div 2)+15);
  Mshow(TRUE);
  repeat
    if Mstatus=LEFTBUT then
    begin
      if regs.cx>exoff then
      begin
        step:=regs.cx-exoff;
        Dec(xoff,step);
      end
        else
      begin
        step:=exoff-regs.cx;
        Inc(xoff,step);
      end;
      if regs.dx>eyoff then
      begin
        step:=regs.dx-eyoff;
        Dec(yoff,step);
      end
      else
      begin
        step:=eyoff-regs.dx;
        Inc(yoff,step);
      end;
    Refresh(NOBAR);
    Printonbar('Move Active.  Leftbutton to RECENTER,  Rightbutton to EXIT.',NOPEN);
    Mshow(FALSE);
    Line((MAXX div 2)-20,MAXY div 2,(MAXX div 2)+20,MAXY div 2);
    Line(MAXX div 2,(MAXY div 2)-15,MAXX div 2,(MAXY div 2)+15);
    Mshow(TRUE);
    end;
    if Keypressed then
    begin
      ch:=Readkey;
      if ch=#59 then Help;
    end;
  until Mstatus=RIGHTBUT;
  Refresh(BAR);
end;

procedure Normalize;
{
INCASE USER LOSES PICTURE THEN THIS PROCEDURE WITH THE SET SCALE AND OFFSETS TO DEFAULTS
}
begin
  scale:=2;
  xoff:=EXOFF;
  yoff:=EYOFF;
  Refresh(BAR);
end;

procedure Redrawmenu;
{
CONTROLLING PROCEDURE FOR REDRAW MENU
}
begin
  case ono of
    0 : Clear;
    1 : Refresh(BAR);
    2 : Zoom;
    3 : Moveobj;
    4 : Normalize;
  end;
end;


end.

