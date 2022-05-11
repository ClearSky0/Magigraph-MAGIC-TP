Unit Prefopts;

Interface

Uses
  Dos,Crt,Graph,Majkvars,Mousedrv,Redrawop;

procedure Prefmenu;
procedure HARDCOPY(Inverse : boolean; Mode : byte);

Implementation

procedure Grid;
{
DRAWS A SQUARE GRID PATTERN ON THE SCREEN
 LOCALS : a,b,c = COUNTERS
}
var
  a,b,c : integer;

begin
  gridcall :=TRUE;
  options[3,0]:='Grid On';         {CHANGES MENU OPTION}
  if grdst then Refresh(BAR)
    else
  begin
    b :=0;
    c :=0;
    Mshow(FALSE);
    Setviewport(0,BARBOT,MAXX,MAXY,CLIPON);
    Setlinestyle(DOTTEDLN,0,1);    {DRAWS GRID IN DOTTED LINES}
    for a :=0 to 70 do
      begin
        Sound(400);Nosound;
        Line(0,b,MAXX,b);      {HORIZONTAL LINE}
        Line(c,0,c,MAXY);      {VERTICAL LINE}
        Inc(b,MAXY div 20);
        Inc(c,MAXX div 29);
      end;
    Setlinestyle(SOLIDLN,0,1);
    Setviewport(0,0,MAXX,MAXY,CLIPON);
    Mshow(TRUE);
    options[3,0] :='Grid OFF'; {CHANGE MENU OPTION}
  end;
  grdst :=not grdst;
  gridcall :=FALSE;
end;

procedure HardCopy(Inverse : boolean; Mode : byte);
{
THIS PROCEDURE IS TAKEN FROM THE GRAPHICS TOOLBOX

GRAPHICS SCREEN DUMP ROUTINE FOR EPSON COMPATIBLE
PRINTERS. PRE-FX SERIES OF EPSON PRINTERS SHOULD
ONLY USE MODE 1.
MODE: 1       = DOUBLE-DENSITY 120 DOTS PER INCH
      2       = HIGH-SPEED D-D 120 DOTS PER INCH
      3       = QUADRUPLE-DENSITY 240 DOTS PER INCH
      0, 4, 5 = 80 DOTS PER INCH
      6       = 90 DOTS PER INCH
}
const
  Esc   = 27;
var
  ScanLine : integer; {THE CURRENT SCAN LINE}
  n1, n2   : byte;    {2 BYTE PRINTER CONTROL CODE}
  ch       : char;

function BaseAddress(Y : word) : word;
{
CALCULATE THE ADDRESS OF SCANLINE Y
}
begin
  BaseAddress := (Y and 3) shl 13 + 90 * (Y shr 2);
end;

procedure SendByte(B : byte);
{
SEND ONE BYTE TO THE PRINTER
}
const
  LPTPortNum = 1; {DEFAULTS TO LPT1. 2 = LPT2}
var
  Regs : Registers;
begin
  Regs.AH := 0;
  Regs.AL := B;
  Regs.DX := Pred(LPTPortNum);
  Intr($17, Regs);
end;

{$B+}  {TURN OFF SHORT CIRCUIT BOOLEAN EVALUATION}

function ConstructByte(X, Y : integer) : byte;
{
CONSTRUCT A PRINT BYTE BY READING BITS FROM THE GRAPHICS SCREEN BUFFER
}
const
  Bits : array[0..7] of byte = (128,64,32,16,8,4,2,1);
var
  CByte, Bit : byte;
  gbase : word;
begin
  Y := Y shl 3;  { Y := Y * 8 }
  CByte := 0;
  if HERC then gbase:=$B000
  else gbase:=$A000;
  for Bit := 0 to 7 do
  if ((Mem[gbase:Baseaddress(Y+Bit) + X shr 3] and Bits[X and 7]) <> 0) then
    CByte := CByte + Bits[Bit];
  ConstructByte := CByte;
end;

{$B-}  {TURN ON SHORT CIRCUIT BOOLEAN EVALUATION}

procedure DoLine;
{
DUMPS ONE PRINT LINE TO THE PRINTER
}
var
  XPixel    : integer;
  PrintByte : byte;
begin
  if Mode = 1 then
    begin
      SendByte(Esc);        {SELECT DOUBLE-DENSITY GRAPHICS PRINT MODE}
      SendByte(Ord('L'));
    end
  else
    begin                   {SELECT 8-PIN GRAPHICS PRINT MODE}
      SendByte(Esc);
      SendByte(Ord('*'));
      SendByte(Mode);
    end;
  SendByte(n1);             {SEND 2 BYTE CONTROL CODE}
  SendByte(n2);
  for XPixel := 0 to MAXX do
  begin
    PrintByte := ConstructByte(XPixel, ScanLine);
    if Inverse then
      PrintByte := not PrintByte;
    SendByte(PrintByte);    {SEND PRINT BYTE}
  end;
  SendByte(10);             {SEND LINE FEED}
end;

begin {HARDCOPY}
  Mshow(FALSE);
  Mode := Mode mod 7;              {MODES 0 THROUGH 6 SUPPORTED}
  if (Mode = 0) or (Mode = 5) then
    Mode := 4;                     {MODES 0 AND 5 USE MODE 4}
  SendByte(Esc);                   {SELECT 24/216-INCH LINE SPACING}
  SendByte(Ord('3'));
  SendByte(24);
  n1 := Lo(Succ(MAXX));   {DETERMINE 2 BYTE CONTROL CODE FOR}
  n2 := Hi(Succ(MAXX));   {THE NUMBER OF DOTS PER PRINT LINE}
  for ScanLine := 0 to (MAXY div 8) do
  begin
    if Keypressed then scanline:=MAXY div 8;   {THIS ALLOWS THE USER TO CANCEL}
    DoLine;                                    {DO A PRINT LINE}
  end;
  SendByte(Esc); SendByte(2);      {SELECT 1/6-INCH LINE SPACING}
  Mshow(TRUE);
end; { HardCopy }

function Printready : boolean;
{
CHECK PRINTER STATUS
 RETURNS : TRUE IF PRINTER AVAILABLE
}
begin
  regs.ah:=2;
  regs.dx:=0;
  Intr($17,regs);
  if (regs.ah and 144)=144 then Printready:=TRUE
  else
  begin
    Printready:=FALSE;
    Sound(500);Delay(20);Sound(300);Delay(60);Sound(400);Delay(60);Nosound;
    if Editgstring((MAXX div 2)-(Textwidth(PRINTMSG)) div 2,MAXy div 2,MAXC,0,PRINTMSG,ul,FALSE) then;
    Setcolor(MAXC);
    Refresh(BAR);
  end;
end;

procedure Edit;
{
ALLOWS EDITING OF ALL OBJECTS
 LOCALS : ch = FOR KEYBOARD READ
          lastobject = HOLDS CUROBJ'S ORIGINAL VALUE
          oldobj = STORES THE VALUE OF curobj BEFORE A KEY WAS PRESSED
          validkeypress = TRUE IF A KEY WAS PRESSED THAT RESULTED IN SOMETHING BEING PERFORMED
}
var
  ch                 : char;
  lastobject,oldobj  : integer;
  validkeypress      : boolean;
  tempobj            : integer;

procedure Deleteobject;
{
DELETES AN OBJECT BY MOVING ALL OBJECTS AFTER THE CURREN ONE DOWN BY ONE
 LOCALS : a = COUNTER
}
var
  a : integer;
begin
  Sound(300);Delay(10);Nosound;
  for a:=curobj to lastobject do
    if (curobj<=lastobject) and (curobj>0) then
    begin
      picobject[a]:=picobject[a+1];
    end;
    Dec(lastobject);
    if curobj>=lastobject then Dec(curobj);
end;

procedure Specialcase(objectnum : integer);
{
CASE STATEMENT THAT IS USED TWICE IN Specialrefresh, DRAWS OBJECT AFTER
DECIDING WHICH TYPE IT IS
 PARAMS : objectnum = NUMBER OF THE OBJECT TO BE REFRESHED
}
begin
  case picobject[objectnum].objectype of {DRAWS THE OBJECTS AS USUAL}
    POINT : with picobject[objectnum] do
            Putpixel(Round(px*scale)+xoff,Round(py*scale)+yoff,Getcolor);
    LIN : with picobject[objectnum] do
            Line(Round(lx1*scale)+xoff,Round(ly1*scale)+yoff,
                 Round(lx2*scale)+xoff,Round(ly2*scale)+yoff);
    ELLIPS : with picobject[objectnum] do
            Ellipse(Round(ex1*scale)+xoff,Round(ey1*scale)+yoff,
                    0,360,Round(ex2*scale),Round(ey2*scale));
    RECT : with picobject[objectnum] do
            Rectangle(Round(rx1*scale)+xoff,Round(ry1*scale)+yoff,
                      Round(rx2*scale)+xoff,Round(ry2*scale)+yoff);
  end;
end;

procedure Specialrefresh;
{
REFRESH WITH THE ADDITION OF COLOUR CHANGES TO THE CURRENT OBJECT
ON THE HERC ALL OBJECTS BUT THE CURRENT ONE ARE DRAWN BLACK
ON THE EGA THE CURRENT OBJECT FLASHES
}
begin
if not gridcall and HERC then
  begin
    options[3,0]:='Grid ON';
    grdst :=FALSE;
  end;
  if HERC then Setcolor(0)
  else Setcolor(MAXC);
  Specialcase(oldobj);
  if HERC then Setcolor(MAXC)
  else Setcolor(MAXC-1);
  Specialcase(curobj);
  Setcolor(MAXC);
  Rectangle(0,0,MAXX,MAXY);
  Setcolor(MAXC);
end;

begin    {EDIT}
  mode:=9;
  lastobject:=curobj-1;
  oldobj:=1;
  curobj:=1;
  validkeypress:=FALSE;
  Mshow(FALSE);
  if HERC then Cleardevice;
  Specialrefresh;
  Printonbar('Edit mode now active.  Press ESCAPE to leave.',NOPEN);
  Rectangle(0,0,MAXX,MAXY);
  repeat
    if Keypressed then
    begin
      ch:=Readkey;
      if ch = #0 then
      begin
        ch:=Readkey;
        case ch of
          LEFT    : if curobj>1 then
                    begin
                      Dec(curobj);
                      validkeypress:=TRUE;
                    end;
          RIGHT   : if curobj<lastobject then
                    begin
                      Inc(curobj);
                      validkeypress:=TRUE;
                    end;
          HOME    : begin
                      curobj:=1;
                      validkeypress:=TRUE;
                    end;
          ENND    : begin
                      curobj:=lastobject;
                      validkeypress:=TRUE;
                    end;
          DEL     : begin
                      drawingchanged:=TRUE;
                      Setcolor(0);
                      if HERC then Specialcase(curobj);
                      Deleteobject;
                      Setcolor(MAXC);
                      if not HERC then
                      begin
                        tempobj:=curobj;
                        curobj:=lastobject;
                        Refresh(BAR);
                        curobj:=tempobj;
                        Printonbar('Edit mode now active.  Press ESCAPE to leave.',NOPEN);
                      end;
                      validkeypress:=TRUE;
                    end;
          UP      : if curobj+10<lastobject then
                    begin
                      Inc(curobj,10);
                      validkeypress:=TRUE;
                    end;
          DOWN    : if curobj-10>1 then
                    begin
                      Dec(curobj,10);
                      validkeypress:=TRUE;
                    end;
          #59     : Help;
        end;
      end;
      if validkeypress then
      begin
        Specialrefresh;
        oldobj:=curobj;
        validkeypress:=FALSE;
        if (Round(picobject[curobj].py*scale)+yoff) < BARBOT then              {IF SOMETHING HAS BEEN DRAWN OVER THE MENUBAR}
          Printonbar('Edit mode now active.  Press ESCAPE to leave.',NOPEN);
      end;
    end;
  until ch=ESC;                    {REPEATS UNTIL USER PRESSES ESCAPE}
  curobj:=lastobject+1;
  Refresh(BAR);
  Mremove;
  Mshow(TRUE);
end;

procedure Prefmenu;
{
CONTROL FOR OPTIONS MENU
}
begin
  case ono of
    0 : Grid;
    1 : if Printready then
        begin
          Printonbar('Picture name : '+filename+'.         Designed on Magigraph.',NOPEN);
          Hardcopy(FALSE,1);
          Replacemenubar;
        end;
    2 : Edit;
  end;
end;


end.

