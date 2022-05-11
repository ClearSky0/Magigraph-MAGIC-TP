Unit Majkvars;

Interface

Uses
  Dos,Crt,Graph;

function I2S(l:longint) : string;
function R2S(r : real) : string;
procedure Upstring(var s : string);

const
  NOFMENUS       = 3;
  NOFOPTS        = 4;
  MENSTLEN       = 7;
  OPTSTLEN       = 12;
  NOTMGPMSG      = 'That is not a Magigraph picture file.  Press ESCAPE.';
  DELCKMSG       = 'Are you sure, RETURN to DELETE or ESCAPE to CANCEL.';
  INVFILEMSG     = 'Invalid filename, must have the extention MGP.  Press ESCAPE.';
  INVPATHMSG     = 'That is an invalid path name.  Press ESCAPE.';
  EXISTMSG       = 'File already exists, Press RETURN to OVERWRITE or ESCAPE to CANCEL.';
  PRINTMSG       = 'Printer not available for use.  Press ESCAPE.';
  LIMITMSG       = 'You have reached the storage capacity of magigraf.  Im VERY sorry!  Press ESC.';
  NFILEMSG       = 'NO FILES';
  FILERRMSG      = 'There has been an error in reading the file, Press ESCAPE';
  FILSAVMSG      = 'There has been an error in reading the file, Press ESCAPE';
  SAVEFILEMSG    = 'Do you wish to save the current drawing?  Press RETURN to SAVE or ESCAPE.';
  LMSG           = 'Leftbutton to LOAD  :  ';
  DELMSG         = 'Leftbutton to DELETE : ';
  CMSG           = 'Rightbutton CANCEL';
  PENDMSG        = 'Pen=Down';
  PENUMSG        = 'Pen=Up';
  NOPEN          = -1;
  PENOFF         = 0;
  PENON          = 1;
  NOBAR          = FALSE;
  BAR            = TRUE;
  NOBUT          = 0;       {MOUSE BUTTON VALUES}
  LEFTBUT        = 1;
  RIGHTBUT       = 2;
  BOTHBUT        = 3;
  WANDXHOT       = 4;       {MOUSE POINTER HOT SPOTS}
  WANDYHOT       = 4;
  CROSSXHOT      = 7;
  CROSSYHOT      = 7;
  NUMOFROWS      = 20;      {USED IN FILE HANDLING DISPLAY}
  NUMOFCOLS      = 7;
  MAXIMUMOBJECTS = 1900;    {MAXIMUM NUMBER OF OBJECTS THAT CAN BE STORED IN MEMORY}
  RAD            = 0;       {RADIUS ELLIPSE ie FROM THE CENTER OUTWARDS}
  CTOC           = 1;       {ELLIPSE FROM CORNER TO CORNER}
  MOUSE          = $33;     {MOUSE INTERRUPT NUMBER}
  UP             = #72;     {KEYBOARD CODES}
  DOWN           = #80;
  LEFT           = #75;
  RIGHT          = #77;
  HOME           = #71;
  ENND           = #79;
  BKSPC          = #8;
  RET            = #13;
  ESC            = #27;
  INS            = #82;
  DEL            = #83;
  NOFHELP        = 9;

  HELPMSGS : array[0..NOFHELP,0..2] of string[49]=
((
'            Welcome to Magigraph!',
'You can access a Help screen to give information',
'on the current mode at any time, by pressing F1.'
),(
'You are at menu level, use the RIGHT button to',
'pull a menu.  You must keep the button down until',
'you have chosen an option.'
),(
'Pixel mode.  You can use the LEFT button to draw',
'a pixel, the RIGHT button will take you back to',
'the menus or BACKSPACE will delete last object.'
),(
'Line Mode.  To draw a line press and keep down',
'the LEFT button, move to the end of the line and',
'release button.  RIGHT=menus, BACKSPACE=delete.'
),(
'Rectangle mode.  Press and keep down the LEFT',
'button then move to the other corner and release',
'the button.  RIGHT=menus, BACKSPACE=delete.'
),(
'Corner to Corner Ellipse.  Press and keep LEFT',
'button down, move to other corner of rectangle',
'that encloses ellipse and release the button.'
),(
'Radius Ellipse.  Mark the centre of the Ellipse',
'with the LEFT button, keep it down and then move',
'until you have the desired major and minor axes.'
),(
'Zoom mode.  Use the LEFT button to Zoom out, the',
'RIGHT button to Zoom in and BOTH buttons will',
'cause a Refresh.  ESCAPE to return to the menus.'
),(
'Move mode.  Chose the area you wish to be centred',
'then click there with the LEFT button.  The RIGHT',
'button will take you back to the menus.'
),(
'Edit mode.  Use the arrow keys and HOME & END to',
'move through the objects, UP & DOWN move in steps',
'of ten.  Use DEL to remove the highlighted object.'
));
  {CONSTANT ARRAYS FOR MENUS}
  MENS : array[0..NOFMENUS] of string[MENSTLEN]=
  ('File','Draw','Redraw','Options');
  OPTS : array[0..NOFMENUS,0..NOFOPTS] of string[OPTSTLEN]=
  (('Save','Load','Delete','Dos Shell','Quit'),
   ('Point','Line','Rectangle','CtoC Ellipse','Radi Ellipse'),
   ('Clear','Refresh','Zoom','Move','Set Defaults'),
   ('Grid ON','Dump Screen','Edit','',''));

  {BIT-MAPS FOR MOUSE POINTER ON EGA}
  WANDCON : array[0..31] of word =
  ($FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,
   $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,
   $0000,$4900,$2A00,$1C00,$7700,$1C00,$2A00,$4900,
   $0080,$0040,$0020,$0010,$0008,$0004,$0002,$0000);
  CROSSCON : array[0..31] of word =
   ($FFFF,$FC7F,$FC7F,$FC7F,$FC7F,$FC7F,$8003,$8103,
    $8003,$FC7F,$FC7F,$FC7F,$FC7F,$FC7F,$FFFF,$FFFF,
    $0000,$0000,$0100,$0100,$0100,$0100,$0000,$3C78,
    $0000,$0100,$0100,$0100,$0100,$0000,$0000,$0000);

type
  TITLEPOS = record               {RECORD FOR STORING START AND END POSITIONS OF MENU TITLES}
    start,finish : integer;
  end;

  OPTBOX = record                 {HOLDS COORDS OF EACH OPTION IN CURRENT MENU}
    x,y : integer;
  end;

  ENUMTYPE = (NULL,POINT,LIN,ELLIPS,RECT);      {USED ONLY FOR STRUCTURE BELOW}

  PICOBJ = record                               {STRUCTURE USED TO HOLD ALL TYPES OF SCREEN OBJECT}
    case objectype : ENUMTYPE of
      NULL   : ();
      POINT  : (px,py : real);
      LIN    : (lx1,ly1,lx2,ly2 : real);
      ELLIPS : (ex1,ey1,ex2,ey2 : real);
      RECT   : (rx1,ry1,rx2,ry2 : real);
    end;

  MOUSEARRAY = array[0..31] of word;

var
  menuname                    : array [0..NOFMENUS] of TITLEPOS;        {COORDS OF MENU TITLES}
  optul,optbr                 : array [0..NOFOPTS] of OPTBOX;           {COORDS OF MENU OPTIONS}
  menus                       : array[0..NOFMENUS] of string[MENSTLEN];
  options                     : array[0..NOFMENUS,0..NOFOPTS] of string[OPTSTLEN];
  picobject                   : array [0..MAXIMUMOBJECTS] of PICOBJ;    {ARRAY CONTAINING ALL THE OBJECTS}
  BARBOX                      : array[1..8] of integer;                 {ARRAY FOR FILLPOLY IN PRINTONBAR}
  PICTUREFILE                 : file of PICOBJ;                         {DECLARATION OF FILE TYPE}
  windul,windbr               : OPTBOX;                                 {COORDS OF MENU WINDOWS}
  wand,cross                  : MOUSEARRAY;                             {VARIABLES FOR MOUSE CURSORS}
  ul                          : string;                                 {NULL STRING VARIABLE TO PASS TO Editgstring}
  chr2                        : char;
  HERC,grdst,gridcall,
  drawingchanged              : boolean;                                {GRID STATE, GRAPHICS CARD & FILESAVE FLAGS}
  ono,mno                     : shortint;                               {OPTION AND MENU NUMBER}
  regs                        : registers;                              {USED IN INTERRUPT CALLS TO GAIN ACCESS TO REGISTERS}
  scale                       : real;
  menutitlebuf,restbuf,curbuf,
  barbuf                      : pointer;                                {USED IN MENUDRV FOR WINDOWING}
  menutitlesiz,restsiz,cursiz,
  barsiz                      : word;
  filename,curpath,curpattern,
  savename                    : string;                                 {FILE VARIABLES}
  windt,windb,windl,windr,
  curobj,xoff,yoff,exoff,eyoff,
  GRDRIVER,GRMODE,MAXX,MAXY,
  MAXC,BARBOT,BARRIGHT,TEXTH,
  TEXTW,GRERROR,WINL,WINT,
  WINR,WINB,mode              : integer;                                           {OTHER GLOBAL VARS}

Implementation

procedure Upstring(var s : string);
{
CONVERT WHOLE STRINGS INTO UPPERCASE
  PARAMS : S = STRING TO BE CONVERTED
  LOCALS : F = COUNTER
}
var
  f : integer;
begin
  for f:=1 to Length(s) do
    s[f]:=Upcase(s[f]);
end;

function I2S(l : longint) : string;
{
CONVERT INTEGER TO STRING
  PARAMS : L = NUMBER TO BE CONVERTED
  LOCALS : S = STRING TO BE RETURNED
  RETURNS S
}
var
  s : string;
begin
  Str(l, s);
  I2S := s;
end;

function R2S(r : real) : string;
{
CONVERT REAL TO STRING
  PARAMS : R = NUMBER TO BE CONVERTED
  LOCALS : S = STRING TO BE RETURNED
  RETURNS S
}
var
  s : string;
begin
  Str(r:6:2, s);             {CONVERT WITH 6 DIGITS INCLUDING 2 DECIMAL PLACES}
  R2S := s;
end;

var
   a,b : byte;       {LOCAL VAR TO MAJKVARS}

{THIS CODE IS NOT CALLED BUT IS EXECUTED BEFORE MAGIC'S MAIN PROCEDURE AS AN INTIATING ROUTINE}

begin
  for a :=0 to 31 do cross[a] :=CROSSCON[a];     {TRANSFER MOUSE POINTERS FROM CONSTANT TO VAR EASIEST WAY}
  for a :=0 to 31 do wand[a] :=WANDCON[a];
  for a :=0 to NOFMENUS do menus[a] :=MENS[a];   {SAME FOR MENUS AND OPTIONS}
  for a :=0 to NOFMENUS do
    for b :=0 to NOFOPTS do
      options[a,b] :=OPTS[a,b];
  ono :=-1;                            {OPTION NUMBER 'FALSE'}
  mno :=-1;                            {MENU NUMBER 'FALSE'}
  scale :=2;                           {DEFAULT MAGNIFICATION}
  curobj :=0;                          {FIRST OBJECT}
  grdst :=FALSE;                       {GRID OFF}
  gridcall :=FALSE;                    {GRID NOT CALLED}
  filename :='NO NAME';                {SET DEFAULT FILE VARIABLES}
  curpath :='C:\TP\PICTURES\';
  curpattern :='C:\TP\PICTURES\*.MGP';
  savename :='';
  ul:='';
  drawingchanged:=FALSE;
  mode:=0;
end.

