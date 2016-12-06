unit Step;

{$mode objfpc}{$H+}
{'AND','ADD','LDA','STA','BUN','BSA','ISZ'

,'CLA','CLE','CMA','CME','CIR','CIL','INC','SPA','SNA','SZA','SZE','HLT',
    'INP','OUT','SKI','SKO','ION','IOF'}
interface
procedure runstep;
procedure showmem(mfrom,mcount: int16);
function do_interupt:boolean;
var
   cur: integer;
   steps: integer;
   etmp: uint32;

implementation
uses
  Classes, SysUtils, Unit1, MorrisAsm, Unit2;


procedure runstep;
var
   tmp: ansistring;
   tmpnum: int16;
begin
   if (cur >=origin) then
   begin
      exit;
   end;
   if (mem[cur].btype=null) then
   begin
      inc(cur);
      exit;
   end;
   if (mem[cur].btype=lb) or (mem[cur].btype=data) then
   begin
      inc(cur);
      exit;
   end;
   if (mem[cur].name='HLT') then
   begin
      Form1.Output.Lines.Add('>> Program halted !');
      cur:=origin;
      exit;
   end;
   if (mem[cur].name='END') then
   begin
      Form1.Output.Lines.Add('End of program !');
      cur:=origin;
      exit;
   end;
///////////////////////////////////////////////////////// AND
   if not (mem[cur].btype=command) then
   begin
      Form1.Output.Lines.Add('Unknown identifier ('+mem[cur].name+') @ '+dec2hex(cur,3));
   end;
      if (mem[cur].name='AND') then
      begin
         if (mem[cur].I=true) then
         begin
            AC:=AC and mem[mem[mem[cur].val].val].val;
            inc(cur);
            exit;
         end
         else
         begin
            AC:=AC and mem[mem[cur].val].val; ;
            inc(cur);
            exit;
         end;
      end;

///////////////////////////////////////////////////////// ADD
      if (mem[cur].name='ADD') then
      begin
         if (mem[cur].I=true) then
         begin
            etmp:=mem[mem[mem[cur].val].val].val;
            etmp:=etmp+AC;
            if (etmp>$FFFF) then
            E:=1;
            AC:=AC + mem[mem[mem[cur].val].val].val;
            inc(cur);
            exit;
         end
         else
         begin
            etmp:=mem[mem[cur].val].val;
            etmp:=etmp+AC;
            if (etmp>$FFFF) then
            E:=1;
            AC:=AC + mem[mem[cur].val].val;
            inc(cur);
            exit;
         end;
      end;
///////////////////////////////////////////////////////// LDA
      if (mem[cur].name='LDA') then
      begin
         if (mem[cur].I=true) then
         begin
            AC:=mem[mem[mem[cur].val].val].val;
            inc(cur);
            exit;
         end
         else
         begin
            AC:=mem[mem[cur].val].val;
            inc(cur);
            exit;
         end;
      end;
///////////////////////////////////////////////////////// STA
      if (mem[cur].name='STA') then
      begin
         if (mem[cur].I=true) then
         begin
            mem[mem[mem[cur].val].val].val:=AC;
            inc(cur);
            exit;
         end
         else
         begin
            mem[mem[cur].val].val:=AC;
            inc(cur);
            exit;
         end;
      end;
///////////////////////////////////////////////////////// BUN
      if (mem[cur].name='BUN') then
      begin
          if (lbls[mem[cur].lblindex].name='ISR') then
          begin
             Form1.Output.Lines.Add('BUN ISR Skipped !');
             inc(cur);
             exit;
          end;
          if (lbls[mem[cur].lblindex].name='ZRO') then
          begin
             if (mem[cur].I) then
             begin
                cur:=mem[0].val;
                Form1.Output.Lines.Add('Interupt ended !');
                exit;
             end;
             Form1.Output.Lines.Add('Warning : Use "BUN ZRO I" to exit ISR !');
          end;
          if (mem[cur].I=true) then
          begin
             cur:=mem[mem[cur].val].val;
             exit;
          end
          else
          begin
             cur:=mem[cur].val;
             exit;
          end;
       end;
///////////////////////////////////////////////////////// BSA
      if (mem[cur].name='BSA') then
      begin
         if (mem[cur].I=true) then
         begin
            mem[mem[mem[cur].val].val].btype:=data;
            mem[mem[mem[cur].val].val].val:=cur+1;
            cur:=mem[mem[cur].val].val;
            exit;
         end
         else
         begin
            mem[mem[cur].val].btype:=data;
            mem[mem[cur].val].val:=cur+1;
            cur:=mem[cur].val;
            exit;
         end;
      end;
///////////////////////////////////////////////////////// ISZ
      if (mem[cur].name='ISZ') then
      begin
         if (mem[cur].I=true) then
         begin
            inc(mem[mem[mem[cur].val].val].val);
            if ( mem[mem[mem[cur].val].val].val = 0 ) then
               inc(cur);
            inc(cur);
            exit;
         end
         else
         begin
            inc(mem[mem[cur].val].val);
            if ( mem[mem[cur].val].val = 0 ) then
               inc(cur);
            inc(cur);
            exit;
         end;
      end;
///////////////////////////////////////////////////////// INC
      if (mem[cur].name='INC') then
      begin
        etmp:=AC;
        inc(etmp);
        if (etmp>$FFFF) then
        E:=1;
        inc(AC);
        inc(cur);
        exit;
      end;
///////////////////////////////////////////////////////// CLA
      if (mem[cur].name='CLA') then
      begin
         AC:=0;
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// CLE
      if (mem[cur].name='CLE') then
      begin
         E:=0;
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// CMA
      if (mem[cur].name='CMA') then
      begin
         AC:=not AC;
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// CME
      if (mem[cur].name='CME') then
      begin
         E:=not E;
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// CIR (Rewritten for E)  **************
      if (mem[cur].name='CIR') then
      begin
         tmp:=shiftR(dec2bin(AC,16));
         tmpnum:=E;
         E:=strtoint(tmp[1]);
         if (tmpnum=1) then
            tmp[1]:='1'
         else
            tmp[1]:='0';
         AC:=bin2dec(tmp);
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// CIL (Rewritten for E)  **************
      if (mem[cur].name='CIL') then
      begin
         tmp:=shiftR(dec2bin(AC,16));
         tmpnum:=E;
         E:=strtoint(tmp[16]);
         if (tmpnum=1) then
            tmp[16]:='1'
         else
            tmp[16]:='0';
         AC:=bin2dec(tmp);
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// SZA
      if (mem[cur].name='SZA') then
      begin
         if (AC=0) then
            inc(cur);
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// SZE
      if (mem[cur].name='SZE') then
      begin
         if (E=0) then
            inc(cur);
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// SPA
      if (mem[cur].name='SPA') then
      begin
         if (AC>0) then
            inc(cur);
         inc(cur);
         exit;
      end;
///////////////////////////////////////////////////////// SNA
      if (mem[cur].name='SNA') then
      begin
         if (AC<0) then
            inc(cur);
         inc(cur);
         exit;
      end;
//////////////////////////////////////////////////////////////// I/O
///////////////////////////////////////// SKI
      if (mem[cur].name='SKI') then
      begin
         if (FGI=true) then
            inc(cur);
         inc(cur);
         exit;
      end;
///////////////////////////////////////// SKO
      if (mem[cur].name='SKO') then
      begin
         if (FGO) then
            inc(cur);
         inc(cur);
         exit;
      end;
///////////////////////////////////////// INP
      if (mem[cur].name='INP') then
      begin
         if (FGI) then
         begin
            if (isbinnum(Form1.textINPR.Text)) then
               AC:=bin2dec(Form1.textINPR.Text)
            else
               Form1.Output.Lines.Add('Warning : Input must be a binary number (only 0,1) !');
         end;
         inc(cur);
         exit;
      end;
//////////////////////////////////////// OUT
      if (mem[cur].name='OUT') then
      begin
         if (FGO) then
         begin
            Form1.lblOUTR.Caption:=Copy(dec2bin(AC,16),9,8);
         end;
         inc(cur);
         exit;
      end;
/////////////////////////////////////// ION
      if (mem[cur].name='ION') then
      begin
         IFlag:=true;
         Form1.lblISR.Caption:='1';
         inc(cur);
         exit;
      end;
/////////////////////////////////////// IOF
      if (mem[cur].name='IOF') then
      begin
         IFlag:=false;
         Form1.lblISR.Caption:='0';
         inc(cur);
         exit;
      end;
/////////////// developer check
       Form1.Output.Lines.Add('Command ('+mem[cur].name+') not implemented (YET) !');
       inc(cur);
       exit;
end;
////////////////////////////////////////////////////////////////////// Interupt
function do_interupt:boolean;
begin
    if ((mem[0].btype=lb)or(mem[0].btype=data)) and (lbls[0].name='ZRO') and (lbls[0].addr=0) then
    begin
       if (mem[1].btype=command) and (mem[1].name='BUN') and (lbls[mem[1].lblindex].name='ISR') then
       begin
          if (mem[1].I=true) then
          begin
               Form1.Output.Lines.Add('Warning : Branching to ISR is indirect!');
               exit(false);
          end
          else
          begin
               mem[0].val:=cur;
               cur:=mem[1].val-1;
               exit(true);
          end;
       end
       else
       begin
          Form1.Output.Lines.Add('Warning : Branching to ISR not found!');
          exit(false);
       end;
    end
    else
    begin
       Form1.Output.Lines.Add('Warning : ZRO label @ 0x000 not found!');
       exit(false);
    end;
end;
////////////////////////////////////////////////////////////// Fill Memory View
procedure showmem(mfrom,mcount: int16);
var
   i: integer;
   ln: ansistring;
begin
    Form2.mList.Items.Clear;
    for i:=mfrom to mfrom+mcount do
    begin
       ln:=dec2hex(i,3)+' : ';
       ///////////
       if (mem[i].btype=command) then
       begin
          if (isMRef(mem[i].name)) then
          begin
            if (mem[i].I) then
            begin
                 ln:=ln+dec2hex(mem[i].code+mem[i].val+$8000,4)+' '
                 +dec2bin(mem[i].code+mem[i].val+$8000,16)+' -- '+mem[i].name;
            end
            else
            begin
                 ln:=ln+dec2hex(mem[i].code+mem[i].val,4)+' '
                 +dec2bin(mem[i].code+mem[i].val,16)+' -- '+mem[i].name;
            end;

          end;
          if (isRRef(mem[i].name)) then
            ln:=ln+dec2hex(mem[i].code,4)+' '+dec2bin(mem[i].code,16)+' -- '+mem[i].name;
          Form2.mList.Items.Add(ln);
       end;
       //////////
       if (mem[i].btype=lb) or (mem[i].btype=data) then
       begin
          ln:=ln+dec2hex(mem[i].val,4)+' '+dec2bin(mem[i].val,16)+' -- '+mem[i].name;
          Form2.mList.Items.Add(ln);
       end;
       if (mem[i].btype=null) then
       begin
          ln:=ln+dec2hex(0,4)+' '+dec2bin(0,16)+' -- '+mem[i].name;
          Form2.mList.Items.Add(ln);
       end;
    end;
end;

end.

