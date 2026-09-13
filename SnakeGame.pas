program SnakeGame;

{$mode objfpc}{$H+}

uses
  SysUtils, snake_terminal;

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

var
  Seed: LongWord;

begin
  Seed := GetTickCount64 mod High(LongWord);
  if (ParamCount = 1) and (ParamStr(1) = '--help') then
  begin
    WriteLn(StdOut, 'Pascal Snake | SnakeGame [--seed 0..4294967295]');
    WriteLn(StdOut, 'WASD/setas: mover | P/Space: pausa | R: reiniciar | Q/Esc: sair');
    WriteLn(StdOut, 'Terminal ANSI 70x24. ENTER inicia; 1/2/3 escolhem a velocidade.');
    Halt(0);
  end;
  if ParamCount <> 0 then
  begin
    if (ParamCount <> 2) or (ParamStr(1) <> '--seed') then
    begin
      WriteLn(StdErr, 'Uso: SnakeGame [--seed 0..4294967295] | --help');
      Halt(2);
    end;
    if not ParseSeed(ParamStr(2), Seed) then
    begin
      WriteLn(StdErr, 'Seed fora do formato: use um inteiro de 0 a 4294967295.');
      Halt(2);
    end;
  end;
  Halt(RunTerminal(Seed));
end.
