unit snake_engine;

{$mode objfpc}{$H+}

interface

const
  MaxWidth = 40;
  MaxHeight = 20;
  MaxCells = MaxWidth * MaxHeight;
  InitialLength = 5;
  GrowthPerFood = 5;
  PointsPerFood = 10;
  MinimumTickMs = 45;

type
  TPoint = record
    X, Y: Integer;
  end;
  TDirection = (dirUp, dirRight, dirDown, dirLeft);
  TPhase = (phReady, phRunning, phPaused, phLost, phWon);
  TDifficulty = (dfCalm, dfClassic, dfFast);
  TGameMode = (gmClassic, gmWrap);
  TStepResult = (srIdle, srMoved, srAte, srLost, srWon);
  TGame = record
    Width, Height, Length, GrowthPending, Score: Integer;
    Body: array[1..MaxCells] of TPoint;
    Food: TPoint;
    HasFood, TurnPending: Boolean;
    Direction, NextDirection: TDirection;
    Phase: TPhase;
    Difficulty: TDifficulty;
    Mode: TGameMode;
    RandomState: LongWord;
  end;

function Point(X, Y: Integer): TPoint;
function SamePoint(const A, B: TPoint): Boolean;
function SnakeAt(const Game: TGame; X, Y: Integer): Boolean;
function InitializeGame(var Game: TGame; Width, Height: Integer;
  Seed: LongWord; Difficulty: TDifficulty; Mode: TGameMode = gmClassic): Boolean;
procedure StartGame(var Game: TGame);
procedure TogglePause(var Game: TGame);
function RequestTurn(var Game: TGame; Direction: TDirection): Boolean;
function StepGame(var Game: TGame): TStepResult;
function TickInterval(const Game: TGame): Integer;

implementation

function Point(X, Y: Integer): TPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;

function SamePoint(const A, B: TPoint): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

function SnakeAt(const Game: TGame; X, Y: Integer): Boolean;
var
  I: Integer;
begin
  for I := 1 to Game.Length do
    if SamePoint(Game.Body[I], Point(X, Y)) then Exit(True);
  Result := False;
end;

procedure PlaceFood(var Game: TGame);
var
  Occupied: array[1..MaxWidth, 1..MaxHeight] of Boolean;
  I, X, Y, FreeCells, Choice: Integer;
begin
  FreeCells := Game.Width * Game.Height - Game.Length;
  Game.HasFood := FreeCells > 0;
  if not Game.HasFood then Exit;
  FillChar(Occupied, SizeOf(Occupied), 0);
  for I := 1 to Game.Length do
    Occupied[Game.Body[I].X, Game.Body[I].Y] := True;
  { Park-Miller: local state; Int64 prevents multiplication overflow. }
  Game.RandomState := (Int64(Game.RandomState) * 48271) mod 2147483647;
  Choice := Game.RandomState mod LongWord(FreeCells);
  { Selecting the nth free cell terminates even when only one cell is free. }
  for Y := 1 to Game.Height do
    for X := 1 to Game.Width do
      if not Occupied[X, Y] then
      begin
        if Choice = 0 then
        begin
          Game.Food := Point(X, Y);
          Exit;
        end;
        Dec(Choice);
      end;
end;

function InitializeGame(var Game: TGame; Width, Height: Integer;
  Seed: LongWord; Difficulty: TDifficulty; Mode: TGameMode): Boolean;
var
  I, HeadX: Integer;
begin
  Result := False;
  if (Width < InitialLength + 1) or (Width > MaxWidth) or
     (Height < 2) or (Height > MaxHeight) then Exit;
  FillChar(Game, SizeOf(Game), 0);
  Game.Width := Width;
  Game.Height := Height;
  Game.Length := InitialLength;
  Game.Direction := dirRight;
  Game.NextDirection := dirRight;
  Game.Phase := phReady;
  Game.Difficulty := Difficulty;
  Game.Mode := Mode;
  Game.RandomState := (Seed mod 2147483646) + 1;
  HeadX := (Width + InitialLength) div 2;
  for I := 1 to Game.Length do
    Game.Body[I] := Point(HeadX - I + 1, (Height + 1) div 2);
  PlaceFood(Game);
  Result := True;
end;

procedure StartGame(var Game: TGame);
begin
  if Game.Phase = phReady then Game.Phase := phRunning;
end;

procedure TogglePause(var Game: TGame);
begin
  case Game.Phase of
    phRunning: Game.Phase := phPaused;
    phPaused: Game.Phase := phRunning;
  end;
end;

function RequestTurn(var Game: TGame; Direction: TDirection): Boolean;
begin
  Result := False;
  if (Game.Phase <> phRunning) or Game.TurnPending then Exit;
  if (Direction = Game.Direction) or
     ((Ord(Direction) + 2) mod 4 = Ord(Game.Direction)) then Exit;
  Game.NextDirection := Direction;
  Game.TurnPending := True;
  Result := True;
end;

function StepGame(var Game: TGame): TStepResult;
var
  Head: TPoint;
  Direction: TDirection;
  I, LastObstacle, Growth, Capacity: Integer;
  Eating, Growing: Boolean;
begin
  Result := srIdle;
  if Game.Phase <> phRunning then Exit;
  Direction := Game.Direction;
  if Game.TurnPending then Direction := Game.NextDirection;
  Head := Game.Body[1];
  case Direction of
    dirUp: Dec(Head.Y);
    dirRight: Inc(Head.X);
    dirDown: Inc(Head.Y);
    dirLeft: Dec(Head.X);
  end;
  if Game.Mode = gmWrap then
  begin
    Head.X := (Head.X + Game.Width - 1) mod Game.Width + 1;
    Head.Y := (Head.Y + Game.Height - 1) mod Game.Height + 1;
  end;
  Eating := Game.HasFood and SamePoint(Head, Game.Food);
  Capacity := Game.Width * Game.Height;
  Growth := Game.GrowthPending;
  if Eating then Inc(Growth, GrowthPerFood);
  if Growth > Capacity - Game.Length then Growth := Capacity - Game.Length;
  Growing := Growth > 0;

  { The tail is no longer an obstacle on the step when it moves away. }
  LastObstacle := Game.Length;
  if not Growing then Dec(LastObstacle);
  Result := srLost;
  if (Head.X >= 1) and (Head.X <= Game.Width) and
     (Head.Y >= 1) and (Head.Y <= Game.Height) then
  begin
    Result := srMoved;
    for I := 1 to LastObstacle do
      if SamePoint(Head, Game.Body[I]) then Result := srLost;
  end;
  Game.TurnPending := False;
  if Result = srLost then
  begin
    Game.Phase := phLost;
    Exit;
  end;

  if Growing then
  begin
    Inc(Game.Length);
    Dec(Growth);
  end;
  for I := Game.Length downto 2 do Game.Body[I] := Game.Body[I - 1];
  Game.Body[1] := Head;
  Game.Direction := Direction;
  Game.GrowthPending := Growth;
  if Eating then
  begin
    Inc(Game.Score, PointsPerFood);
    Result := srAte;
  end;
  if Game.Length = Capacity then
  begin
    Game.Phase := phWon;
    Game.HasFood := False;
    Game.GrowthPending := 0;
    Result := srWon;
  end
  else if Eating then PlaceFood(Game);
end;

function TickInterval(const Game: TGame): Integer;
begin
  case Game.Difficulty of
    dfCalm: Result := 180;
    dfClassic: Result := 110;
    dfFast: Result := 70;
  end;
  Dec(Result, (Game.Score div PointsPerFood) * 2);
  if Result < MinimumTickMs then Result := MinimumTickMs;
end;

end.
