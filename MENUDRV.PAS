Unit Menudrv;

Interface

Uses
  Dos,Crt,Graph,Majkvars,Mousedrv;

function Getmenu : shortint;

Implementation
var
  optbuf   : pointer;        {VARS FOR GET & PUTIMAGE}
  optsize  : word;
  finalopt : shortint;       {FINAL OPTION ON CURRENT MENU}

procedure Showmenu(nofmenu,lastopt : shortint);
{
DRAWS MENU ON SCREEN ALTERING LENGTH OF THE MENU DEPENDING ON lastopt
 PARAMS : nofmenu = NUMBER OF MENU
          lastopt = LAST OPTION NUMBER
 LOCALS : curopt = COUNTER FOR CURRENT OPTION
}
var
  curopt : shortint;
begin
  Mshow(FALSE);
  with menuname[nofmenu] do
  begin
    menutitlesiz :=Imagesize(start,0,finish,BARBOT);
    Getmem(menutitlebuf,menutitlesiz);
    Getimage(start,0,finish,BARBOT,menutitlebuf^);
    Putimage(start,0,menutitlebuf^,NOTPUT);
  end;                                                     {INVERTS MENU TITLE}
  restsiz :=Imagesize(windl-1,windt-1,windr+1,windb+1);
  Getmem(restbuf,restsiz);
  Getimage(windl-1,windt-1,windr+1,windb+1,restbuf^);
  Putimage(windl-1,windt-1,restbuf^,XORPUT);               {STORE AND CLEAR AREA UNBDER MENU BOX}
  Rectangle(windl,windt,windr,windb);
  Rectangle(windl+1,windt+1,windr-1,windb-1);
  for curopt :=0 to lastopt do
  begin
    optul[curopt].x :=1+menuname[nofmenu].start;
    optul[curopt].y :=BARBOT+8+(curopt*TEXTH)-1;
    optbr[curopt].x :=windr-3;
    optbr[curopt].y :=TEXTH+optul[curopt].y;
    Outtextxy(optul[curopt].x+1,optul[curopt].y+1,options[nofmenu,curopt]);
  end;                                                   {CALCULATE COORDS OF EACH INDIVIDUAL OPTION AND PRINT THEM}
  optsize :=Imagesize(optul[1].x,optul[1].y,optbr[1].x,optbr[1].y);   {IMAGE SIZE IS CONSTANT FOR ALL OPTIONS}
  Mshow(TRUE);
end;

procedure Killmenu(nofmenu :shortint);
{
REMOVES MENU AND REPLACES PREVIOUS CONTENTS OF THE SCREEN
 PARAMS : nofmenu = THE NUMBER OF THE MENU TO REMOVE
}
begin
  Mshow(FALSE);
  Putimage(windl-1,windt-1,restbuf^,NORMALPUT);
  Putimage(menuname[nofmenu].start,0,menutitlebuf^,NORMALPUT);
  Freemem(restbuf,restsiz);
  Freemem(menutitlebuf,menutitlesiz);
  Mshow(TRUE);
end;

function Menuchoice : shortint;
{
ASCERTAINS WHICH MENU HAS BEEN CHOSEN
 LOCALS : curmen = COUNTER FOR CURRENT MENU
 RETURNS : MENU NUMBER THAT WAS CHOSEN
}
var
  curmen : shortint;
begin
  mno:=-1;                         {SET MENU CHOSEN TO 'FALSE'}
  if regs.dx < TEXTH then          {IF THE MOUSE IS OVER THE BAR THEN..}
  for curmen :=0 to NOFMENUS do    {SCAN MENU POSITIONS TO SEE WHICH MENU THE MOUSE IS OVER}
    with menuname[curmen] do
      if ((regs.cx >start) and (regs.cx <finish)) then mno :=curmen;
  Menuchoice :=mno;
end;

procedure Moveopt(ooptn,noptn : integer);
{
HIGHLIGHTS MENU OPTIONS
 PARAMS : ooptn,noptn = OLD AND NEW OPTION NUMBERS
}
begin
  Mshow(FALSE);
  Getmem(optbuf,optsize);
  if ooptn <>-1 then          {IF MOUSE WAS ON THE MENU}
  begin
    Getimage(optul[ooptn].x,optul[ooptn].y,optbr[ooptn].x,optbr[ooptn].y,optbuf^);
    Putimage(optul[ooptn].x,optul[ooptn].y,optbuf^,NOTPUT);
  end;
  if noptn <>-1 then          {IF MOUSE IS ON THE MENU}
  begin
    Getimage(optul[noptn].x,optul[noptn].y,optbr[noptn].x,optbr[noptn].y,optbuf^);
    Putimage(optul[noptn].x,optul[noptn].y,optbuf^,NOTPUT);
  end;
  Freemem(optbuf,optsize);
  Mshow(TRUE);
end;

function Nofoption(nofmenu : shortint) : shortint;
{
ASCERTAINS WHICH MENU OPTION MOUSE BUTTON IS RELEASED OVER
 PARAMS : nofmenu = NUMBER OF MENU TO CHECK
 LOCALS : oldopt,newopt = KEEPS TRACK OF POSITIONS ON OPTIONS
          obuf,osiz = VARIABLES FOR GET AND PUTIMAGE
 RETURNS : newopt = THE OPTION THE RIGHT BUTTON WAS RELEASED OVER
}
var
  oldopt, newopt, curopt, unused : integer;
  obuf : pointer;
  osiz : word;
begin
  oldopt :=-1;         {SET TO 'FALSE'}
  newopt :=-1;
  curopt :=0;
  Mdomain(windl,0,windr,windb-4);      {LIMIT MOUSE TO MENU WINDOW}
  repeat
    unused :=Mstatus;
    if regs.dx <TEXTH then newopt :=-1;
    if ((regs.dx >=optul[curopt].y) and (regs.dx <optbr[curopt].y)) then
      newopt :=curopt;
    if oldopt <> newopt then Moveopt(oldopt,newopt);
    oldopt :=newopt;
    inc(curopt);
    if curopt >finalopt then curopt :=0;
  until Mbutrel<>RIGHTBUT;                           {SCAN MENU UNTIL RIGHT BUTTON IS RELEASED}
  if ((newopt <>-1) and (Mstatus<>BOTHBUT)) then     {IF IT HAS BEEN RELEASED ON A VALID OPTION THEN}
  begin
    Mshow(FALSE);
    osiz :=Imagesize(optul[newopt].x,optul[newopt].y,optbr[newopt].x,optbr[newopt].y);
    Getmem(obuf,osiz);                               {GET AN IMAGE OF THE OPTION}
    Getimage(optul[newopt].x,optul[newopt].y,optbr[newopt].x,optbr[newopt].y,obuf^);
    for curopt:=0 to 6 do                            {AND MAKE IT BLINK SIX TIMES}
    begin
      Putimage(optul[newopt].x,optul[newopt].y,obuf^,XORPUT);
      Delay(50);
    end;
    Mshow(TRUE);
    Freemem(obuf,osiz);
  end
    else newopt:=-1;                                 {OTHERWISE NO OPTION HAS BEEN CHOSEN}
  Mdomain(0,0,MAXX,MAXY);
  Nofoption :=newopt;
end;

function Optionchoice(nofmenu : shortint) : shortint;
{
CALCULATE WINDOW COORDS, LAST OPTION IN MENU, CONTROL COURSE OF EVENTS IN SEARCH FOR OPTION
 PARAMS : nofmenu = NUMBER OF MENU TO BE USED
 RETURNS : ono = THE OPTION CHOSEN
}
var
  curopt : shortint;
begin
  if ((nofmenu<0) or (nofmenu>NOFMENUS)) then Exit;
  windl :=menuname[nofmenu].start-2;
  windt :=BARBOT+4;
  windr :=windl +((OPTSTLEN+1)*TEXTW);
  for curopt :=0 to NOFOPTS do
    if options[nofmenu,curopt]<>'' then
    begin
      finalopt :=curopt;
      windb :=windt+6+((curopt+1)*(TEXTH));
    end;
  Showmenu(nofmenu,finalopt);
  ono :=Nofoption(nofmenu);
  Killmenu(nofmenu);
  Optionchoice :=ono;
end;

function Getmenu : shortint;
{
CONTROL PROCEDURE FOR MENUDRV
}
begin
  while Mstatus = RIGHTBUT do
  begin
    mno :=Menuchoice;
    ono :=Optionchoice(mno);
  end;
  Getmenu :=mno;
end;


end.

