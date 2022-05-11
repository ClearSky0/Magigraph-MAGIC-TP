Unit Drawopts;

Interface

Uses
  Dos,Crt,Graph,Mousedrv,Majkvars,Redrawop;

procedure Drawmenu;

Implementation

var
  prntstr : string[30];         {STRING USED TO PASS TO PRINTONBAR}

procedure Lastobj;
{
CHECKS HOW CLOSE CUROBJ IS TO MAXIMUMOBJECTS
DISPLAYS AN ERROR WHEN THE MAXIMUM OBJECT IS READECHD AND MAKES A CLICKING SOUND
WHEN YOU ARE 20 OBJECTS FROM THE MAXIMUM
}
begin
  drawingchanged:=TRUE;
  if curobj > MAXIMUMOBJECTS-1 then
  begin
    Sound(900);Delay(200);Nosound;
    if Editgstring(EXOFF-(Textwidth(LIMITMSG) div 2),EYOFF,MAXC,0,LIMITMSG,ul,FALSE) then;
    Setcolor(MAXC);
    Setfillstyle(SOLIDFILL,0);
    Refresh(BAR);
    Dec(curobj);
  end;
  if curobj > MAXIMUMOBJECTS-20 then
  begin
    Sound(400);Delay(1);Sound(1000);Delay(1);Nosound;
  end;
end;

procedure Dots;
{
DRAWS AND STORES SINGLE PIXELS
}
begin
  mode:=2;
  Printonbar('Point active',NOPEN);
  Mnewpointer(CROSSXHOT,CROSSYHOT,cross);      {ALL DRAWING MODES USE THE CROSS CURSOR AND ALL OTHERS USE THE WAND}
  repeat
    if Mbutstat =LEFTBUT then
    begin
      if Mstatus=LEFTBUT then;
      Mshow(false);
      Putpixel(regs.cx,regs.dx,Getmaxcolor);
      if curobj =0 then curobj :=1;
      Lastobj;
      with picobject[curobj] do
      begin                              {STORES OBJECT}
        objectype :=POINT;
        px :=((regs.cx-xoff)) / scale;
        py :=((regs.dx-yoff)) / scale;
      end;
      Inc(curobj);                       {MOVES ONTO NEXT OBJECT}
      Mshow(true);
      repeat until Mbutrel <>LEFTBUT;    {DONT ALLOW MORE THAN ONE POINT TO BE DRAWN WITH ONE BUTTON PRESS}
    end;
    if Keypressed then
    begin
      Servkeys;         {ALLOWS DELETION OF LAST OBJECT DRAWN}
      Printonbar('Point active',NOPEN);
    end;
  until Mstatus =RIGHTBUT;
  Mnewpointer(WANDXHOT,WANDYHOT,wand);
  Replacemenubar;
end;

procedure Lines;
{
DRAWS AND STORES LINES
 LOCALS : x,y,oldx,oldy,newx,newy = HOLD COORDINATES
          linebuf,linesiz = FOR PUTIMAGE ON EGA ONLY
}
var
  x,y,oldx,oldy,newx,newy : integer;

procedure Interactline;
{
DRAWS NEW LINE AND REMOVES OLD ONE
}
begin
  Setwritemode(XORPUT);
  Line(x,y,oldx,oldy);
  Line(x,y,newx,newy);
  Setwritemode(NORMALPUT);
  oldx :=newx;
  oldy :=newy;
end;

begin     {LINES}
  mode:=3;
  prntstr :='Line active';
  Printonbar(prntstr,PENOFF);
  Mnewpointer(CROSSXHOT,CROSSYHOT,cross);
  repeat
  if Mstatus =LEFTBUT then
    begin
      x :=regs.cx;
      y :=regs.dx;
      oldx :=x;
      oldy :=y;
      newx :=x;
      newy :=y;        {INITIALIZE COORDS}
      Mshow(false);
      Printonbar(prntstr,PENON);
      while Mstatus =LEFTBUT do
      begin
        newx :=regs.cx;
        newy :=regs.dx;
        if ((newx <>oldx) or (newy <>oldy)) then Interactline;
      end;
      if HERC then
      begin
        Putimage(x-4,y-4,curbuf^,XORPUT);    {REMOVE BEGINNING OF LINE MARK ON HERC}
        Mremove;
      end;
      Line(x,y,newx,newy);                   {DRAW FINAL LINE WITHOUT XOR}
      Printonbar(prntstr,PENOFF);
      Mshow(true);
      if curobj =0 then curobj :=1;
      Lastobj;
      with picobject[curobj] do              {STORE OBJECT}
      begin
        objectype :=LIN;
        lx1 :=(x-xoff) / scale;
        ly1 :=(y-yoff) / scale;
        lx2 :=(newx-xoff) / scale;
        ly2 :=(newy-yoff) / scale;
      end;
      inc(curobj);
    end;
    if Keypressed then
    begin
      Servkeys;
      Printonbar(prntstr,PENOFF);
    end;
  until Mstatus =RIGHTBUT;
  Mnewpointer(WANDXHOT,WANDYHOT,wand);
  Replacemenubar;
end;

procedure Ellipses(way : byte);
{
DRAWS AND STORES ELLIPSES
 PARAMS : way = TWO TYPES OF ELLIPSE CAN BE DRAWN WITH THE ONE PROCEDURE
                ONE FROM CORNER TO CORNER AND THE OTHER FROM THE CENTER TO THE CORNER
}
var
  ox,oy,x,y,oradx,orady,newx,newy,oldx,oldy,nradx,nrady : integer;

procedure Movellipse(move : boolean);
{
DRAWS A DOTTED CROSS TO REPRESENT THE MAJOR AND MINOR AXES OF RADIUS ELLIPSE
 PARAMS : move = EITHER DRAWS A NEW ONE BY ITSELF OR A NEW ONE AFTER REMOVING THE OLD ONE
}
begin
  Setwritemode(XORPUT);
  if move then
  begin
    Line(x,(y-orady)+1,x,(y+orady)-1);         {REMOVE OLD V LINE}
    Line(x-4,y-orady,x+4,y-orady);             {REMOVE OLD TOP MARK}
    Line(x-4,y+orady,x+4,y+orady);             {REMOVE OLD BOTTOM MARK}
    Line((x-oradx)+1,y,(x+oradx)-1,y);         {REMOVE OLD H LINE}
    Line(x-oradx,y-4,x-oradx,y+4);             {REMOCE OLD LEFT END MARK}
    Line(x+oradx,y-4,x+oradx,y+4);             {REMOVE OLD RIGHT END MARK}
  end;
  Line(x,(y-nrady)+1,x,(y+nrady)-1);         {PLACE NEW V LINE}
  Line(x-4,y-nrady,x+4,y-nrady);             {NEW TOP MARK}
  Line(x-4,y+nrady,x+4,y+nrady);             {NEW BOTTOM MARK}
  Line((x-nradx)+1,y,(x+nradx)-1,y);         {PLACE NEW H LINE}
  Line(x-nradx,y-4,x-nradx,y+4);             {PLACE NEW LEFT END MARK}
  Line(x+nradx,y-4,x+nradx,y+4);             {PLACE NEW RIGHT END MARK}
  Setwritemode(NORMALPUT);
  orady:=nrady;
end;

procedure Calcos;
{
CALCULATES AXES OF ELLIPSE
}
begin
  if way =RAD then
  begin
    if x>newx then nradx :=x-newx
    else nradx :=newx-x;
    if y>newy then nrady :=y-newy
    else nrady :=newy-y;
  end
    else
  begin
    if x>newx then
    begin
      nradx :=(ox-newx) div 2;
      x :=ox-nradx;
    end
      else
    begin
      nradx :=(newx-ox) div 2;
      x :=ox+nradx;
    end;
    if y>newy then
    begin
      nrady :=(oy-newy) div 2;
      y :=oy-nrady;
    end
      else
    begin
      nrady :=(newy-oy) div 2;
      y :=oy+nrady;
    end;
  end;
end;

procedure Doellipse;
{
CONTROL PROC FOR DRAWING AND STORING TWO TYPES OF INTERACTIVE ELLIPSE ON EGA ONLY
}
begin
  Printonbar(prntstr,PENOFF);
  Mnewpointer(CROSSXHOT,CROSSYHOT,cross);
  repeat
    if Mstatus=LEFTBUT then
    begin
      x :=regs.cx;
      y :=regs.dx;
      ox :=x;
      oy :=y;
      oradx :=0;
      orady :=0;
      nradx :=0;
      nrady :=0;
      newx :=x;
      newy :=y;
      oldx :=x;
      oldy :=y;                        {INIT VARS}
      Printonbar(prntstr,PENON);
      Mshow(FALSE);
      if way=RAD then Movellipse(FALSE);
      while Mstatus =LEFTBUT do
      begin
        Setwritemode(XORPUT);
        newx :=regs.cx;
        newy :=regs.dx;
        Calcos;
        if way=RAD then
        begin
          if (orady<>nrady) or (oradx<>nradx) then Movellipse(TRUE);
          oradx :=nradx;
          orady :=nrady;
        end
          else if (newx<>oldx) or (newy<>oldy) then
        begin
          Rectangle(ox,oy,oldx,oldy);
          Rectangle(ox,oy,newx,newy);
          oldx :=newx;
          oldy:=newy;
        end;
      end;                              {UPDATE ELLIPSE REPRESENTATION & COORDS WHILE LEFTBUTTON IS DOWN}
      if way =RAD then
      begin
        Movellipse(FALSE);
      end                                  {REMOVES OLD CROSS}
        else Rectangle(ox,oy,newx,newy);    {OR OLD RECTANGLE}
      Ellipse(x,y,0,360,nradx,nrady);      {DRAW ELLIPSE IN FINAL POSITION WITHOUT XOR}
      if HERC then
      begin
        Putimage(ox-4,oy-4,curbuf^,XORPUT);
        Mremove;
      end;
      Setwritemode(NORMALPUT);
      Printonbar(prntstr,PENOFF);
      if curobj =0 then curobj :=1;
      Lastobj;
      with picobject[curobj] do
      begin
        objectype :=ELLIPS;
        ex1 :=(x-xoff) / scale;
        ey1 :=(y-yoff) / scale;
        ex2 :=nradx / scale;
        ey2 :=nrady / scale;
      end;
      inc(curobj);
      Mshow(TRUE);
    end;
    if Keypressed then
    begin
      Servkeys;
      Printonbar(prntstr,PENOFF);
    end;
  until Mstatus =RIGHTBUT;
  Mnewpointer(WANDXHOT,WANDYHOT,wand);
  Replacemenubar;
end;

begin {Ellipses}
  if way =RAD then
  begin
    prntstr:='Radius Ellipse active';
    mode:=6;
  end
  else
  begin
    prntstr :='Corner to Corner Ellipse active';           {SETS STRING FOR PRINTONBAR}
    mode:=5;
  end;
  Doellipse;
end;

procedure Rectang;
{
DRAWS AND STORES RECTANGLES
}
var
  x,y,oldx,oldy,newx,newy : integer;

procedure Dorectangle;
{
DRAWS AND STORES RECTANGLE ON EGA IN INTERACTIVE MODE
}
begin
  Printonbar(prntstr,PENOFF);
  Mnewpointer(CROSSXHOT,CROSSYHOT,cross);
  repeat
    if Mstatus=LEFTBUT then
      begin
        x :=regs.cx;
        y :=regs.dx;
        oldx :=x;
        oldy :=y;
        newx :=oldx;
        newy :=oldy;                 {INIT VARS}
        Printonbar(prntstr,PENON);
        Mshow(FALSE);
        while Mstatus =LEFTBUT do
        begin
          Setwritemode(XORPUT);
          newx :=regs.cx;
          newy :=regs.dx;
          if (oldx<>newx) or (oldy<>newy) then
          begin
            Rectangle(x,y,oldx,oldy);
            Rectangle(x,y,newx,newy);
            oldx :=newx;
            oldy:=newy;
          end;
        end;
        Setwritemode(NORMALPUT);
        if HERC then Putimage(x-4,y-4,curbuf^,XORPUT);
        Mremove;
        Rectangle(x,y,newx,newy);    {DRAWS RECTANGLE IN FINAL POSITION WITHOUT XOR}
        Printonbar(prntstr,PENOFF);
        if curobj =0 then curobj :=1;
        Lastobj;
        with picobject[curobj] do
        begin
          objectype :=RECT;
          rx1 :=(x-xoff) / scale;
          ry1 :=(y-yoff) / scale;
          rx2 :=(newx-xoff) / scale;
          ry2 :=(newy-yoff) / scale;
        end;                         {STORES OBJECT}
        Inc(curobj);
        Mshow(TRUE);
      end;
    if Keypressed then
    begin
      Servkeys;
      Printonbar(prntstr,PENOFF);
    end;
  until Mstatus =RIGHTBUT;
  Mnewpointer(WANDXHOT,WANDYHOT,wand);
  Replacemenubar;
end;

begin   {RECTANGLE}
  mode:=4;
  prntstr :='Rectangle Active';
  Dorectangle;
end;


procedure Drawmenu;
{
CONTROL PROCEDURE FOR THE DRAW MENU
}
begin
  case ono of
    0 : Dots;
    1 : Lines;
    2 : Rectang;
    3 : Ellipses(CTOC);
    4 : Ellipses(RAD);
  end;
end;


end.

