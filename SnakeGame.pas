program SnakeGame;

{$mode objfpc}{$H+}

uses SysUtils, snake_cli, snake_desktop;

procedure Usage;
begin
  WriteLn('Snake. / The Pascal Edition');
  WriteLn('Usage: SnakeGame [--seed NUMBER] [--no-audio] [--reduced-motion]');
  WriteLn('       SnakeGame --self-test');
  WriteLn('       SnakeGame --snapshot FILE.bmp [--scene menu|play|pause|over|win]');
  WriteLn('WASD/arrows move; Enter starts; Space/P pauses; R restarts; Esc opens menu.');
  WriteLn('Tab selects world; 1/2/3 select pace; M mutes; V reduces motion; F11 fullscreen; Q quits.');
end;

var Options: TDesktopOptions; I: Integer; Argument: String; HasScene: Boolean;
begin
  Options := Default(TDesktopOptions);
  Options.Seed := GetTickCount64 mod High(LongWord);
  Options.Scene := 'menu'; I := 1; HasScene := False;
  try
    while I <= ParamCount do
    begin
      Argument := ParamStr(I);
      case Argument of
        '--help': begin Usage; Halt(0); end;
        '--no-audio': Options.NoAudio := True;
        '--reduced-motion': Options.ReducedMotion := True;
        '--self-test': Options.SelfTest := True;
        '--seed', '--snapshot', '--scene':
          begin
            Inc(I);
            if I > ParamCount then raise Exception.Create('Missing value for ' + Argument);
            case Argument of
              '--seed': if not ParseSeed(ParamStr(I), Options.Seed) then
                raise Exception.Create('Invalid seed: use a decimal integer from 0 to 4294967295.');
              '--snapshot':
                begin
                  Options.Snapshot := ParamStr(I);
                  if Options.Snapshot = '' then raise Exception.Create('Snapshot path cannot be empty.');
                end;
              '--scene': begin Options.Scene := ParamStr(I); HasScene := True; end;
            end;
          end;
      else raise Exception.Create('Unknown option: ' + Argument);
      end;
      Inc(I);
    end;
    if (Options.Scene <> 'menu') and (Options.Scene <> 'play') and
       (Options.Scene <> 'pause') and (Options.Scene <> 'over') and
       (Options.Scene <> 'win') then raise Exception.Create('Unknown snapshot scene.');
    if Options.SelfTest and ((Options.Snapshot <> '') or Options.NoAudio or Options.ReducedMotion) then
      raise Exception.Create('--self-test cannot be combined with snapshot, audio or motion options.');
    if (Options.Snapshot = '') and HasScene then
      raise Exception.Create('--scene requires --snapshot.');
  except
    on E: Exception do begin WriteLn(StdErr, E.Message); Halt(2); end;
  end;
  Halt(RunDesktop(Options));
end.
