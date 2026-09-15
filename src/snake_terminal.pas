unit snake_terminal;

{$mode objfpc}{$H+}

interface

function RunTerminal(Seed: LongWord): Integer;

implementation

uses
  Crt, SysUtils, BaseUnix, Termio, snake_engine;

const
  BoardWidth = 30;
  BoardHeight = 14;
  FrameWidth = BoardWidth * 2 + 2;
  MinimumColumns = 70;
  MinimumRows = 24;

type
  TCells = array[1..BoardWidth, 1..BoardHeight] of Byte;

function RunTerminal(Seed: LongWord): Integer;
var
  Game: TGame;
  PreviousCells, Cells: TCells;
  Columns, Rows, PreviousColumns, PreviousRows, Left, Top, Best: Integer;
  SavedTextAttr: Byte;
  Quit, Dirty, FullRedraw, WasSmall: Boolean;
  LastTick: QWord;
  PreviousPhase: TPhase;

  procedure Put(X, Y: Integer; const S: String; Foreground: Byte;
    Background: Byte = Black);
  begin
    TextColor(Foreground);
    TextBackground(Background);
    GotoXY(X, Y);
    Write(S);
  end;

  procedure Center(Y: Integer; const S: String; Color: Byte);
  begin
    Put(Left + (FrameWidth - Length(S)) div 2, Y, S, Color);
  end;

  function SpeedName: String;
  begin
    case Game.Difficulty of
      dfCalm: Result := 'CHILL';
      dfClassic: Result := 'CLASSIC';
      dfFast: Result := 'QUICK';
    end;
  end;

  procedure Panel(const Title, Detail, Action: String; Color: Byte);
  const
    PanelWidth = 48;
  var
    Y, PanelLeft: Integer;
  begin
    PanelLeft := Left + (FrameWidth - PanelWidth) div 2;
    for Y := Top + 8 to Top + 14 do
      Put(PanelLeft, Y, StringOfChar(' ', PanelWidth), White, Blue);
    Put(PanelLeft, Top + 8, StringOfChar('-', PanelWidth), Color, Blue);
    Put(PanelLeft + (PanelWidth - Length(Title)) div 2, Top + 10,
      Title, Color, Blue);
    Put(PanelLeft + (PanelWidth - Length(Detail)) div 2, Top + 12,
      Detail, White, Blue);
    Put(PanelLeft + (PanelWidth - Length(Action)) div 2, Top + 13,
      Action, LightCyan, Blue);
  end;

  procedure Render;
  var
    I, X, Y: Integer;
  begin
    Left := (Columns - FrameWidth) div 2 + 1;
    Top := (Rows - 22) div 2 + 1;
    if FullRedraw then
    begin
      TextBackground(Black);
      ClrScr;
      Center(Top, 'P A S C A L  /  S N A K E', LightGreen);
      Center(Top + 1, 'BUILT IN PASCAL. PLAYED IN YOUR TERMINAL.', DarkGray);
      Put(Left, Top + 4, '+' + StringOfChar('-', FrameWidth - 2) + '+', DarkGray);
      Put(Left, Top + 19, '+' + StringOfChar('-', FrameWidth - 2) + '+', DarkGray);
      for Y := 1 to BoardHeight do
      begin
        Put(Left, Top + 4 + Y, '|', DarkGray);
        Put(Left + FrameWidth - 1, Top + 4 + Y, '|', DarkGray);
      end;
      Center(Top + 21, 'WASD / ARROWS  MOVE   P  PAUSE   R  RESTART   Q  QUIT', LightGray);
    end;
    Put(Left, Top + 3, StringOfChar(' ', FrameWidth), LightGray);
    Put(Left + 1, Top + 3, Format('POINTS %4d', [Game.Score]), White);
    Put(Left + 22, Top + 3, Format('BEST %4d', [Best]), LightGreen);
    Put(Left + 47, Top + 3, SpeedName, LightCyan);
    FillChar(Cells, SizeOf(Cells), 0);
    for I := 1 to Game.Length do
      Cells[Game.Body[I].X, Game.Body[I].Y] := 1;
    Cells[Game.Body[1].X, Game.Body[1].Y] := 2;
    if Game.HasFood then Cells[Game.Food.X, Game.Food.Y] := 3;
    for Y := 1 to BoardHeight do
      for X := 1 to BoardWidth do
        if FullRedraw or (Cells[X, Y] <> PreviousCells[X, Y]) then
          case Cells[X, Y] of
            0: Put(Left + 1 + (X - 1) * 2, Top + 4 + Y, '  ', Black);
            1: Put(Left + 1 + (X - 1) * 2, Top + 4 + Y, 'oo', LightGreen);
            2: Put(Left + 1 + (X - 1) * 2, Top + 4 + Y, '@@', Black, LightGreen);
            3: Put(Left + 1 + (X - 1) * 2, Top + 4 + Y, '<>', LightRed);
          end;
    PreviousCells := Cells;
    case Game.Phase of
      phReady: Panel('READY TO PLAY?', '1 CHILL   2 CLASSIC   3 QUICK',
        'ENTER / SPACE  PLAY', LightGreen);
      phPaused: Panel('PAUSED', 'TAKE A BREATH. THE GAME CAN WAIT.',
        'P / SPACE  RESUME', Yellow);
      phLost: Panel('GAME OVER', Format('TOTAL: %d POINTS', [Game.Score]),
        'R  NEW GAME    Q  QUIT', LightRed);
      phWon: Panel('BOARD COMPLETE!', Format('TOTAL: %d POINTS', [Game.Score]),
        'R  NEW GAME    Q  QUIT', LightGreen);
    end;
    FullRedraw := False;
    Dirty := False;
  end;

  procedure ReadSize;
  var
    Size: TWinSize;
  begin
    if fpIOCtl(StdOutputHandle, TIOCGWINSZ, @Size) = 0 then
    begin
      Columns := Size.ws_col;
      Rows := Size.ws_row;
    end
    else
    begin
      Columns := ScreenWidth;
      Rows := ScreenHeight;
    end;
    { CRT coordinates are bounded; keep a valid window even in an empty PTY. }
    if Columns < 1 then Columns := 1;
    if Rows < 1 then Rows := 1;
    if Columns > 255 then Columns := 255;
    if Rows > 255 then Rows := 255;
  end;

  procedure HandleKey;
  var
    Key: Char;
    Direction: TDirection;
    IsDirection: Boolean;
  begin
    Key := ReadKey;
    IsDirection := False;
    Direction := dirRight;
    if Key = #0 then
    begin
      Key := ReadKey;
      IsDirection := True;
      case Key of
        #72: Direction := dirUp;
        #77: Direction := dirRight;
        #80: Direction := dirDown;
        #75: Direction := dirLeft;
        else IsDirection := False;
      end;
      Key := #0;
    end
    else
    begin
      Key := LowerCase(Key);
      case Key of
        'w': begin Direction := dirUp; IsDirection := True; end;
        'd': begin Direction := dirRight; IsDirection := True; end;
        's': begin Direction := dirDown; IsDirection := True; end;
        'a': begin Direction := dirLeft; IsDirection := True; end;
      end;
    end;
    if Key in ['q', #27, #3] then Quit := True;
    if WasSmall then Exit;
    if IsDirection then RequestTurn(Game, Direction);
    case Key of
      '1'..'3':
        if Game.Phase = phReady then
          Game.Difficulty := TDifficulty(Ord(Key) - Ord('1'));
      #13: StartGame(Game);
      ' ':
        if Game.Phase = phReady then StartGame(Game) else TogglePause(Game);
      'p': TogglePause(Game);
      'r': InitializeGame(Game, BoardWidth, BoardHeight, Seed, Game.Difficulty);
    end;
    Dirty := True;
  end;

begin
  Result := 2;
  if (IsATTY(StdInputHandle) <> 1) or (IsATTY(StdOutputHandle) <> 1) then
  begin
    WriteLn(StdErr, 'Use an interactive terminal: make play (Docker with -it).');
    Exit;
  end;
  if GetEnvironmentVariable('TERM') = 'dumb' then
  begin
    WriteLn(StdErr, 'This game requires an ANSI terminal such as xterm.');
    Exit;
  end;
  InitializeGame(Game, BoardWidth, BoardHeight, Seed, dfClassic);
  Best := 0;
  Quit := False;
  Dirty := True;
  FullRedraw := True;
  WasSmall := False;
  PreviousColumns := 0;
  PreviousRows := 0;
  LastTick := GetTickCount64;
  SavedTextAttr := TextAttr;
  CheckBreak := False;
  { CRT CursorOn/Off targets the Linux console; DEC private mode 25 targets xterm. }
  Write(StdOut, #27'[?25l');
  Flush(StdOut);
  try
    while not Quit do
    begin
      ReadSize;
      if (Columns <> PreviousColumns) or (Rows <> PreviousRows) then
      begin
        Window(1, 1, Columns, Rows);
        if (PreviousColumns <> 0) and (Game.Phase = phRunning) then TogglePause(Game);
        PreviousColumns := Columns;
        PreviousRows := Rows;
        FullRedraw := True;
        Dirty := True;
      end;
      WasSmall := (Columns < MinimumColumns) or (Rows < MinimumRows);
      if WasSmall then
      begin
        if Dirty then
        begin
          TextBackground(Black);
          ClrScr;
          Put(1, 1, Copy('Resize the terminal to 70x24. Q quits.', 1, Columns - 1), Yellow);
          Dirty := False;
        end;
        if KeyPressed then HandleKey;
        LastTick := GetTickCount64;
      end
      else
      begin
        PreviousPhase := Game.Phase;
        if KeyPressed then HandleKey;
        if Game.Phase <> PreviousPhase then
        begin
          FullRedraw := True;
          LastTick := GetTickCount64;
        end;
        if (Game.Phase = phRunning) and
           (GetTickCount64 - LastTick >= QWord(TickInterval(Game))) then
        begin
          StepGame(Game);
          LastTick := GetTickCount64;
          Dirty := True;
          if Game.Score > Best then Best := Game.Score;
          if Game.Phase <> PreviousPhase then FullRedraw := True;
        end;
        if Dirty then Render;
      end;
      Delay(10);
    end;
    Result := 0;
  finally
    TextAttr := SavedTextAttr;
    TextBackground(Black);
    ClrScr;
    Write(StdOut, #27'[?25h');
    Flush(StdOut);
    GotoXY(1, 1);
    WriteLn('GAME CLOSED.');
  end;
end;

end.
