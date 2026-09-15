unit snake_cli;

{$mode objfpc}{$H+}

interface

function ParseSeed(const Text: String; out Seed: LongWord): Boolean;

implementation

uses SysUtils;

function ParseSeed(const Text: String; out Seed: LongWord): Boolean;
var
  I: Integer;
  Value: QWord;
begin
  Result := False;
  if Text = '' then Exit;
  for I := 1 to Length(Text) do
    if not (Text[I] in ['0'..'9']) then Exit;
  if not TryStrToQWord(Text, Value) then Exit;
  if Value > High(LongWord) then Exit;
  Seed := Value;
  Result := True;
end;

end.
