Unit Mousedrv;
{SEE MAGIGRAPH 'C' VERSION FOR INFO ON MOUSE INTERRUPT FUNCTIONS}
Interface

Uses
  Dos,Crt,Graph,Majkvars;

function Editgstring(x,y,bc,fc : integer;c : string;var s : string;edit : boolean) : boolean;
procedure Showbar;

function Minit    : boolean;
function Mbutstat : integer;
function Mbutrel  : integer;
function Mstatus  : integer;
procedure Mshow(stat : boolean);
procedure Mposet(x,y : integer);
procedure Mdomain(minx,miny,maxx,maxy : integer);
procedure Mnewpointer(xhot,yhot : integer;cursor : MOUSEARRAY);
procedure Mratio(xrat,yrat : byte);
procedure Mremove;

Implementation
var
  moldx,moldy    : integer;       {USED TO CONTROL MOUSE CURSOR GENERATED FOR HERC}
  trip           : boolean;


function Editgstring(x,y,bc,fc : integer;c : string;var s : string;edit : boolean) : boolean;
{
MULTIPURPOSE DISPLAY AND EDIT FUNCTION FOR GRAPHICS MODE
 PARAMS : x = X COORD ON SCREEN
          y = Y COORD ON SCREEN
          bc = BACKGROUND COLOUR
          fc = FORGROUND COLOUR
          c = CONSTANT STRING TO BE DISPLAYED WITH VARIABLE
          s = STRING TO BE EDITED
          edit = FLAG FOR EDIT OR DISPLAY ONLY
 LOCALS : ply = ARRAY FOR FILLPOLY PROCEDURE
          ch = CHARACTER READ FROM KEYBOARD
          s2 = COPY OF THE STRING BEING EDITED
          ps = POSITION IN STRING
          slen = STRING LENGTH
 RETURNS : TRUE IF RETURN ENDS EDITING OR FALSE IF ESCAPE ENDS EDITING AND STRING IS RETURNED TO ORIGINAL VALUE
}
var
  ply          : array[0..7] of integer;
  ch           : char;
  s2           : string[60];
  ps,slen      : integer;
begin
  ch:=#255;
  Mshow(FALSE);
  ps:=0;
  s2:=s;
  Setfillstyle(SOLIDFILL,bc);                    {SET BACKGROUND COLOR}
  slen:=Length(c+s2);
  ply[0]:=x-3-TEXTW*2;         ply[1]:=y-3;     {CALCULATES THE AREA AROUND THE STRING TO BE CLEARED}
  ply[2]:=x+3+TEXTW*(2+slen);  ply[3]:=ply[1];
  ply[4]:=ply[2];              ply[5]:=y+TEXTH+1;
  ply[6]:=ply[0];              ply[7]:=ply[5];
  Setcolor(bc);
  Fillpoly(4,ply);
  Setcolor(fc);                                  {SET FORGROUND COLOR}
  Outtextxy(x,y,c+s2);
  if edit then Outtextxy(x+TEXTW*ps+Textwidth(c),y,'_'); {IF IN EDIT MODE THEN DRAW A CURSOR}
  repeat
    slen:=Length(s2);
    ply[2]:=x-3+TEXTW*(3+slen)+Textwidth(c);
    ply[4]:=ply[2];
    if keypressed then
    begin
      ch:=Readkey;
      if edit then                          {ONLY IN EDIT MODE ALLOW EDITING}
      begin
        case ch of
          #0 : begin                        {IF AN EXTENDED KEY CODE}
                 ch:=Readkey;
                 case ch of
                   LEFT       : if ps>0 then Dec(ps);
                   RIGHT      : if ps<=slen then Inc(ps);
                   HOME       : ps:=0;
                   ENND       : ps:=slen+1;
                   DEL        : s2:=Concat(Copy(s2,1,ps),Copy(s2,ps+2,slen));
                 end;
               end;
          BKSPC : begin
                    if ps=slen then s2:=Copy(s2,1,slen-1)
                      else s2:=Concat(Copy(s2,1,ps-1),Copy(s2,ps+1,slen));
                    if ps>0 then Dec(ps);
                  end;
        else if (Ord(ch)>31) and (Ord(ch)<128) and edit then    {ANY CHARACTER BETWEEN 32 AND 128 IS A VALID ENTRY}
          begin
            s2:=Concat(Copy(s2,1,ps),ch,Copy(s2,ps+1,slen));
            if ps<=slen then Inc(ps);
          end;
        end;
        Setcolor(bc);                       {NO OUTLINE AROUND FILLPOLY}
        Fillpoly(4,ply);                    {CLEAR OLD STRING AND PRINT NEW ONE}
        Setcolor(fc);
        Outtextxy(x,y,c+s2);
        Outtextxy(x+TEXTW*ps+Textwidth(c),y,'_');
      end;
    end;
  until (ch=ESC) or (ch=RET);               {KEEP EDITING UNTIL ESC OR RET}
  if ch=RET then
  begin
    Editgstring:=TRUE;                      {RETURNS TRUE}
    s:=s2;                                  {LETS THE REAL STRING = THE EDITED STRING}
  end
    else
  begin
    Editgstring:=FALSE;                     {FORGET THE EDITED STRING AND RETURN FALSE}
  end;
  if edit then
  begin
    Setcolor(bc);
    Fillpoly(4,ply);                        {IF EDIT MODE REPRINT FINAL STRING}
    Setcolor(fc);
    Outtextxy(x,y,c+s);
  end;
  Mshow(TRUE);
end;

procedure Mremove;
{
REMOVES MOUSE POINTER ON HERC ONLY
}
begin
  if HERC then Putimage(moldx-4,moldy-4,curbuf^,XORPUT);
end;

procedure Setmpointer;
{
DRAWS THE MOUSE POINTER FOR HERCULES AND STORES IT IN A BUFFER FOR PUTIMAGE
}
begin
  cursiz :=Imagesize(200,200,208,208);
  Getmem(curbuf,cursiz);
  Line(200,204,208,204);
  Line(204,200,204,208);
  Getimage(200,200,208,208,curbuf^);
  Putimage(200,200,curbuf^,XORPUT);
end;

procedure Movemouse;
{
PROCEDURE FOR MOVING HERCULES MOUSE POINTER
}
begin
  if trip =FALSE then                                      {IF THIS IS THE FIRST CALL THEN INITIALIZE OLD POSITIONS}
  begin
    trip :=TRUE;
    moldx :=regs.cx;
    moldy :=regs.dx;
  end;
  if ((moldx<>regs.cx) or (moldy<>regs.dx)) and HERC then  {IF THE OLD POS <> CURRENT POSITION}
  begin
    Putimage(moldx-4,moldy-4,curbuf^,XORPUT);              {THEN REMOVE OLD CURSOR AND}
    Putimage(regs.cx-4,regs.dx-4,curbuf^,XORPUT);          {PUT NEW ONE}
    moldx :=regs.cx;
    moldy :=regs.dx;
  end;
end;

function Minit : boolean;
{
INITIALIZE MOUSE AND TEST FOR ITS EXISTANCE
 RETURNS : TRUE IF MOUSE ON
}
begin
  if HERC then Setmpointer;
  regs.ax :=0;
  Intr(MOUSE,regs);
  if regs.ax =0 then Minit :=FALSE          {IF MICROSOFT MOUSE DRIVER IS NOT AVAILABLE}
    else Minit :=TRUE;
  trip :=FALSE;
end;

procedure Mshow(stat : Boolean);
{
TOGGLES THE MOUSE ON AND OFF ON THE EGA OR REMOVES LAST POINTER ON HERCULES
 PARAMS : stat = ONLY OF USE WITH EGA, TRUE IF MOUSE TO BE TURNED ON
}
begin
  if HERC then Mremove
    else
  begin
  if stat then regs.ax :=1
    else regs.ax :=2;
    Intr(MOUSE,regs);
  end;
end;

function Mstatus : integer;
{
ATAINS MOUSE SCREEN COORDS AND CURRENT BUTTON STATUS.
DUE TO NOT KNOWING HOW TO INFORM THE MICROSOFT MOUSE DRIVER OF GRAPHICS MODE
CHANGES ON HERCULES, THE DOMAIN OF THE MOUSE IS MULTIPLIED BY THE WIDTH OF A
TEXT  CHAR AND THE HEIGHT OF A TEXT CHAR.  WHEN FINDING THE LOCATION OF  THE
MOUSE IT IS DIVIED BY THE SAME VALUES.
}
begin
  regs.ax :=3;
  Intr(MOUSE,regs);
  Mstatus :=regs.bx;
  if HERC then
  begin
    regs.cx :=regs.cx div 8;
    regs.dx :=regs.dx div 14;
    Movemouse;                         {SINCE MSTATUS IS MOST OFTEN USED MOUSE PROC THEN MOVEMOUSE IS CALLED FROM HERE}
  end;
end;

function Mbutstat : integer;
{
ATTAINS POSITION BUTTON WAS LAST PRESSED
 RETURNS : regs.ax, BUTTON NUMBER
}
begin
  regs.ax :=5;
  Intr(MOUSE,regs);
  Mbutstat :=regs.ax;
end;

function Mbutrel : integer;
{
ATTAINS POSITION BUTTON WAS RELEASED
 RETURNS : regs.ax, BUTTON NUMBER
}
begin
  regs.ax :=6;
  Intr(MOUSE,regs);
  Mbutrel :=regs.ax;
end;

procedure Mposet(x,y : integer);
{
SETS THE MOUSE POSITION AND TAKES INTO ACOUNT THE HERCULES PROBLEM
 PARAMS : x,y = COORDS TO SET MOUSE TO
}
begin
  with regs do
  begin
    ax :=4;
    if HERC then
    begin
      cx :=x*8;
      dx :=y*14;
    end
    else
    begin
      cx :=x;
      dx :=y;
    end;
  end;
  Intr(MOUSE,regs);
end;

procedure Mdomain(minx,miny,maxx,maxy : integer);
{
SETS THE DOMAIN OF MOVEMENT OF THE MOUSE AND TAKES INTO ACCOUNT THE HERCULES
PROBLEM.
 PARAMS : minx,miny = MINIMUM AND MAXIMUM X RANGE OF MOVEMENT
          maxx,maxy = MINIMUM AND MAXIMUM Y RANGE OF MOVEMENT
}
begin
  if HERC then
  begin
    minx :=minx *8;
    miny :=miny *14;
    maxx :=maxx *8;
    maxy :=maxy *14;
  end;
  regs.ax :=7;
  regs.cx :=minx; regs.dx :=maxx;
  Intr(MOUSE,regs);
  regs.ax :=8;
  regs.cx :=miny; regs.dx :=maxy;
  Intr(MOUSE,regs);
  if HERC then
  begin
    regs.cx :=regs.cx div 8;
    regs.dx :=regs.dx div 14;
    Movemouse;                         {SERVICE HERCULES POINTER}
  end;
end;

procedure Mnewpointer(xhot,yhot : integer;cursor : MOUSEARRAY);
{
CHANGE MOUSE POINTER ON THE EGA
 PARAMS : xhot,yhot = ACTIVE POINT OF CURSOR RELATIVE TO BITMAP
          cursor = ARRAY OF 32x16 THAT HOLDS BIT MAP AND MASK FOR CURSOR
}
begin
  with regs do
  begin
    ax :=9;
    bx :=xhot;
    cx :=yhot;
    dx :=Ofs(cursor);
    es :=Seg(cursor);
  end;
  Intr(MOUSE,regs);
end;

procedure Mratio(xrat,yrat : byte);
{
ALTERS THE MOUSE MOVEMENT RATIO
 PARAMS : xrat,yrat RATIO OF MOVEMENT IN BOTH AXES
}
begin
  with regs do
  begin
    ax :=15;
    cx :=xrat;
    dx :=yrat;
  end;
  Intr(MOUSE,regs);
end;

procedure Showbar;
{
DISPLAYS MENUBAR ACROSS TOP OF SCREEN
 LOCALS : curpos = CURRENT SCREEN POSITION
          barbuf,barsiz = VARIABLES FOR BUFFER
          curmen = CURRENT MENU
}
var
  curpos : integer;
  barsiz : word;
  barbuf : pointer;
  curmen : shortint;
begin
  curpos :=TEXTW;
  BARBOT := TEXTH+1;
  BARRIGHT := MAXX;
  BARBOX[1] :=   0; BARBOX[2] :=0;               {FOR FILLPOLY IN PRINTONBAR}
  BARBOX[3] :=MAXX; BARBOX[4] :=0;
  BARBOX[5] :=MAXX; BARBOX[6] :=BARBOT;
  BARBOX[7] :=   0; BARBOX[8] :=BARBOT;
  Mshow(FALSE);
  for curmen :=0 to NOFMENUS do
    with menuname[curmen] do
    begin
      start :=curpos-1;                                    {CALCULATE COORDS OF MENU TITLES}
      finish :=curpos+Textwidth(menus[curmen])+1;
      Outtextxy(curpos,1,menus[curmen]);                   {AND PRINT THEM}
      curpos :=curpos+Textwidth(menus[curmen])+TEXTW*2;
    end;
  Outtextxy(MAXX-Textwidth('F1 for HELP')-TEXTW,1,'F1 for HELP');
  barsiz :=Imagesize(0,0,BARRIGHT,BARBOT);               {INVERT WHOLE MENU BAR}
  Getmem(barbuf,barsiz);
  Getimage(0,0,BARRIGHT,BARBOT,barbuf^);
  Putimage(0,0,barbuf^,NOTPUT);
  Freemem(barbuf,barsiz);
  Mshow(TRUE);
end;


end.

