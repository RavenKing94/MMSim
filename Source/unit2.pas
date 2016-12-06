unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  MorrisASM,step;

type

  { TForm2 }

  TForm2 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    mList: TListBox;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mListSelectionChange(Sender: TObject; User: boolean);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

{ TForm2 }

procedure TForm2.Button1Click(Sender: TObject);
begin
   showmem(hex2dec(Edit1.Caption),strtoint(Edit2.Caption));
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
   showmem(hex2dec(Edit1.Caption),strtoint(Edit2.Caption));
end;

procedure TForm2.mListSelectionChange(Sender: TObject; User: boolean);
begin
   if (User) then
      Form2.mList.Selected[abs(cur-hex2dec(Form2.Edit1.Caption))]:=true;
end;

end.

