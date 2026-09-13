program test_snake_engine;

{$mode objfpc}{$H+}

uses
  SysUtils, snake_engine;

var
  Checks: LongInt = 0;
  Cases: Integer = 0;

procedure Check(Condition: Boolean; const Message: String);
begin
  Inc(Checks);
  if not Condition then
  begin
    WriteLn(StdErr, 'FAIL: ', Message);
    Halt(1);
  end;
end;

procedure Passed(const Name: String);
begin
  Inc(Cases);
  WriteLn('ok ', Cases, ' - ', Name);
end;

procedure Valid(const G: TGame);
var
  Used: array[1..MaxWidth, 1..MaxHeight] of Boolean;
  I: Integer;
begin
  FillChar(Used, SizeOf(Used), 0);
  Check((G.Length >= InitialLength) and
    (G.Length <= G.Width * G.Height), 'bounded length');
  Check((G.GrowthPending >= 0) and
    (G.GrowthPending <= G.Width * G.Height - G.Length), 'bounded growth');
  for I := 1 to G.Length do
  begin
    Check((G.Body[I].X >= 1) and (G.Body[I].X <= G.Width) and
      (G.Body[I].Y >= 1) and (G.Body[I].Y <= G.Height), 'body in board');
    Check(not Used[G.Body[I].X, G.Body[I].Y], 'distinct body cells');
    Used[G.Body[I].X, G.Body[I].Y] := True;
    if I > 1 then
      Check(Abs(G.Body[I].X - G.Body[I - 1].X) +
        Abs(G.Body[I].Y - G.Body[I - 1].Y) = 1, 'contiguous body');
  end;
  if G.HasFood then
  begin
    Check((G.Food.X >= 1) and (G.Food.X <= G.Width) and
      (G.Food.Y >= 1) and (G.Food.Y <= G.Height), 'food in board');
    Check(not Used[G.Food.X, G.Food.Y], 'food outside body');
  end;
  if G.Phase = phWon then
    Check((G.Length = G.Width * G.Height) and not G.HasFood, 'full board wins');
end;

function NewGame(Seed: LongWord = 42): TGame;
begin
  Check(InitializeGame(Result, 30, 14, Seed, dfClassic), 'init');
  StartGame(Result);
end;

procedure TestInitialization;
var
  G, Before: TGame;
  Seed: LongWord;
begin
  for Seed := 0 to 1023 do
  begin
    G := NewGame(Seed);
    Valid(G);
    Check(G.Score = 0, 'initial score');
    Check(G.Length = 5, 'initial length');
  end;
  G := NewGame(High(LongWord));
  Valid(G);
  Before := G;
  Check(not InitializeGame(G, 5, 14, 1, dfCalm), 'reject narrow board');
  Check(CompareMem(@G, @Before, SizeOf(G)), 'failed init preserves state');
  Check(not InitializeGame(G, MaxWidth + 1, 14, 1, dfCalm), 'reject wide board');
  Check(not InitializeGame(G, 30, 1, 1, dfCalm), 'reject short board');
  Check(not InitializeGame(G, 30, MaxHeight + 1, 1, dfCalm), 'reject tall board');
  Check(InitializeGame(G, 6, 2, 0, dfCalm), 'minimum board');
  Valid(G);
  Check(InitializeGame(G, MaxWidth, MaxHeight, 0, dfFast), 'maximum board');
  Valid(G);
  Passed('initialization, seed boundaries, dimensions and free food');
end;

procedure TestMovementAndTurns;
var
  G: TGame;
  Head: TPoint;
  D, Opposite, Turn: TDirection;
begin
  for D := Low(TDirection) to High(TDirection) do
  begin
    G := NewGame;
    G.Direction := D;
    Opposite := TDirection((Ord(D) + 2) mod 4);
    Turn := TDirection((Ord(D) + 1) mod 4);
    Check(not RequestTurn(G, Opposite), 'reversal rejected in every direction');
    Check(not RequestTurn(G, D), 'same direction does not consume turn');
    Check(RequestTurn(G, Turn), 'perpendicular turn accepted');
    Check(not RequestTurn(G, Opposite), 'second turn in same tick rejected');
  end;
  G := NewGame;
  Head := G.Body[1];
  G.Food := Point(1, 1);
  Check(StepGame(G) = srMoved, 'move result');
  Check(SamePoint(G.Body[1], Point(Head.X + 1, Head.Y)), 'head advances');
  Check(SamePoint(G.Body[2], Head), 'body follows head');
  Check(RequestTurn(G, dirUp), 'first turn');
  Check(not RequestTurn(G, dirLeft), 'fast up-left cannot reverse');
  Check(StepGame(G) = srMoved, 'turn applies');
  Check(G.Direction = dirUp, 'committed direction');
  Check(RequestTurn(G, dirLeft), 'next tick accepts new turn');
  Valid(G);
  Passed('movement, reversal and one valid turn per tick');
end;

procedure TestGrowth;
var
  G: TGame;
  I: Integer;
begin
  G := NewGame;
  G.Food := Point(G.Body[1].X + 1, G.Body[1].Y);
  Check(StepGame(G) = srAte, 'food consumed');
  Check((G.Score = 10) and (G.Length = 6) and
    (G.GrowthPending = 4), 'growth debt replaces uninitialized segments');
  Valid(G);
  G.Food := Point(1, 1);
  for I := 1 to 4 do
  begin
    Check(StepGame(G) = srMoved, 'growth step');
    Valid(G);
  end;
  Check((G.Length = 10) and (G.GrowthPending = 0), 'exactly five new segments');
  Check(StepGame(G) = srMoved, 'normal step after growth');
  Check(G.Length = 10, 'growth stops');
  Passed('safe gradual growth, score and new food');
end;

procedure TailFixture(var G: TGame);
begin
  G := NewGame;
  G.Length := 8;
  G.Body[1] := Point(3, 2);
  G.Body[2] := Point(4, 2);
  G.Body[3] := Point(4, 3);
  G.Body[4] := Point(4, 4);
  G.Body[5] := Point(3, 4);
  G.Body[6] := Point(2, 4);
  G.Body[7] := Point(2, 3);
  G.Body[8] := Point(2, 2);
  G.Direction := dirLeft;
  G.Food := Point(1, 1);
end;

procedure TestCollisions;
var
  G, Before: TGame;
  D: TDirection;
  I: Integer;
begin
  TailFixture(G);
  Check(StepGame(G) = srMoved, 'vacating tail is allowed');
  Valid(G);
  TailFixture(G);
  G.GrowthPending := 1;
  Before := G;
  Check(StepGame(G) = srLost, 'growing tail is an obstacle');
  Check(CompareMem(@G.Body, @Before.Body, SizeOf(G.Body)), 'fatal move is atomic');
  TailFixture(G);
  G.Direction := dirRight;
  Check(StepGame(G) = srLost, 'body collision');
  for D := Low(TDirection) to High(TDirection) do
  begin
    G := NewGame;
    G.Direction := D;
    for I := 1 to G.Length do
      case D of
        dirUp: G.Body[I] := Point(3, I);
        dirRight: G.Body[I] := Point(G.Width - I + 1, 3);
        dirDown: G.Body[I] := Point(3, G.Height - I + 1);
        dirLeft: G.Body[I] := Point(I, 3);
      end;
    G.Food := Point(1, 1);
    Check(StepGame(G) = srLost, 'all four walls are fatal');
    Check(G.Phase = phLost, 'lost phase');
    Check(StepGame(G) = srIdle, 'lost game cannot move');
    Valid(G);
  end;
  Passed('four walls, body, moving tail and growing tail');
end;

procedure NearlyFull(var G: TGame; Width, Height: Integer);
var
  X, Y, I: Integer;
begin
  Check(InitializeGame(G, Width, Height, 42, dfClassic), 'near-full init');
  StartGame(G);
  I := 0;
  { Caminho contínuo que deixa somente (1,1) livre; altura deve ser par. }
  for Y := 1 to Height do
    if Odd(Y) then
      for X := 2 to Width do
      begin Inc(I); G.Body[I] := Point(X, Y); end
    else
      for X := Width downto 2 do
      begin Inc(I); G.Body[I] := Point(X, Y); end;
  for Y := Height downto 2 do
  begin Inc(I); G.Body[I] := Point(1, Y); end;
  G.Length := I;
  G.Direction := dirLeft;
  G.Food := Point(1, 1);
  Valid(G);
end;

procedure TestCapacity;
var
  G: TGame;
begin
  NearlyFull(G, 6, 2);
  Dec(G.Length);
  Check(StepGame(G) = srAte, 'penultimate free cell');
  Check(SamePoint(G.Food, Point(1, 2)), 'food selects the only free cell');
  Valid(G);
  Check(RequestTurn(G, dirDown), 'turn into final cell');
  Check(StepGame(G) = srWon, 'small board victory');
  Valid(G);
  NearlyFull(G, MaxWidth, MaxHeight);
  G.GrowthPending := 1;
  Check(StepGame(G) = srWon, 'maximum capacity does not overflow array');
  Check(G.Length = MaxCells, 'all array cells valid');
  Check(G.GrowthPending = 0, 'no excess growth after victory');
  Check(StepGame(G) = srIdle, 'won game cannot move');
  Check(not RequestTurn(G, dirDown), 'won game cannot turn');
  Valid(G);
  Passed('single free cell, full-board victory and maximum capacity');
end;

procedure TestPhasesAndSpeed;
var
  G, Before: TGame;
begin
  Check(InitializeGame(G, 30, 14, 42, dfCalm), 'ready init');
  Before := G;
  Check(StepGame(G) = srIdle, 'ready does not move');
  Check(not RequestTurn(G, dirDown), 'ready cannot turn');
  TogglePause(G);
  Check(CompareMem(@G, @Before, SizeOf(G)), 'ready pause is ignored');
  StartGame(G);
  TogglePause(G);
  Before := G;
  Check(StepGame(G) = srIdle, 'pause does not move');
  Check(not RequestTurn(G, dirUp), 'pause ignores direction');
  StartGame(G);
  Check(CompareMem(@G, @Before, SizeOf(G)), 'paused state including RNG unchanged');
  TogglePause(G);
  Check(G.Phase = phRunning, 'resume');
  Check(TickInterval(G) = 180, 'calm speed');
  G.Difficulty := dfClassic;
  Check(TickInterval(G) = 110, 'classic speed');
  G.Score := 10;
  Check(TickInterval(G) = 108, 'acceleration per food');
  G.Difficulty := dfFast;
  G.Score := 0;
  Check(TickInterval(G) = 70, 'fast speed');
  G.Score := MaxCells * PointsPerFood;
  Check(TickInterval(G) = MinimumTickMs, 'speed lower bound');
  G := NewGame;
  Check((G.Length = 5) and (G.Score = 0) and not G.TurnPending, 'restart resets state');
  Passed('ready, pause, resume, restart and bounded speeds');
end;

procedure TestDeterminismAndProperties;
var
  G, Twin: TGame;
  Seed, Tick: Integer;
  Direction: TDirection;
  A, B: TStepResult;
begin
  for Seed := 0 to 255 do
  begin
    G := NewGame(Seed);
    Twin := NewGame(Seed);
    for Tick := 1 to 200 do
    begin
      Direction := TDirection((Tick * 17 + Seed * 13 + Tick div 7) mod 4);
      RequestTurn(G, Direction);
      RequestTurn(Twin, Direction);
      if Tick mod 19 = 0 then
      begin
        TogglePause(G);
        TogglePause(Twin);
      end;
      A := StepGame(G);
      B := StepGame(Twin);
      Check(A = B, 'same seed and input yield same result');
      Check(CompareMem(@G, @Twin, SizeOf(G)), 'full deterministic state');
      Valid(G);
      if G.Phase = phLost then
      begin
        G := NewGame(Seed + Tick);
        Twin := NewGame(Seed + Tick);
      end;
    end;
  end;
  Passed('51200 deterministic paired steps and state invariants');
end;

begin
  TestInitialization;
  TestMovementAndTurns;
  TestGrowth;
  TestCollisions;
  TestCapacity;
  TestPhasesAndSpeed;
  TestDeterminismAndProperties;
  WriteLn('PASS: ', Cases, ' groups, ', Checks, ' checks');
end.
