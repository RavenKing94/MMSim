unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterAny, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, Menus, morrisASM, Unit2;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    btnISR: TButton;
    btnOpen: TButton;
    Button6: TButton;
    btnSave: TButton;
    chkHL: TCheckBox;
    chkFGI: TCheckBox;
    chkFGO: TCheckBox;
    Label11: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    lblE: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    miCopy: TMenuItem;
    miPaste: TMenuItem;
    miSelAll: TMenuItem;
    miCut: TMenuItem;
    odg: TOpenDialog;
    pmSyn: TPopupMenu;
    rundelay: TEdit;
    sdg: TSaveDialog;
    textINPR: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    lblOUTR: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    lblISR: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblAC: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    label6: TLabel;
    Timer1: TTimer;
    vList: TMemo;
    Output: TMemo;
    BasicAsmSyn: TSynAnySyn;
    SynEdit1: TSynEdit;
    procedure btnISRClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure chkHLChange(Sender: TObject);
    procedure chkFGIChange(Sender: TObject);
    procedure chkFGOChange(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure miCopyClick(Sender: TObject);
    procedure miCutClick(Sender: TObject);
    procedure miPasteClick(Sender: TObject);
    procedure miSelAllClick(Sender: TObject);
    procedure SynEdit1Change(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  assembled: boolean=false;

implementation
uses step;
{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  i: integer;
begin
   resetASM;
   Output.Lines.Clear;
   for lastline:=0 to SynEdit1.Lines.Count-1 do
       tokenize(SynEdit1.Lines[lastline]);
   ALM;
   lblISR.Caption:='1';
   Label2.Caption:='0';
   steps:=0;
   cur:=forg;
   Form2.Edit1.Caption:=dec2hex(forg,3);
   vList.Lines.Clear;
   for i:=0 to LBLCount-1 do
       vList.Lines.Add(lbls[i].name+' @ '+dec2hex(lbls[i].addr,3)+' : '+inttostr(mem[lbls[i].addr].val));
   lblAC.Caption:=dec2bin(AC,16);
   if ((cur-hex2dec(Form2.Edit1.Caption))>(Form2.mList.Items.Count-1)) then
   Form2.mList.Selected[Form2.mList.Items.Count-1]:=true;
   if ((cur-hex2dec(Form2.Edit1.Caption))<0) then
   Form2.mList.Selected[0]:=true;
   showmem(hex2dec(Form2.Edit1.Caption),strtoint(Form2.Edit2.Caption));
   Form2.mList.Selected[cur-hex2dec(Form2.Edit1.Caption)]:=true;
   Button2.Enabled:=true;
   Button3.Enabled:=true;
end;

procedure TForm1.btnISRClick(Sender: TObject);
begin
  if (not assembled) then
  begin
     Output.Lines.Add('Program is not assembled !');
     exit;
  end;
  if (IFlag=false) then
  begin
     Output.Lines.Add('System Interupts are OFF !');
     exit;
  end;
  if (do_interupt) then
  begin
     Output.Lines.Add('System Interupted !');
  end
  else
  begin
     Output.Lines.Add('Interupt failed - Continued ..');
  end;
end;

procedure TForm1.btnOpenClick(Sender: TObject);
begin
  odg.FileName:='';
  odg.Execute;
  if (length(odg.FileName)>0) then
  begin
       SynEdit1.Lines.LoadFromFile(odg.FileName);
  end;
end;

procedure TForm1.btnSaveClick(Sender: TObject);
var
  sv:integer;
begin
  sdg.FileName:='';
  sdg.Execute;
  if (length(sdg.FileName)>0) then
  begin
       if (FileExistsUTF8(sdg.FileName)) then
       begin
            sv:=MessageDlg('Overwrite ?','File already exists do you want to overwrite it?',mtConfirmation,[mbYes,mbNo],0);
            if (sv=mrYes) then
            begin
                 SynEdit1.Lines.SaveToFile(sdg.FileName);
            end
            else
                 exit;
       end;
       SynEdit1.Lines.SaveToFile(sdg.FileName);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if (not assembled) then
  begin
     Output.Lines.Add('Program is not assembled !');
     exit;
  end;
  Timer1Timer(Button2);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if (not assembled) then
  begin
     Output.Lines.Add('Program is not assembled !');
     exit;
  end;
  Button2.Enabled:=false;
  Button6.Enabled:=true;
  Timer1.Interval:=strtoint(rundelay.Text);
  Timer1.Enabled:=true;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Form2.Show;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Timer1.Enabled:=false;
  Button2.Enabled:=true;
  Button6.Enabled:=false;
  Output.Lines.Add('Execution Paused !');
end;

procedure TForm1.chkHLChange(Sender: TObject);
begin
   if (chkHL.Checked) then
      SynEdit1.Highlighter:=BasicAsmSyn
   else
      SynEdit1.Highlighter:=NIL;
end;

procedure TForm1.chkFGIChange(Sender: TObject);
begin
  if (chkFGI.Checked) then
  begin
     chkFGI.Caption:=' = 1';
     FGI:=chkFGI.Checked;
  end
  else
  begin
     chkFGI.Caption:=' = 0';
     FGI:=chkFGI.Checked;
  end;
end;

procedure TForm1.chkFGOChange(Sender: TObject);
begin
  if (chkFGO.Checked) then
  begin
     chkFGO.Caption:=' = 1';
     FGO:=chkFGO.Checked;
  end
  else
  begin
     chkFGO.Caption:=' = 0';
     FGO:=chkFGO.Checked;
  end;
end;

procedure TForm1.FormDropFiles(Sender: TObject; const FileNames: array of String);
begin
  SynEdit1.Lines.LoadFromFile(FileNames[0]);
end;

procedure TForm1.miCutClick(Sender: TObject);
begin
   SynEdit1.CutToClipboard;
end;

procedure TForm1.miCopyClick(Sender: TObject);
begin
   SynEdit1.CopyToClipboard;
end;

procedure TForm1.miPasteClick(Sender: TObject);
begin
   SynEdit1.PasteFromClipboard;
end;

procedure TForm1.miSelAllClick(Sender: TObject);
begin
   SynEdit1.SelectAll;
end;

procedure TForm1.SynEdit1Change(Sender: TObject);
begin

end;


procedure TForm1.Timer1Timer(Sender: TObject);
var i: integer;
begin
  if (cur>=origin) then
  begin
   Output.Lines.Add('End of Program !');
   Timer1.Enabled:=False;
   exit;
  end;
   Label2.Caption:=inttostr(steps);
   inc(steps);
   runstep;
   vList.Lines.Clear;
   for i:=0 to LBLCount-1 do
       vList.Lines.Add(lbls[i].name+' @ '+dec2hex(lbls[i].addr,3)+' : '+inttostr(mem[lbls[i].addr].val));
   lblAC.Caption:=dec2bin(AC,16);
   lblE.Caption:=inttostr(E);
   showmem(hex2dec(Form2.Edit1.Caption),strtoint(Form2.Edit2.Caption));
   Form2.mList.Selected[abs(cur-hex2dec(Form2.Edit1.Caption))]:=true;
end;

end.

