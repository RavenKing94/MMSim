unit MorrisASM;

{$mode objfpc}{$H+}

interface
procedure Tokenize(s:ansistring);
procedure error(s: ansistring; ln: integer);
function isnum(s: ansistring):boolean;
function isbinnum(s: ansistring):boolean;
procedure ALM;
function listlabels:boolean;
procedure resetASM;
function hex2dec(s: ansistring): int16;
function bin2dec(s: ansistring): int16;
function dec2hex(x,c: uint16): ansistring;
function dec2bin(x,c: uint16): ansistring;
function isMRef(s: ansistring): boolean;
function isRRef(s: ansistring): boolean;
function shiftL(x: ansistring): ansistring;
function shiftR(x: ansistring): ansistring;
///////////////////////////////////////////////////////////////////////////
type
  blocktype=(null,lcommand,command,data,lb);
  MemoryBlock=Record
    btype   : blocktype;  //Block Type
    linenum : integer;    //Line number for showing in editor
    code : int16;       //Command Code
    name : ansistring;    //Command Name
    lblindex: integer;    //Label Index
    I       : boolean;    //Indirect
    val     : int16;      //Value , Address
  end;

  lbl=record
    name : ansistring;
    addr : int16;
  end;

var
  origin: int16;
  fmem: int16;
  AC: int16;
  AR: int16;
  E: byte;
  FGI: boolean; // flag input
  FGO: boolean; // flag output
  IFlag: boolean; // interupt flag
  LBLCount: integer;
  mem: array[0..4095] of MemoryBlock;
  lbls: array[0..4095] of lbl;
  tk: array[0..4000] of array[0..20] of ansistring; //Tokens' placeholder
  tc: array[0..4000] of integer; //Token count in each line
  lastline: integer; //Last Line in Action
  ctline: integer;
  gotorigin: boolean;
  forg: int16;
  haserror: boolean;
  const commands: array[0..24] of ansistring=(
    'AND','ADD','LDA','STA','BUN','BSA','ISZ'

    ,'CLA','CLE','CMA','CME','CIR','CIL','INC','SPA','SNA','SZA','SZE','HLT',
    'INP','OUT','SKI','SKO','ION','IOF'
  );
  const ccodes: array[0..24] of integer=(
    0,4096,8192,12288,16384,20480,24576,{MRI}
    30720,29696,29184,28928,28800,28736,28704,28688,28680,28676,28674,28673{7001}
    ,63488,62464,61952,61696,61568,61504
  );
implementation
uses
  Classes, SysUtils,unit1;
procedure error(s: ansistring; ln: integer);
begin
     haserror:=true;
     Form1.Output.Lines.Add('Line ('+IntToStr(ln+1)+') : '+s);
end;
procedure error(s: ansistring);
begin
     haserror:=true;
     Form1.Output.Lines.Add('Fatal - '+s);
end;
procedure Tokenize(s: ansistring);
var
  inword: boolean=false; //Getting a Word (AB, 034, A_1, -100, ...)
  i: integer;
begin
     tc[lastline]:=0;
     i:=1;
     s:=upcase(s);
     while (true) do
     begin
          if (i>length(s)) then break;
          if (s[i] in [' ',#0,#9]) then       //Skip whitespace
          begin
            inword:=false;
            inc(i);
            continue;
          end;
          if (s[i] in [':',',']) then     //Signs
          begin
            inc(tc[lastline]);
            tk[lastline,tc[lastline]-1]:=s[i];
            inword:=false;
            inc(i);
            continue;
          end;
          if (s[i]='/') then        //Comments
            if (s[i+1]='/') then
            begin
              inword:=false;
              break;
            end
            else
            begin
              error('Unknown identifier ( / ) .' , lastline );
              inc(i);
              inword:=false;
              continue;
            end;
          if (s[i] in ['A'..'Z']+['0'..'9']+['_','-','+']) then   //Get a Word containing A..Z,0..9,_
          begin
            if (not inword) then
            begin
              inword:=true;
              inc(tc[lastline]);
            end;
              tk[lastline,tc[lastline]-1]:=tk[lastline,tc[lastline]-1]+s[i];
              inc(i);
              continue;
          end;
          error('Unknown Identifier ( '+s[i]+' ) .',lastline);
          inc(i);

     end;
end;

function isnum(s: ansistring):boolean;
var
  i: integer;
begin
     i:=1;
     if (length(s)=0) then exit(false);
     if (s[1] in ['-','+']) then
        inc(i);
     for i:=i to length(s) do
         if not(s[i] in ['0'..'9']) then
            exit(false);
     exit(true);

end;
function ishexnum(s: ansistring):boolean;
var
  i: integer;
begin
     i:=1;
     if (s[1] in ['-','+']) then
        inc(i);
     for i:=i to length(s) do
         if not(s[i] in ['0'..'9']+['A'..'F']) then
            exit(false);
     exit(true);

end;

function isbinnum(s: ansistring):boolean;
var
  i: integer;
begin
     i:=1;
     if (s[1] in ['-','+']) then
        inc(i);
     for i:=i to length(s) do
         if not(s[i] in ['0','1']) then
            exit(false);
     exit(true);

end;

function issep(s: ansistring):boolean;
begin
     if (s=',') or (s=':') then
       exit(true)
     else exit(false);
end;

function isvalidname(s: ansistring):boolean;
var
  i: integer;
begin
     s:=upcase(s);
     if (length(s)<1) then exit(false);
     if (s[1]='_') then exit(false);
     if (s[1] in ['0'..'9']) then exit(false);
     for i:=1 to length(s) do
         if not (s[i] in ['0'..'9']+['A'..'Z']+['_']) then
            exit(false);
     exit(true);
end;
////////////////////////////////////////////
{----------------Convertions---------------}
function ipower(b,e:int16):int16;inline;
var i: integer;
begin
     ipower:=1;
     for i:=0 to e do
         ipower:=ipower*b;
end;

function hex2dec(s: ansistring):int16;
var
  i,r,p,sgn: int16;
begin
     r:=0;
     sgn:=0;
     if (s[1]='-') then
        sgn:=-1;
     if (s[1]='+') then
        sgn:=1;
     for i:=1+abs(sgn) to length(s) do
     begin
          p:=ipower(16,length(s)-i+abs(sgn)-1);

          if (s[i] in ['0'..'9']) then  r:=r+p*StrToInt(s[i]);
          if (s[i]='A') then r:=r+p*10;
          if (s[i]='B') then r:=r+p*11;
          if (s[i]='C') then r:=r+p*12;
          if (s[i]='D') then r:=r+p*13;
          if (s[i]='E') then r:=r+p*14;
          if (s[i]='F') then r:=r+p*15;
     end;
     if (sgn>=0) then
        exit(r)
     else
        exit(-r);
end;

function bin2dec(s: ansistring):int16;inline;  // Binary string to decimal number
var
  i,p,r,sgn: int16;
begin
     r:=0;
     sgn:=0;
     if (s[1]='-') then
        sgn:=-1;
     if (s[1]='+') then
        sgn:=1;
     for i:=length(s) downto 1+abs(sgn) do
     begin
          p:=ipower(2,length(s)-i-abs(sgn)-1);
          r:=r+p*StrToInt(s[i]);
     end;
     if (sgn>=0) then
        exit(r)
     else
        exit(-r);
end;

function dec2hex(x,c: uint16): ansistring;
var
  i,j: uint16;
  r,r2: ansistring;
begin
   r:='';
   r2:='';
   for j:=1 to 4 do
   begin
        i:=x mod 16;
        x:=x div 16;
        if (i in [0..9]) then  r:=InttoStr(i)+r;
        if (i=10) then r:='A'+r;
        if (i=11) then r:='B'+r;
        if (i=12) then r:='C'+r;
        if (i=13) then r:='D'+r;
        if (i=14) then r:='E'+r;
        if (i=15) then r:='F'+r;
   end;
   for j:=5-c to 4 do
   begin
      r2:=r2+r[j];
   end;
exit(r2);
end;

function dec2bin(x,c: uint16): ansistring;
var
  i,j: uint16;
  r,r2: ansistring;
begin
r2:='';
r:='';
   for j:=1 to 16 do
   begin
        i:=x mod 2;
        x:=x div 2;
        r:=InttoStr(i)+r;
   end;
   for j:=17-c to 16 do
   begin
      r2:=r2+r[j];
   end;
exit(r2);
end;

function shiftL(x: ansistring): ansistring;
var
  i: integer;
  t: ansistring;
begin
     t:='';
     for i:=2 to length(x) do
     begin
        t:=t+x[i];
     end;
     t:=t+x[1];
     exit(t);
end;

function shiftR(x: ansistring): ansistring;
var
  i: integer;
  t: ansistring;
begin
     t:=x[16];
     for i:=1 to length(x)-1 do
     begin
        t:=t+x[i];
     end;
     exit(t);
end;
////////////////////////////////////////////
{-----------------Assembler----------------}
function iscmd(s: ansistring):boolean;
var
  i:integer;
begin
     s:=upcase(s);
     for i:=0 to 24 do
         if (s=commands[i]) then
         exit(true);
     exit(false);
end;
function getcmdcode(s: ansistring):integer;
var
  i:integer;
begin
     s:=upcase(s);
     for i:=0 to 24 do
         if (s=commands[i]) then
         exit(ccodes[i]);
end;
function islabel(s: ansistring):boolean;
var
  i: integer;
begin
    for i:=0 to LBLCount do
        if (s=lbls[i].name) then
           exit(true);
    exit(false);
end;
function lblindex(s: ansistring):integer;
var
  i: integer;
begin
    for i:=0 to LBLCount do
        if (s=lbls[i].name) then
           exit(i);
    exit(-1);
end;
function listlabels:boolean; //List labels and also check for some errors
var
  i: integer;
begin
    LBLCount:=0;
    for i:=0 to lastline do
    begin
        if (tc[i]=0) then continue;
        if (isvalidname(tk[i,0])) then
        begin
            if (iscmd(tk[i,0])) then continue;
            if (tk[i,0]='HEX') or (tk[i,0]='BIN') or (tk[i,0]='DEC') then continue;
            if (tk[i,0]='ORG') then continue;
            if (tk[i,0]='END') then exit(true);
            if (islabel(tk[i,0])) then
            begin
               error('Dupplicate label name !',i);
               exit(false);
            end;
            if (issep(tk[i,1])) then
            begin
                 lbls[LBLCount].name:=tk[i,0];
                 inc(LBLCount);
            end
            else
            begin
               if (tk[i,0]='HEX') or (tk[i,0]='BIN') or (tk[i,0]='DEC') then
               begin
                 continue;
               end
               else
               begin
                 error('Expected (,) or (:) after label name',i);
                 exit(false);
               end;
            end;
        end
        else
        begin
             error('Unknown Identifier ('+tk[i,0]+')',i);
             exit(false);
        end;
    end;
end;
/////////////////////////////////////////
function isMRef(s: ansistring): boolean;
var
  i: integer;
begin
    for i:=0 to 6 do
    begin
         if (commands[i]=s) then
           exit(true);
    end;
    exit(false);
end;
function isRRef(s: ansistring): boolean;
var
  i: integer;
begin
    for i:=7 to 24 do
    begin
         if (commands[i]=s) then
           exit(true);
    end;
    exit(false);
end;

function MRef(i: integer):boolean;
begin
    if (tc[ctline]<i+2) then
    begin
      error('Expected label name',ctline);
      exit(false);
    end;
     if (islabel(tk[ctline,i+1])) then //2
     begin
        mem[origin].btype:=command;
        mem[origin].name:=tk[ctline,i+0];
        mem[origin].code:=getcmdcode(tk[ctline,i+0]);
        mem[origin].linenum:=ctline;
        // For the label address to be found & set later
        mem[origin].lblindex:=lblindex(tk[ctline,i+1]);

        if (tc[ctline]>i+2) then         //2.5 Check possibility of I's existense ?!
          if (tk[ctline,i+2]='I') then   //3 Is it (I) there or is it error?
          begin
             mem[origin].I:=true;
             inc(ctline);
             inc(origin);
             exit(true);
          end
          else
          begin
             error('Expected (I) , Found Nonsense :-)',ctline);
             exit(false);
          end;
        inc(ctline);
        inc(origin);
        exit(true);
     end
     else
     begin
        error('Invalid label name ('+tk[ctline,i+1]+')',ctline);
        exit(false);
     end;
end;
function RRef(i: integer):boolean;
begin
    mem[origin].btype:=command;
    mem[origin].name:=tk[ctline,i+0];
    mem[origin].code:=getcmdcode(tk[ctline,i+0]);
    mem[origin].linenum:=ctline;
    mem[origin].lblindex:=-1;
    if (tc[ctline]>i+1) then
    begin
       error('Unknown identifier ('+tk[ctline,i+1]+')',ctline);
       exit(false);
    end;
    inc(origin);
    inc(ctline);
    exit(true);
end;
///////////////////////////////////////
procedure lbladdrfetch;
var i:integer;
begin
  for i:=0 to origin-1 do
  begin
     if (isMRef(mem[i].name)) then
     begin
          mem[i].val:=lbls[mem[i].lblindex].addr;
     end
     else
     if ((mem[i].btype=lb) or (mem[i].btype=data))and(mem[i].I) then
     begin
          mem[i].btype:=data;
          mem[i].val:=lbls[mem[i].lblindex].addr;
     end;
  end;
end;
/////////////////////////////////////////
//Included assembly procedures in a separate file//

procedure ALM; //Assemble & Load in memory
begin
     assembled:=false;
     if (haserror) then
     begin
        error('>> Errors exist - Assembly failed !');
        exit;
     end;
     ctline:=0;
     origin:=0;
     {------------------ Find Labels ----------------------}
     if (not listlabels) then
        exit;
     {------------------ Look for ISR ---------------------}
     //Moved to step
     {----------------- Look for 1st ORG ------------------}
     //Moved to step
     {==================== Main Part ======================}
     while (ctline<=lastline) do
     begin
          if (tc[ctline]=0) then
          begin
               inc(ctline);
               continue;
          end;
          if (tk[ctline,0]='END') then
          begin
             Form1.Output.Lines.Add('>> Successfuly assembled !');
             lbladdrfetch;
             assembled:=true;
             exit;
          end;
          //Included assembly conditions in a separate file//
          {$I asm.pas}

     end;
     //Form1.Output.Lines.Add('>> Successfuly assembled !');
     error('Program has no END !');
     exit;
end;
/////////////////////////////////////
procedure resetASM;
var i,j: integer;
begin
    origin:=0;
    AC:=0;
    AR:=0;
    E:=0;
    LBLCount:=0;
    for i:=0 to 4095 do
    begin
        mem[i].btype:=null;
        mem[i].name:='';
        mem[i].code:=0;
        mem[i].I:=false;
        mem[i].lblindex:=-1;
        mem[i].linenum:=0;
        mem[i].val:=0;
    end;
    for i:=0 to 4095 do
    begin
        lbls[i].name:='';
        lbls[i].addr:=0;
    end;
    for i:=0 to 4095 do
    begin
        tc[i]:=0;
    end;
    for i:=0 to 4095 do
    begin
        for j:=0 to 20 do
        setlength(tk[i,j],0);
    end;
    origin:=0;
    forg:=0;
    gotorigin:=false;
    lastline:=0;
    ctline:=0;
    haserror:=false;
end;

end.

