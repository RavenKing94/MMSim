////////////////////////////////////////////////////////////// ASM Conditions
{-------------------- ORG -------------------}
if (tk[ctline,0]='ORG') then
begin
   if (ishexnum(tk[ctline,1])) then
   begin
      origin:=hex2dec(tk[ctline,1]);
      if (origin>4095) then
      begin
         error('Maximum memory address is 0xFFF or 4095 !!!',ctline);
         exit;
      end;
      if (not gotorigin) then
      forg:=origin;
      gotorigin:=true;
      inc(ctline);
      continue;
   end
   else
   begin
      error('Expected hex number !',ctline);
      exit;
   end;
end;
if (origin>=4095) then
begin
   error('Reached end of memory - Assembly failed !',ctline);
   exit;
end;
{============== Memory Refrence =============}
if (isMRef(tk[ctline,0])) then       //1
begin
   if (MRef(0)) then
       continue
   else
       exit;
end;

{============= Reg Refrence & IO ============}
if (isRRef(tk[ctline,0])) then       //1
begin
   if (RRef(0)) then
       continue
   else
       exit;
end;

{==================== LBL ===================}//BEGIN Labels
if (islabel(tk[ctline,0])) then
begin
    lbls[lblindex(tk[ctline,0])].addr:=origin;
    mem[origin].btype:=lb;
    mem[origin].name:=tk[ctline,0];
    mem[origin].linenum:=ctline;

    if (tc[ctline]=2) then
    begin
        inc(origin);
        inc(ctline);
        continue;
    end;
    mem[origin].btype:=data;
    if (isnum(tk[ctline,2])) then
    begin
       mem[origin].val:=hex2dec(tk[ctline,2]);
       inc(origin);
       inc(ctline);
       continue;
    end;
    //////////////////    ////////////////
    if (tk[ctline,2]='HEX') then
    begin
        if (tc[ctline]<=3) then
        begin
             error('Missing hex number after HEX keyword',ctline);
             exit;
        end;
        if (ishexnum(tk[ctline,3])) then
        begin
             mem[origin].val:=hex2dec(tk[ctline,3]);
             if (tc[ctline]>4) then
             begin
                  error('Unknown identifier after hex number (U dont need it!!!)',ctline);
                  exit;
             end;
             inc(origin);
             inc(ctline);
             continue;
        end
        else
        begin
             error('Wrong syntax - Expected hex number',ctline);
             exit;
        end;
    end;
    //////////////////    ////////////////
    if (tk[ctline,2]='DEC') then
    begin
        if (tc[ctline]<=3) then
        begin
             error('Missing decimal number after DEC keyword',ctline);
             exit;
        end;
        if (isnum(tk[ctline,3])) then
        begin
           mem[origin].val:=int16(strtoint(tk[ctline,3]));
           if (tc[ctline]>4) then
           begin
                error('Unknown identifier after decimal number (U dont need it!!!)',ctline);
                exit;
           end;
           inc(origin);
           inc(ctline);
           continue;
        end
        else
        begin
           error('Wrong syntax - Expected decimal number',ctline);
           exit;
        end;
    end;
    //////////////////    //////////////
    if (tk[ctline,2]='BIN') then
    begin
        if (tc[ctline]>3) then
        begin
           error('Missing binary number after BIN keyword',ctline);
           exit;
        end;
        if (isnum(tk[ctline,3])) then
        begin
             mem[origin].val:=bin2dec(tk[ctline,3]);
             if (tc[ctline]>4) then
             begin
                  error('Unknown identifier after binary number (U dont need it!!!)',ctline);
                  exit;
             end;
             inc(origin);
             inc(ctline);
             continue;
        end
        else
        begin
             error('Wrong syntax - Expected binary number',ctline);
             exit;
        end;
    end;
    //////////////////    /////////////////
    if (tk[ctline,2]='LBL') then
    begin
        if (tc[ctline]<=3) then
        begin
           error('Missing label name after LBL keyword',ctline);
           exit;
        end;
        if (islabel(tk[ctline,3])) then
        begin
           mem[origin].I:=true;  //So lbladdrfetch knows what to do
           mem[origin].linenum:=ctline;
           mem[origin].name:=tk[ctline,0];
           mem[origin].lblindex:=lblindex(tk[ctline,3]);
           inc(origin);
           inc(ctline);
           continue;
        end
        else
        begin
           error('Expected label name after LBL keyword',ctline);
           exit;
        end;
    end;
    ////////////////////////////////////////
    if (iscmd(tk[ctline,2])) then
    begin
         if (isMRef(tk[ctline,2])) then
         begin
            if (MRef(2)) then
               continue
            else
                exit;
         end;
         if (isRRef(tk[ctline,2])) then
         begin
            if (RRef(2)) then
               continue
            else
                exit;

         end;
    end;
    inc(origin);
    inc(ctline);
    continue;
end;
/////////////////////////////////////////////END Labels
////////////////////////////////////////////////////// Hex DATA
if (tk[ctline,0]='HEX') then
begin
     if (tc[ctline]<2) then
     begin
          error('Incomplete syntax - Expected hex number',ctline);
          exit;
     end;
     if (ishexnum(tk[ctline,1])) then
     begin
          mem[origin].btype:=data;
          mem[origin].linenum:=ctline;
          mem[origin].val:=hex2dec(tk[ctline,1]);
     end
     else
     begin
          error('Expected hex number after HEX keyword',ctline);
          exit;
     end;
     if (tc[ctline]>2) then
     begin
          error('Unknown identifier after hex number (U dont need it!!!)',ctline);
          exit;
     end;
     inc(origin);
     inc(ctline);
     continue;
end;
/////////////////////////////////////////////////////// Decimal DATA
if (tk[ctline,0]='DEC') then
begin
     if (tc[ctline]<2) then
     begin
          error('Incomplete syntax - Expected decimal number',ctline);
          exit;
     end;
     if (isnum(tk[ctline,1])) then
     begin
          mem[origin].btype:=data;
          mem[origin].linenum:=ctline;
          mem[origin].val:=int16(strtoint(tk[ctline,1]));
     end
     else
     begin
          error('Expected decimal number after DEC keyword',ctline);
          exit;
     end;
     if (tc[ctline]>2) then
     begin
          error('Unknown identifier after decimal number (U dont need it!!!)',ctline);
          exit;
     end;
     inc(origin);
     inc(ctline);
     continue;
end;
/////////////////////////////////////////////////////// Binary DATA
if (tk[ctline,0]='BIN') then
begin
     if (tc[ctline]<2) then
     begin
          error('Incomplete syntax - Expected bin number',ctline);
          exit;
     end;
     if (isnum(tk[ctline,1])) then
     begin
          mem[origin].btype:=data;
          mem[origin].linenum:=ctline;
          mem[origin].val:=bin2dec(tk[ctline,1]);
     end
     else
     begin
          error('Expected bin number after BIN keyword',ctline);
          exit;
     end;
     if (tc[ctline]>2) then
     begin
          error('Unknown identifier after bin number (U dont need it!!!)',ctline);
          exit;
     end;
     inc(origin);
     inc(ctline);
     continue;
end;
/////////////////assign lbl to mem
/////////////////////////////////////////////////////////End of ASM Conditions

