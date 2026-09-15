program SnakeTerminal;

{$mode objfpc}{$H+}

uses SysUtils, snake_cli, snake_terminal;

var Seed: LongWord;
begin
  Seed := GetTickCount64 mod High(LongWord);
  if (ParamCount = 1) and (ParamStr(1) = '--help') then
  begin
    WriteLn(StdOut, 'Pascal Snake | SnakeTerminal [--seed 0..4294967295]');
    WriteLn(StdOut, 'WASD/arrows: move | P/Space: pause | R: restart | Q/Esc: quit');
    WriteLn(StdOut, 'ANSI terminal 70x24. ENTER starts; 1/2/3 select speed.');
    Halt(0);
  end;
  if ParamCount <> 0 then
  begin
    if (ParamCount <> 2) or (ParamStr(1) <> '--seed') then
    begin
      WriteLn(StdErr, 'Usage: SnakeTerminal [--seed 0..4294967295] | --help');
      Halt(2);
    end;
    if not ParseSeed(ParamStr(2), Seed) then
    begin
      WriteLn(StdErr, 'Invalid seed: use a decimal integer from 0 to 4294967295.');
      Halt(2);
    end;
  end;
  Halt(RunTerminal(Seed));
end.
