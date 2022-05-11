Unit Fileopts;

Interface

Uses
  Dos,Crt,Graph,Majkvars,Mousedrv,Redrawop;

procedure Filemenu;

Implementation

var
  counter1,counter2,
  oldx1,oldy1,oldx2,oldy2    : integer;
  onefile                    : SEARCHREC;                                      {STORES RESULT OF FINDFIRST AND FINDNEXT}
  paray                      : array[0..7] of integer;                         {POLYGON ARRAY}
  rows                       : array[0..NUMOFROWS] of integer;                 {HOLDS COORDS OF FILENAMES}
  cols                       : array[0..NUMOFCOLS] of integer;
  files                      : array[1..NUMOFCOLS,1..NUMOFROWS] of string[12]; {HOLDS FILENAMES}

procedure Fixstring;
{
CONVERTS CURRENT FILE PATTERN TO UPERCASE & WORKS OUT THE CURRENT PATH FROM IT
}
begin
  Upstring(curpattern);
  for counter1:=Length(curpattern) downto 1 do
    if curpattern[counter1]='\' then
    begin
      curpath:=Copy(curpattern,1,counter1);
      counter1:=1;
    end;
end;

procedure Movename(newx1,newy1,newx2,newy2 : integer);
{
HIGHLIGHTS ANYTHING ON THE SCREEN BY INVERTING IT
ALSO REMOVES HIGHLIGHT FROM OLD POSITION
 PARAMS : newx1,newy1,newx2,newy2 = COORDS OF BOX TO BE HIGHLIGHTED
 LOCALS : buffer,size = FOR GET AND PUT IMAGE
}
var
  buffer : pointer;
  size   : word;
begin
  if (oldx1<>newx1) or (oldy1<>newy1) then                 {ONLY IF POSITION HAS CHANGED}
  begin
    Mshow(FALSE);
    size :=Imagesize(newx1,newy1,newx2,newy2);
    Getmem(buffer,size);
    Getimage(newx1,newy1,newx2,newy2,buffer^);
    Putimage(newx1,newy1,buffer^,NOTPUT);
    Freemem(buffer,size);
    size :=Imagesize(oldx1,oldy1,oldx2,oldy2);
    Getmem(buffer,size);                                   {INVERTS NEW BOX AND THEN FREES MEMORY}
    Getimage(oldx1,oldy1,oldx2,oldy2,buffer^);
    Putimage(oldx1,oldy1,buffer^,NOTPUT);
    Freemem(buffer,size);                                  {RETURN OLD BOX TO NORMAL}
    oldx1:=newx1;      oldy1:=newy1;
    oldx2:=newx2;      oldy2:=newy2;
    Mshow(TRUE);
  end;
end;

procedure Displaywind;
{
PUTS FILE WINDOW ON SCREEN
 LOCALS : polyparts = ARRAY FOR FILLPOLY
}
var
  polyparts  : array[0..7] of integer;
begin
  Mshow(FALSE);
  oldx1:=0;                  oldy1:=0;
  oldx2:=0;                  oldy2:=0;
  polyparts[0]:=WINL+1;      polyparts[1]:=WINB-1;
  polyparts[2]:=WINL+1;      polyparts[3]:=WINT+1;
  polyparts[4]:=WINR-1;      polyparts[5]:=WINT+1;
  polyparts[6]:=WINR-1;      polyparts[7]:=WINB-1;
  Setcolor(1);
  Rectangle(WINL-1,WINT-1,WINR+1,WINB);
  Setcolor(0);
  Setfillstyle(SOLIDFILL,MAXC);
  Fillpoly(4,polyparts);
  Mshow(TRUE);
end;

procedure Searchfiles;
{
USES FINDFIRST AND FINDNEXT TO SEARCH FOR ALL FILES IN CURRENT DIRECTORY
 LOCALS : tempfiles = 1-D ARRAY USED IN THE SORT ROUTINE
          onetemp = USED FOR SWAPPING IN SORT
          ind = INDEX INTO 1-D ARRAY
}
var
  tempfiles : array[1..112] of string[12];
  onetemp   : string[12];
  ind       : integer;

begin
  for counter1:=1 to 112 do
  begin
    if (counter1=1) then
    begin
      Findfirst(curpattern,ANYFILE,onefile);
      if DOSERROR=0 then tempfiles[1]:=onefile.name
        else tempfiles[1]:=NFILEMSG;
    end
      else
    begin
      tempfiles[counter1]:='\';          {IF THERE ARE NO MORE FILES THEN STORE NAME AS A BACKSLASH}
      Findnext(onefile);
      if DOSERROR=0 then tempfiles[counter1]:=onefile.name;
    end;
  end;                                   {THE ABOVE READS ALL THE FILES IN THE DIRECTORY}
  for counter1:=112 downto 2 do          {VERY SIMPLE, BUT VERY FAST BUBBLE SORT}
    for counter2:=1 to counter1-1 do
      if (tempfiles[counter2]>tempfiles[counter2+1]) then
      begin
        onetemp:=tempfiles[counter2];
        tempfiles[counter2]:=tempfiles[counter2+1];
        tempfiles[counter2+1]:=onetemp;
      end;
  ind:=1;
  for counter1:=1 to NUMOFCOLS-1 do
    for counter2:=1 to NUMOFROWS-1 do
    begin
      if ind<113 then files[counter1,counter2]:=tempfiles[ind]
        else files[counter1,counter2]:='\';
      Inc(ind);
    end;                                 {MOVES FILENAMES FROM 1-D ARRAY TO A 2-D ARRAY}
end;

procedure Showfiles;
{
DISPLAYS ALL FILES FOUND ONTO THE FILE WINDOW
}
begin
  Mshow(FALSE);
  Outtextxy(WINL+TEXTW,WINT+TEXTH,'Directory of   '+curpattern);
  rows[0]:=WINT+TEXTH*4;
  rows[NUMOFROWS]:=WINB-(TEXTH*4)-4;
  cols[0]:=WINL+TEXTW;
  cols[NUMOFCOLS]:=WINR-(TEXTW*3)-4;
  for counter1:=1 to NUMOFROWS-1 do
    rows[counter1] :=WINT+TEXTH*(4+(counter1-1));
  for counter1:=1 to NUMOFCOLS-1 do
    cols[counter1] :=(WINL+TEXTW)+(TEXTW*13*(counter1-1));                       {CALCULATE COORDS FOR PRINTING NAMES}
  for counter1:=1 to NUMOFCOLS-1 do
    for counter2:=1 to NUMOFROWS-1 do
      if files[counter1,counter2]<>'\' then
        Outtextxy(cols[counter1]+1,rows[counter2]+1,files[counter1,counter2]);   {DISPLAY ALL FILENAMES}
  Mshow(TRUE);
end;

{$I+}
function Save : boolean;
{
ALLOWS PICTURE FILE TO BE SAVED TO DISK
 LOCALS : overwrite = STORES USERS REPLY TO QUESTION ASKING IF HE WISHED TO OVERWRITE A FILE WITH SAME NAME
          count = FOR NEXT LOOP COUNTER
}
var
  overwrite     : boolean;
  count         : integer;
begin
  Save:=FALSE;
  ul:='';
  if savename='' then savename:=curpath+filename;
  if not Editgstring(MAXX div 3,MAXY div 5,0,MAXC,'Save picture as : ',savename,TRUE) then
  begin
    Refresh(BAR);
    Exit;                       {IF ESCAPE WAS PRESSED TO END EDITING THEN LEAVE PROCEDURE}
  end;
  Upstring(savename);
  curpattern:=savename;
  Fixstring;                    {WORK OUT PATH NAME FROM SAVE NAME}
  curpattern:=curpath+'*.MGP';
  Findfirst(curpath+'*.*',ANYFILE,onefile);
  if (DOSERROR<>0) or (Pos('.MGP',savename)=0) then      {CHECK TO SEE IF PATH IS OK AND FILENAME ENDS WITH .MGP}
  begin
    if DOSERROR<>0 then
    begin
      Sound(600);Delay(30);Sound(200);Delay(60);Sound(400);Delay(30);Nosound;
      overwrite:=Editgstring((MAXX div 2)-(Textwidth(INVPATHMSG) div 2),100,0,MAXC,INVPATHMSG,ul,FALSE)
    end
    else
    begin
      Sound(100);Delay(60);Sound(200);Delay(40);Sound(400);Delay(50);Nosound;
      overwrite:=Editgstring((MAXX div 2)-(Textwidth(INVFILEMSG) div 2),100,0,MAXC,INVFILEMSG,ul,FALSE);
    end;
    Refresh(BAR);
    Exit;
  end;
  Findfirst(savename,ANYFILE,onefile);
  if DOSERROR=0 then                  {CHECK TO SEE IF A FILE ALREADY EXISTS WITH THE SAME NAME}
  begin
    Sound(400);Delay(50);Sound(800);Delay(40);Sound(200);Delay(50);Nosound;
    overwrite:=Editgstring((MAXX div 2)-(Textwidth(EXISTMSG) div 2),100,MAXC,0,EXISTMSG,ul,FALSE);
  end;
  if (overwrite) or (DOSERROR<>0) then
  begin
    Assign(PICTUREFILE,savename);
    Rewrite(PICTUREFILE);
    if Ioresult<>0 then
    begin
      if Editgstring((MAXX div 2)-(Textwidth(FILSAVMSG) div 2),MAXY div 2,0,MAXC,FILSAVMSG,ul,FALSE) then;
      Setcolor(MAXC);
      Refresh(BAR);
      Exit;
    end;
    for count:=0 to curobj-1 do
      Write(PICTUREFILE,picobject[count]);
    Close(PICTUREFILE);
    drawingchanged:=FALSE;
    Save:=TRUE;
  end;                                {SAVE ALL CURRENTLY DRAWN OBJECTS}
  Setcolor(MAXC);
  xoff:=EXOFF;
  yoff:=EYOFF;
  scale:=2;
  Refresh(BAR);
  ul:='';
end;
{$I+}

function Filechosen : boolean;
{
CHECKS POSITION OF MOUSE AND CONTROLS THE HIGHLIGHTING OF THE FILENAMES
ALLOWS EDITING OF CURRENT PATTERN
 LOCALS : dirend,dirstart = COORDS OF BEGINNING AND END OF CURPATTERN
          oldfname = OLD FILE NAME
}
var
  dirend,dirstart : integer;
  oldfname   : string[12];
begin
  dirstart:=WINL+TEXTW+Textwidth('Directory of   ');
  dirend:=WINL+TEXTW+Textwidth('Directory of   '+curpattern);
  Filechosen:=FALSE;
  paray[0]:=WINL+Textwidth(LMSG);         paray[1]:=WINB-(TEXTH*2);
  paray[2]:=paray[0]+(TEXTW*12);          paray[3]:=paray[1];
  paray[4]:=paray[2];                     paray[5]:=WINB-TEXTH;
  paray[6]:=paray[0];                     paray[7]:=paray[5];
  repeat
    for counter1:=0 to NUMOFCOLS-1 do                     {SCANS ALL FILE POSITIONS TO FIND WHERE MOUSE IS}
      if (regs.cx>cols[counter1]) and (regs.cx<cols[counter1+1]) then
        for counter2:=0 to NUMOFROWS-1 do
          if (regs.dx>rows[counter2]) and (regs.dx<rows[counter2+1]) then
            if files[counter1,counter2]<>'\' then
            begin
              Movename(cols[counter1],rows[counter2],cols[counter1+1]-TEXTW,rows[counter2+1]);
              filename :=files[counter1,counter2];
              if filename<>oldfname then
              begin
                Mshow(FALSE);
                Fillpoly(4,paray);
                Outtextxy(paray[0],paray[1],filename);
                Mshow(TRUE);
                oldfname:=filename;
              end;
            end;
  if (regs.dx>WINT+TEXTH) and (regs.dx<WINT+TEXTH*2) then     {IF MOUSE IS OVER FILE PATTERN THE HIGHLIGHT IT}
    Movename(dirstart-1,WINT+TEXTH-1,dirend-1,WINT+TEXTH*2-1);
  until Mstatus<>0;
  if (regs.bx=LEFTBUT) then
    if (regs.dx>WINT+TEXTH) and (regs.dx<WINT+TEXTH*2) then
    begin
      if Editgstring(dirstart,WINT+TEXTH,MAXC,0,'',curpattern,TRUE) then
      begin       {IF THE USER HAS EDITED THE PATTERN THEN REDISPLAY NEW DIRECTORY OF FILES}
        Fixstring;
        Displaywind;
        Outtextxy(WINL+TEXTW,WINB-(TEXTH*2),LMSG);
        Outtextxy(WINR-Textwidth(CMSG)-(TEXTW*2),WINB-(TEXTH*2),CMSG);
        Searchfiles;
        Showfiles;
      end;
    end
    else Filechosen:=TRUE
  else      {IF ANY OTHER BUTTON THAN LEFTBUT IS PRESSED THEN NO FILE IS CHOSEN}
    begin
      filename:=NFILEMSG;
      Filechosen:=TRUE;
    end;
end;

{$I+}
procedure Load;
{
CONTROLS ORDER OF EVENTS WHEN CHOSING A FILE TO LOAD AND LOADS THE CHOSEN FILE
}
begin
  Displaywind;
  Outtextxy(WINL+TEXTW,WINB-(TEXTH*2),LMSG);
  Outtextxy(WINR-Textwidth(CMSG)-(TEXTW*2),WINB-(TEXTH*2),CMSG);
  Searchfiles;
  Showfiles;
  repeat until Filechosen;
  Upstring(filename);
  if (Pos('.MGP',filename)=0) and (regs.bx<>RIGHTBUT) then      {IF A VALID FILENAME}
  begin                                                         {THEN DISPLAY ERROR MESSAGE}
    filename:=NFILEMSG;
    Nosound;Sound(400);Delay(15);Sound(300);Delay(15);Sound(600);Delay(15);Nosound;
    if Editgstring((MAXX div 2)-(Textwidth(NOTMGPMSG) div 2),MAXY div 2,0,MAXC,NOTMGPMSG,ul,FALSE) then;
  end;
  if (regs.bx=LEFTBUT) and (filename<>NFILEMSG) then
  begin       {IF THE LEFT BUTTON HAS BEEN PRESSED AND A VALID FILENAME CHOSEN THEN READ THE FILE IN}
    Sound(1000);Delay(50);Nosound;
    curobj:=0;
    Assign(PICTUREFILE,curpath+filename);
    reset(PICTUREFILE);
    while not Eof(PICTUREFILE) do
    begin
      Read(PICTUREFILE,picobject[curobj]);
      Inc(curobj);                          {SETS CUROBJ TO THE NUMBER OF RECORDS READ IN + 1}
      if Ioresult<>0 then
      begin
        if Editgstring((MAXX div 2)-(Textwidth(FILERRMSG) div 2),MAXY div 2,0,MAXC,FILERRMSG,ul,FALSE) then;
        Setcolor(MAXC);
        Refresh(BAR);
        Exit;
      end;
    end;
    Close(PICTUREFILE);
    drawingchanged:=FALSE;
  end;
  Setcolor(MAXC);
  scale:=2;                                 {SETS ZOOM SCALE AND RECENTER OBJECTS}
  yoff:=EXOFF;
  yoff:=EYOFF;
  Refresh(BAR);
  ul:='';
end;
{$I+}

procedure Deletefile;
{
USES A CALL TO MS-DOS TO DELETE ANYFILE
}
begin
  Displaywind;
  Outtextxy(WINL+TEXTW,WINB-(TEXTH*2),DELMSG);
  Outtextxy(WINR-Textwidth(CMSG)-(TEXTW*2),WINB-(TEXTH*2),CMSG);
  Searchfiles;
  Showfiles;
  repeat if Filechosen then; until Mstatus<>0;
  if (regs.bx=LEFTBUT) and (filename<>NFILEMSG) then
  begin       {MAKE SURE THAT THE USER REALLY WANTS TO DELETE THE FILE, IF RETURN IS PRESSED THEN DELETE}
    Sound(800);Delay(40);Sound(200);Delay(50);Nosound;
    if Editgstring((MAXX div 2)-(Textwidth(DELCKMSG) div 2),MAXY div 2,0,MAXC,DELCKMSG,ul,FALSE) then
      Exec('A:\COMMAND.COM','/C DEL '+curpath+filename);
  end;
  Setcolor(MAXC);
  Refresh(BAR);
end;

procedure Gotodos;
{
CALLS COMMAND.COM AND ALLOWS USER TO EXECUTE MS-DOS COMMANDS
}
var
  scrbuf : pointer;
  scrsiz : word;
  mem : longint;
begin
  Mshow(FALSE);
  restorecrtmode;
  Writeln('Now entering MS-Dos.');
  Writeln('Type "exit" to return to Magigraf.');
  Exec('A:\COMMAND.COM','/B');      {CALL COMMAND.COM}
  Clrscr;                           {WHEN USER RETURNS BY TYPING EXIT THE PROGRAM IS RESUMED FROM HERE}
  Writeln('Welcome back, to Magigraph.');
  if DOSERROR <>0 then Writeln('A Dos-error has occured, code:=',DOSERROR);       {8 IS THE USUAL ERROR CODE, OUT OF MEMORY}
  Delay(2000);
  Setgraphmode(getgraphmode);       {BACK INTO GRAPHICS MODE}
  Mnewpointer(WANDXHOT,WANDYHOT,wand);
  Refresh(BAR);
  if not HERC then Mshow(TRUE);
end;

procedure Leaveprog;
{
CLOSES GRAPHICS, FREES MEMORY, AND EXITS PROGRAM
}
begin
  if drawingchanged then
  begin
    Sound(200);Delay(50);Sound(300);Delay(40);Sound(100);Delay(50);Nosound;
    if Editgstring((MAXX div 2)-(Textwidth(SAVEFILEMSG) div 2),MAXY div 2,MAXC,0,SAVEFILEMSG,ul,FALSE) then
      repeat until Save;
  end;
  Closegraph;
  if HERC then Freemem(curbuf,cursiz);
  Freemem(barbuf,barsiz);
  Writeln('You have been using MAGIGRAPH, (C) G.A.Godfrey 1988.');
  Halt;
end;

procedure Filemenu;
{
CONTROL FOR FILEMENU
}
begin
  case ono of
    0 : if Save then;
    1 : Load;
    2 : Deletefile;
    3 : Gotodos;
    4 : Leaveprog;
  end;
end;


end.

