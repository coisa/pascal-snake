unit snake_desktop;

{$mode objfpc}{$H+}

interface

type
  TDesktopOptions = record
    Seed: LongWord;
    Snapshot, Scene: String;
    SelfTest, NoAudio, ReducedMotion: Boolean;
  end;

function RunDesktop(const Options: TDesktopOptions): Integer;

implementation

uses SysUtils, Math, snake_engine, snake_sdl;

const
  CanvasW = 1200;
  CanvasH = 800;
  BoardX = 52;
  BoardY = 192;
  CellSize = 28;
  BoardW = 28;
  BoardH = 18;
  Ink = $0B1018;
  Panel = $111A25;
  Edge = $243442;
  Mint = $A9F978;
  Teal = $39CDA2;
  White = $EAF3EC;
  Muted = $96A7B6;
  Coral = $FF907E;
  FontSizes: array[0..4] of Integer = (12, 16, 24, 42, 76);
  SpeedNames: array[TDifficulty] of String = ('CHILL', 'CLASSIC', 'QUICK');

type
  TTextCache = record
    Text: String;
    Font, W, H: Integer;
    Texture: Pointer;
  end;
  TParticle = record
    X, Y, VX, VY, Life, Total: Double;
    Color: LongWord;
  end;
  TApp = record
    Window, Renderer: Pointer;
    Fonts: array[0..4] of Pointer;
    Cache: array[0..127] of TTextCache;
    CacheNext: Integer;
    Particles: array[0..95] of TParticle;
    ParticleNext: Integer;
    Audio: LongWord;
    FPMask: TFPUExceptionMask;
    SDLReady, TTFReady, Quit, Muted, ReducedMotion, Fullscreen: Boolean;
    Game, Previous: TGame;
    Seed: LongWord;
    Best: array[TGameMode, TDifficulty] of Integer;
    Elapsed, Accumulator, Countdown, Flash, Toast, PhaseAge: Double;
    LastPhase: TPhase;
    MouseX, MouseY: Single;
    ToastText: String;
  end;

var A: TApp;

function RGBA(Value: LongWord; Alpha: Byte = 255): TColor;
begin
  Result.R := (Value shr 16) and 255;
  Result.G := (Value shr 8) and 255;
  Result.B := Value and 255;
  Result.A := Alpha;
end;

function Blend(FromColor, ToColor: LongWord; T: Double): LongWord;
var C, D: TColor;
begin
  C := RGBA(FromColor); D := RGBA(ToColor);
  Result := (LongWord(Round(C.R + (D.R - C.R) * T)) shl 16) or
    (LongWord(Round(C.G + (D.G - C.G) * T)) shl 8) or
    LongWord(Round(C.B + (D.B - C.B) * T));
end;

procedure SetColor(Color: LongWord; Alpha: Byte = 255);
var C: TColor;
begin
  C := RGBA(Color, Alpha);
  SDL_SetRenderDrawColor(A.Renderer, C.R, C.G, C.B, C.A);
end;

procedure Rect(X, Y, W, H: Double; Color: LongWord; Alpha: Byte = 255);
var R: TRect;
begin
  R.X := Round(X); R.Y := Round(Y); R.W := Round(W); R.H := Round(H);
  SetColor(Color, Alpha);
  SDL_RenderFillRect(A.Renderer, @R);
end;

procedure Circle(X, Y, Radius: Double; Color: LongWord; Alpha: Byte = 255);
var V: array[0..95] of TVertex; I, J: Integer; Angle: Double;
begin
  for I := 0 to 31 do
    for J := 0 to 2 do
    begin
      V[I * 3 + J].Color := RGBA(Color, Alpha);
      V[I * 3 + J].TexCoord.X := 0;
      V[I * 3 + J].TexCoord.Y := 0;
      V[I * 3 + J].Position.X := X;
      V[I * 3 + J].Position.Y := Y;
      if J > 0 then
      begin
        Angle := (I + J - 1) * Pi / 16;
        V[I * 3 + J].Position.X := X + Cos(Angle) * Radius;
        V[I * 3 + J].Position.Y := Y + Sin(Angle) * Radius;
      end;
    end;
  SDL_RenderGeometry(A.Renderer, nil, @V[0], Length(V), nil, 0);
end;

procedure Rounded(X, Y, W, H, Radius: Double; Color: LongWord; Alpha: Byte = 255);
begin
  Rect(X + Radius, Y, W - Radius * 2, H, Color, Alpha);
  Rect(X, Y + Radius, Radius, H - Radius * 2, Color, Alpha);
  Rect(X + W - Radius, Y + Radius, Radius, H - Radius * 2, Color, Alpha);
  Circle(X + Radius, Y + Radius, Radius, Color, Alpha);
  Circle(X + W - Radius, Y + Radius, Radius, Color, Alpha);
  Circle(X + Radius, Y + H - Radius, Radius, Color, Alpha);
  Circle(X + W - Radius, Y + H - Radius, Radius, Color, Alpha);
end;

function CachedText(const Value: String; FontIndex: Integer): Integer;
var I: Integer; Surface: Pointer;
begin
  for I := 0 to High(A.Cache) do
    if (A.Cache[I].Texture <> nil) and (A.Cache[I].Text = Value) and
       (A.Cache[I].Font = FontIndex) then Exit(I);
  Result := A.CacheNext;
  A.CacheNext := (A.CacheNext + 1) mod Length(A.Cache);
  with A.Cache[Result] do
  begin
    if Texture <> nil then SDL_DestroyTexture(Texture);
    Texture := nil;
    Text := Value; Font := FontIndex;
  end;
  Surface := TTF_RenderUTF8_Blended(A.Fonts[FontIndex], PChar(Value), RGBA($FFFFFF));
  if Surface = nil then raise Exception.Create('Could not rasterize text: ' + String(SDL_GetError()));
  try
    A.Cache[Result].Texture := SDL_CreateTextureFromSurface(A.Renderer, Surface);
  finally
    SDL_FreeSurface(Surface);
  end;
  with A.Cache[Result] do
  begin
    if Texture = nil then raise Exception.Create('Could not create text texture.');
    SDL_QueryTexture(Texture, nil, nil, @W, @H);
  end;
end;

procedure Text(X, Y: Double; const Value: String; Font: Integer;
  Color: LongWord; Center: Boolean = False);
var I: Integer; R: TRect; C: TColor;
begin
  if Value = '' then Exit;
  I := CachedText(Value, Font);
  R.X := Round(X); R.Y := Round(Y);
  R.W := A.Cache[I].W; R.H := A.Cache[I].H;
  if Center then Dec(R.X, R.W div 2);
  C := RGBA(Color);
  SDL_SetTextureColorMod(A.Cache[I].Texture, C.R, C.G, C.B);
  SDL_RenderCopy(A.Renderer, A.Cache[I].Texture, nil, @R);
end;

function Inside(X, Y, W, H: Integer): Boolean;
begin
  Result := (A.MouseX >= X) and (A.MouseX < X + W) and
    (A.MouseY >= Y) and (A.MouseY < Y + H);
end;

procedure Button(X, Y, W, H: Integer; const LabelText: String; Selected: Boolean;
  Enabled: Boolean = True; FontIndex: Integer = 1);
var Background, Foreground: LongWord;
begin
  Background := $1C2935; Foreground := Muted;
  if Enabled and Inside(X, Y, W, H) then Background := $304252;
  if Selected then begin Background := Mint; Foreground := Ink; end;
  if not Enabled then
    if Selected then begin Background := $213A30; Foreground := Mint; end
    else begin Background := $18232E; Foreground := $71818F; end;
  Rounded(X, Y, W, H, 10, Background);
  Text(X + W / 2, Y + (H - FontSizes[FontIndex] - 3) / 2,
    LabelText, FontIndex, Foreground, True);
end;

procedure Tone(Frequency: Double; Falling: Boolean = False);
var Samples: array[0..5759] of SmallInt; I: Integer; T, Envelope, Phase: Double;
begin
  if A.Muted or (A.Audio = 0) then Exit;
  SDL_ClearQueuedAudio(A.Audio);
  Phase := 0;
  for I := 0 to High(Samples) do
  begin
    T := I / Length(Samples);
    Envelope := Sin(Pi * T) * (1 - T);
    if Falling then Phase := Phase + 2 * Pi * Frequency * (1 - T * 0.7) / 48000
    else Phase := Phase + 2 * Pi * Frequency / 48000;
    Samples[I] := Round((Sin(Phase) + Sin(Phase * 2) * 0.18) * Envelope * 4800);
  end;
  if SDL_QueueAudio(A.Audio, @Samples[0], SizeOf(Samples)) <> 0 then
  begin
    SDL_CloseAudioDevice(A.Audio); A.Audio := 0;
  end;
end;

procedure Burst(OriginX, OriginY: Double; ParticleColor: LongWord; Count: Integer);
var I: Integer; Angle, Speed: Double;
begin
  if A.ReducedMotion then Exit;
  for I := 1 to Count do
  begin
    Angle := I * 2.399963 + A.Elapsed;
    Speed := 45 + (I * 29 mod 90);
    with A.Particles[A.ParticleNext] do
    begin
      X := OriginX; Y := OriginY;
      VX := Cos(Angle) * Speed; VY := Sin(Angle) * Speed;
      Total := 0.45 + (I mod 5) * 0.07; Life := Total;
      Color := ParticleColor;
    end;
    A.ParticleNext := (A.ParticleNext + 1) mod Length(A.Particles);
  end;
end;

procedure ResetGame;
var Difficulty: TDifficulty; Mode: TGameMode;
begin
  Difficulty := A.Game.Difficulty; Mode := A.Game.Mode;
  InitializeGame(A.Game, BoardW, BoardH, A.Seed, Difficulty, Mode);
  A.Previous := A.Game;
  A.Accumulator := 0; A.Countdown := 0; A.PhaseAge := 0;
  A.Toast := 0; A.Flash := 0;
  FillChar(A.Particles, SizeOf(A.Particles), 0);
end;

procedure BeginGame;
begin
  if A.Game.Phase in [phLost, phWon] then ResetGame;
  StartGame(A.Game);
  A.Countdown := 1.5;
  A.Accumulator := 0;
  Tone(440);
end;

procedure PauseGame;
begin
  TogglePause(A.Game);
  A.Accumulator := 0;
  A.Previous := A.Game;
end;

procedure Activate;
begin
  case A.Game.Phase of
    phReady, phLost, phWon: BeginGame;
    phRunning, phPaused: PauseGame;
  end;
end;

procedure SelectMode;
begin
  if A.Game.Phase <> phReady then Exit;
  if A.Game.Mode = gmClassic then A.Game.Mode := gmWrap
  else A.Game.Mode := gmClassic;
  ResetGame;
end;

procedure HandleKey(Key: LongInt);
begin
  case Key of
    13, 32: Activate;
    Ord('p'): if A.Game.Phase in [phRunning, phPaused] then PauseGame;
    Ord('r'): begin ResetGame; BeginGame; end;
    27: if A.Game.Phase = phReady then A.Quit := True else ResetGame;
    Ord('q'): A.Quit := True;
    9: SelectMode;
    Ord('1')..Ord('3'):
      if A.Game.Phase = phReady then
      begin
        A.Game.Difficulty := TDifficulty(Key - Ord('1'));
        ResetGame;
      end;
    Ord('m'):
      begin
        A.Muted := not A.Muted;
        if A.Muted and (A.Audio <> 0) then SDL_ClearQueuedAudio(A.Audio);
      end;
    Ord('v'):
      begin
        A.ReducedMotion := not A.ReducedMotion;
        FillChar(A.Particles, SizeOf(A.Particles), 0);
      end;
    KeyF11:
      begin
        if A.Fullscreen then
          A.Fullscreen := SDL_SetWindowFullscreen(A.Window, 0) <> 0
        else A.Fullscreen := SDL_SetWindowFullscreen(A.Window, $1001) = 0;
      end;
    Ord('w'), KeyUp: RequestTurn(A.Game, dirUp);
    Ord('d'), KeyRight: RequestTurn(A.Game, dirRight);
    Ord('s'), KeyDown: RequestTurn(A.Game, dirDown);
    Ord('a'), KeyLeft: RequestTurn(A.Game, dirLeft);
  end;
end;

procedure HandleClick;
var I: Integer;
begin
  if Inside(912, 552, 232, 52) then Activate;
  if Inside(912, 614, 232, 34) and (A.Game.Phase <> phReady) then ResetGame;
  if Inside(912, 680, 112, 28) then HandleKey(Ord('m'));
  if Inside(1032, 680, 112, 28) then HandleKey(Ord('v'));
  if A.Game.Phase <> phReady then Exit;
  if (Inside(912, 376, 112, 40) and (A.Game.Mode <> gmClassic)) or
     (Inside(1032, 376, 112, 40) and (A.Game.Mode <> gmWrap)) then SelectMode;
  for I := 0 to 2 do
    if Inside(912 + I * 80, 476, 72, 38) then
    begin
      A.Game.Difficulty := TDifficulty(I); ResetGame;
    end;
end;

procedure Events;
var E: TEvent; X, Y: LongInt;
begin
  SDL_GetMouseState(@X, @Y);
  SDL_RenderWindowToLogical(A.Renderer, X, Y, @A.MouseX, @A.MouseY);
  while SDL_PollEvent(@E) <> 0 do
    case E.Kind of
      EventQuit: A.Quit := True;
      EventKeyDown: if E.Key.Repeated = 0 then HandleKey(E.Key.Keysym.Sym);
      EventWindow:
        if (E.Window.Event = WindowFocusLost) and (A.Game.Phase = phRunning) then PauseGame;
      EventMouseDown:
        if E.Mouse.Button = 1 then
        begin
          { SDL logical-size rendering also transforms pointer event coordinates. }
          A.MouseX := E.Mouse.X; A.MouseY := E.Mouse.Y;
          HandleClick;
        end;
    end;
end;

procedure Update(Delta: Double);
var I: Integer; Step: TStepResult; Food: TPoint;
begin
  A.Elapsed := A.Elapsed + Delta;
  if A.LastPhase <> A.Game.Phase then A.PhaseAge := 0;
  A.LastPhase := A.Game.Phase;
  A.PhaseAge := A.PhaseAge + Delta;
  A.Flash := Max(0, A.Flash - Delta);
  A.Toast := Max(0, A.Toast - Delta);
  for I := 0 to High(A.Particles) do
    with A.Particles[I] do
      if Life > 0 then
      begin
        Life := Max(0, Life - Delta);
        X := X + VX * Delta; Y := Y + VY * Delta;
        VY := VY + 120 * Delta;
      end;
  if A.Game.Phase <> phRunning then Exit;
  if A.Countdown > 0 then
  begin
    A.Countdown := Max(0, A.Countdown - Delta);
    Exit;
  end;
  A.Accumulator := A.Accumulator + Delta;
  if A.Accumulator < TickInterval(A.Game) / 1000 then Exit;
  { At most one simulation step per update: a slow frame never causes a burst. }
  A.Accumulator := Min(A.Accumulator - TickInterval(A.Game) / 1000,
    TickInterval(A.Game) / 1000);
  A.Previous := A.Game;
  Food := A.Game.Food;
  Step := StepGame(A.Game);
  if Step in [srLost, srWon] then
  begin
    A.LastPhase := A.Game.Phase; A.PhaseAge := 0;
  end;
  if Step in [srAte, srWon] then
  begin
    Burst(BoardX + (Food.X - 0.5) * CellSize, BoardY + (Food.Y - 0.5) * CellSize, Mint, 24);
    A.ToastText := '+10  /  NICE BITE'; A.Toast := 1.1;
    Tone(660 + (A.Game.Score mod 50) * 8);
  end;
  if Step = srLost then
  begin
    A.Flash := 0.35;
    Tone(220, True);
    Burst(BoardX + (A.Game.Body[1].X - 0.5) * CellSize,
      BoardY + (A.Game.Body[1].Y - 0.5) * CellSize, Coral, 30);
  end;
  if Step = srWon then
    for I := 1 to 4 do Burst(BoardX + I * 150, BoardY + 160, Mint, 20);
  if A.Game.Score > A.Best[A.Game.Mode, A.Game.Difficulty] then
    A.Best[A.Game.Mode, A.Game.Difficulty] := A.Game.Score;
end;

procedure SnakeSegment(X, Y, Radius: Double; Color: LongWord);
begin
  Circle(X, Y, Radius, Color);
end;

procedure Ribbon(X1, Y1, X2, Y2, Radius: Double; C1, C2: LongWord);
var V: array[0..5] of TVertex; NX, NY, Distance: Double; I: Integer;
begin
  Distance := Hypot(X2 - X1, Y2 - Y1);
  if Distance < 0.01 then Exit;
  NX := -(Y2 - Y1) / Distance * Radius;
  NY := (X2 - X1) / Distance * Radius;
  for I := 0 to High(V) do
  begin
    V[I].TexCoord.X := 0; V[I].TexCoord.Y := 0;
    if I in [0, 1, 3] then V[I].Color := RGBA(C1) else V[I].Color := RGBA(C2);
  end;
  V[0].Position.X := X1 + NX; V[0].Position.Y := Y1 + NY;
  V[1].Position.X := X1 - NX; V[1].Position.Y := Y1 - NY;
  V[2].Position.X := X2 + NX; V[2].Position.Y := Y2 + NY;
  V[3] := V[1]; V[4] := V[2];
  V[5].Position.X := X2 - NX; V[5].Position.Y := Y2 - NY;
  SDL_RenderGeometry(A.Renderer, nil, @V[0], Length(V), nil, 0);
end;

procedure DrawSnake;
var I: Integer; Alpha, X, Y, PX, PY, DX, DY, EX, EY: Double;
  Positions: array[1..MaxCells] of TFPoint; C: LongWord;
begin
  Alpha := 1;
  if not A.ReducedMotion and (A.Game.Phase = phRunning) and (A.Countdown = 0) then
    Alpha := Min(1, A.Accumulator / (TickInterval(A.Game) / 1000));
  for I := 1 to A.Game.Length do
  begin
    X := A.Game.Body[I].X; Y := A.Game.Body[I].Y;
    if (I <= A.Previous.Length) and
       (Abs(X - A.Previous.Body[I].X) <= 1) and
       (Abs(Y - A.Previous.Body[I].Y) <= 1) then
    begin
      X := A.Previous.Body[I].X + (X - A.Previous.Body[I].X) * Alpha;
      Y := A.Previous.Body[I].Y + (Y - A.Previous.Body[I].Y) * Alpha;
    end;
    Positions[I].X := BoardX + (X - 0.5) * CellSize;
    Positions[I].Y := BoardY + (Y - 0.5) * CellSize;
  end;
  for I := A.Game.Length downto 1 do
  begin
    X := Positions[I].X; Y := Positions[I].Y;
    C := Blend(Mint, $208D83, (I - 1) / Max(8, A.Game.Length));
    if I < A.Game.Length then
    begin
      PX := Positions[I + 1].X; PY := Positions[I + 1].Y;
      if (Abs(X - PX) <= CellSize + 1) and (Abs(Y - PY) <= CellSize + 1) then
      begin
        Ribbon(X, Y, PX, PY, 11, C,
          Blend(Mint, $208D83, I / Max(8, A.Game.Length)));
      end;
    end;
    SnakeSegment(X, Y, 11, C);
    if (I > 1) and (I mod 2 = 0) then Circle(X - 2, Y - 3, 2, $E3FFD0, 35);
  end;
  X := Positions[1].X; Y := Positions[1].Y;
  Circle(X, Y, 12.5, Mint);
  DX := 0; DY := 0;
  case A.Game.Direction of
    dirUp: DY := -1; dirRight: DX := 1; dirDown: DY := 1; dirLeft: DX := -1;
  end;
  for I := -1 to 1 do
    if I <> 0 then
    begin
      EX := X + DX * 5 - DY * I * 5;
      EY := Y + DY * 5 + DX * I * 5;
      Circle(EX, EY, 3.5, $FAFFF0);
      Circle(EX + DX, EY + DY, 1.9, Ink);
    end;
end;

procedure DrawFood;
var X, Y, Pulse: Double;
begin
  if not A.Game.HasFood then Exit;
  X := BoardX + (A.Game.Food.X - 0.5) * CellSize;
  Y := BoardY + (A.Game.Food.Y - 0.5) * CellSize;
  Pulse := 0;
  if not A.ReducedMotion then Pulse := Sin(A.Elapsed * 4) * 1.5;
  Circle(X, Y, 19 + Pulse, Coral, 12);
  Circle(X, Y, 14 + Pulse, Coral, 22);
  Circle(X - 3, Y + 1, 6.5, Coral);
  Circle(X + 3, Y + 1, 6.5, Coral);
  Circle(X - 4, Y - 1, 2, $FFD7B4);
  Rounded(X + 1, Y - 10, 6, 4, 2, Mint);
  Rect(X, Y - 8, 2, 5, $D5EAB5);
end;

procedure DrawOverlay;
var Title, Subtitle, Hint: String; C: LongWord; Offset: Double;
begin
  if (A.Game.Phase = phRunning) and (A.Countdown = 0) then Exit;
  if (A.Game.Phase = phRunning) and (A.Countdown > 0) then
  begin
    Rounded(366, 342, 156, 166, 24, Ink, 235);
    Text(444, 354, 'GET READY', 0, Mint, True);
    Text(444, 378, IntToStr(Ceil(A.Countdown * 2)), 4, White, True);
    Exit;
  end;
  Rect(BoardX, BoardY, BoardW * CellSize, BoardH * CellSize, Ink, 160);
  C := Mint;
  case A.Game.Phase of
    phReady: begin Title := 'One more bite.'; Subtitle := 'A familiar game. A fresh start.'; Hint := 'PRESS ENTER TO PLAY'; end;
    phPaused: begin Title := 'Take a breath.'; Subtitle := 'Your next move can wait.'; Hint := 'SPACE TO RESUME'; end;
    phLost: begin Title := 'So close.'; Subtitle := IntToStr(A.Game.Score) + ' points. Ready for another run?'; Hint := 'ENTER TO TRY AGAIN'; C := Coral; end;
    phWon: begin Title := 'Every. Last. Bite.'; Subtitle := 'You filled the board. Beautifully done.'; Hint := 'ENTER TO PLAY AGAIN'; end;
  else Exit;
  end;
  Offset := 0;
  if not A.ReducedMotion then Offset := Power(1 - Min(1, A.PhaseAge / 0.22), 3) * 14;
  Rounded(180, 308 + Offset, 528, 238, 22, Edge);
  Rounded(181, 309 + Offset, 526, 236, 21, $101C27);
  Rounded(412, 333 + Offset, 64, 5, 2, C);
  Text(444, 364 + Offset, Title, 3, White, True);
  Text(444, 428 + Offset, Subtitle, 1, Muted, True);
  Text(444, 491 + Offset, Hint, 0, C, True);
end;

procedure Draw;
var I, X, Y: Integer; C: LongWord; Editable: Boolean; LabelText, Status: String;
  Clip: TRect; P: TParticle;
begin
  SetColor(Ink); SDL_RenderClear(A.Renderer);
  for Y := 0 to CanvasH div 4 do
    Rect(0, Y * 4, CanvasW, 4, Blend($121E29, Ink, Y / (CanvasH div 4)));
  Rounded(36, 40, 52, 52, 16, Mint);
  Rounded(49, 54, 25, 9, 4, Ink);
  Rounded(49, 54, 9, 26, 4, Ink);
  Rounded(49, 70, 27, 9, 4, Ink);
  Circle(72, 74, 6, Ink); Circle(74, 72, 1.5, Mint);
  Text(104, 32, 'snake.', 3, White);
  Text(106, 88, 'THE PASCAL EDITION', 0, Muted);
  Rounded(936, 52, 232, 34, 17, $20332C);
  Circle(956, 69, 3, Mint);
  Text(976, 61, 'OLD SCHOOL. NEW ENERGY.', 0, Mint);

  Rounded(32, 136, 824, 592, 22, Edge);
  Rounded(33, 137, 822, 590, 21, Panel);
  Circle(58, 162, 3, Mint);
  Text(72, 154, 'THE PLAYFIELD', 0, Muted);
  if A.Game.Mode = gmClassic then Status := 'SOLID WALLS'
  else Status := 'OPEN EDGES';
  Text(720, 154, Status, 0, Muted);
  Rect(BoardX, BoardY, BoardW * CellSize, BoardH * CellSize, $0D1620);
  SetColor($1A2834);
  for X := 0 to BoardW do
    SDL_RenderDrawLine(A.Renderer, BoardX + X * CellSize, BoardY,
      BoardX + X * CellSize, BoardY + BoardH * CellSize);
  for Y := 0 to BoardH do
    SDL_RenderDrawLine(A.Renderer, BoardX, BoardY + Y * CellSize,
      BoardX + BoardW * CellSize, BoardY + Y * CellSize);
  if A.Game.Mode = gmWrap then C := Teal else C := $4A5B68;
  Rect(BoardX, BoardY, 40, 2, C); Rect(BoardX, BoardY, 2, 40, C);
  Rect(BoardX + BoardW * CellSize - 40, BoardY + BoardH * CellSize - 2, 40, 2, C);
  Rect(BoardX + BoardW * CellSize - 2, BoardY + BoardH * CellSize - 40, 2, 40, C);
  Clip.X := BoardX; Clip.Y := BoardY; Clip.W := BoardW * CellSize; Clip.H := BoardH * CellSize;
  SDL_RenderSetClipRect(A.Renderer, @Clip);
  DrawFood; DrawSnake;
  for I := 0 to High(A.Particles) do
  begin
    P := A.Particles[I];
    if P.Life > 0 then Circle(P.X, P.Y, 1 + P.Life / P.Total * 2,
      P.Color, Round(220 * P.Life / P.Total));
  end;
  if (A.Flash > 0) and not A.ReducedMotion then
    Rect(BoardX, BoardY, BoardW * CellSize, BoardH * CellSize, Coral, Round(45 * A.Flash / 0.35));
  DrawOverlay;
  SDL_RenderSetClipRect(A.Renderer, nil);
  if (A.Toast > 0) and (A.Game.Phase = phRunning) then
    Text(444, 702, A.ToastText, 0, Mint, True);

  Rounded(880, 136, 288, 592, 22, Edge);
  Rounded(881, 137, 286, 590, 21, Panel);
  Text(912, 164, 'YOUR SCORE', 0, Muted);
  Text(907, 186, Format('%.3d', [A.Game.Score]), 4, White);
  Text(912, 290, 'SESSION BEST', 0, Muted);
  Text(1092, 287, IntToStr(A.Best[A.Game.Mode, A.Game.Difficulty]), 1, Mint);
  Rect(912, 326, 232, 1, Edge);
  Text(912, 348, '01 / CHOOSE YOUR WORLD', 0, Muted);
  Editable := A.Game.Phase = phReady;
  Button(912, 376, 112, 40, 'CLASSIC', A.Game.Mode = gmClassic, Editable);
  Button(1032, 376, 112, 40, 'WRAP', A.Game.Mode = gmWrap, Editable);
  if A.Game.Mode = gmClassic then LabelText := 'Mind the walls. Own the space.'
  else LabelText := 'Cross an edge. Keep the flow.';
  Text(912, 424, LabelText, 0, Muted);
  Text(912, 452, '02 / FIND YOUR PACE', 0, Muted);
  for I := 0 to 2 do Button(912 + I * 80, 476, 72, 38,
    SpeedNames[TDifficulty(I)], Ord(A.Game.Difficulty) = I, Editable, 0);
  case A.Game.Phase of
    phReady: LabelText := 'LET''S PLAY  >';
    phRunning: LabelText := 'PAUSE  II';
    phPaused: LabelText := 'KEEP GOING  >';
  else LabelText := 'ONE MORE RUN  >';
  end;
  Button(912, 552, 232, 52, LabelText, True);
  if Editable then Text(1028, 624, 'ENTER TO START', 0, Muted, True)
  else Button(912, 614, 232, 34, 'BACK TO MENU  /  ESC', False);
  if A.Audio = 0 then LabelText := 'NO AUDIO'
  else if A.Muted then LabelText := 'M / MUTED' else LabelText := 'M / SOUND';
  Text(912, 688, LabelText, 0, Muted);
  if A.ReducedMotion then LabelText := 'V / STILL' else LabelText := 'V / MOTION';
  Text(1040, 688, LabelText, 0, Muted);
  Text(40, 751, 'WASD / ARROWS   move', 0, White);
  Text(268, 751, 'SPACE   pause', 0, Muted);
  Text(434, 751, 'R   restart', 0, Muted);
  Text(568, 751, 'TAB   world', 0, Muted);
  Text(714, 751, '1 / 2 / 3   pace', 0, Muted);
  Text(936, 751, 'F11   fullscreen     Q   quit', 0, Muted);
end;

function FontPath: String;
const Paths: array[0..3] of String = (
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  '/System/Library/Fonts/Supplemental/Arial.ttf',
  '/Library/Fonts/Arial.ttf', '/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf');
var Candidate: String;
begin
  Result := GetEnvironmentVariable('SNAKE_FONT');
  if Result <> '' then Exit;
  for Candidate in Paths do if FileExists(Candidate) then Exit(Candidate);
  raise Exception.Create('No TrueType font found. Set SNAKE_FONT to a readable font file.');
end;

procedure Initialize(const Options: TDesktopOptions);
var I: Integer; Desired: TAudioSpec; Path: String; Flags: LongWord;
begin
  A := Default(TApp);
  A.FPMask := GetExceptionMask;
  { C graphics/audio libraries expect non-trapping IEEE floating-point math. }
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow,
    exUnderflow, exPrecision]);
  A.Seed := Options.Seed; A.Muted := Options.NoAudio; A.ReducedMotion := Options.ReducedMotion;
  LoadSDL;
  SDL_SetHint('SDL_RENDER_SCALE_QUALITY', '1');
  if SDL_Init($20) <> 0 then raise Exception.Create('Video initialization failed: ' + String(SDL_GetError()));
  A.SDLReady := True;
  Flags := $20 or $2000; { Resizable, high-DPI. }
  if Options.SelfTest or (Options.Snapshot <> '') then Flags := Flags or $8;
  A.Window := SDL_CreateWindow('Snake. / The Pascal Edition', $2FFF0000, $2FFF0000,
    CanvasW, CanvasH, Flags);
  if A.Window = nil then raise Exception.Create('Could not create a window: ' + String(SDL_GetError()));
  SDL_SetWindowMinimumSize(A.Window, 900, 600);
  A.Renderer := SDL_CreateRenderer(A.Window, -1, $2 or $4);
  if A.Renderer = nil then A.Renderer := SDL_CreateRenderer(A.Window, -1, $1);
  if A.Renderer = nil then raise Exception.Create('Could not create a renderer: ' + String(SDL_GetError()));
  SDL_RenderSetLogicalSize(A.Renderer, CanvasW, CanvasH);
  SDL_SetRenderDrawBlendMode(A.Renderer, 1);
  if TTF_Init() <> 0 then raise Exception.Create('Could not initialize SDL2_ttf.');
  A.TTFReady := True;
  Path := FontPath;
  for I := 0 to High(A.Fonts) do
  begin
    A.Fonts[I] := TTF_OpenFont(PChar(Path), FontSizes[I]);
    if A.Fonts[I] = nil then raise Exception.Create('Could not open font: ' + Path);
  end;
  if not Options.NoAudio and (SDL_InitSubSystem($10) = 0) then
  begin
    FillChar(Desired, SizeOf(Desired), 0);
    Desired.Frequency := 48000; Desired.Format := $8010;
    Desired.Channels := 1; Desired.Samples := 1024;
    A.Audio := SDL_OpenAudioDevice(nil, 0, @Desired, nil, 0);
    if A.Audio <> 0 then SDL_PauseAudioDevice(A.Audio, 0);
  end;
  A.Game.Difficulty := dfClassic; A.Game.Mode := gmClassic;
  ResetGame;
end;

procedure Cleanup;
var I: Integer;
begin
  if A.Audio <> 0 then SDL_CloseAudioDevice(A.Audio);
  for I := 0 to High(A.Cache) do
    if A.Cache[I].Texture <> nil then SDL_DestroyTexture(A.Cache[I].Texture);
  for I := 0 to High(A.Fonts) do
    if A.Fonts[I] <> nil then TTF_CloseFont(A.Fonts[I]);
  if A.TTFReady then TTF_Quit;
  if A.Renderer <> nil then SDL_DestroyRenderer(A.Renderer);
  if A.Window <> nil then SDL_DestroyWindow(A.Window);
  if A.SDLReady then SDL_Quit;
  UnloadSDL;
  SetExceptionMask(A.FPMask);
end;

procedure Snapshot(const FileName: String);
var Pixels: array of LongWord; Surface, RW: Pointer; W, H: LongInt;
begin
  if (SDL_GetRendererOutputSize(A.Renderer, @W, @H) <> 0) or
     (W < 1) or (H < 1) or (W > 8192) or (H > 8192) then
    raise Exception.Create('Unsupported screenshot dimensions.');
  { ReadPixels uses physical pixels, which may exceed logical size on Retina. }
  SetLength(Pixels, W * H);
  if SDL_RenderReadPixels(A.Renderer, nil, $16362004, @Pixels[0], W * 4) <> 0 then
    raise Exception.Create('Could not read rendered pixels.');
  Surface := SDL_CreateRGBSurfaceFrom(@Pixels[0], W, H, 32, W * 4,
    $00FF0000, $0000FF00, $000000FF, $FF000000);
  if Surface = nil then raise Exception.Create('Could not create screenshot surface.');
  try
    RW := SDL_RWFromFile(PChar(FileName), 'wb');
    if RW = nil then raise Exception.Create('Could not open screenshot output: ' + FileName);
    if SDL_SaveBMP_RW(Surface, RW, 1) <> 0 then raise Exception.Create('Could not write screenshot.');
  finally
    SDL_FreeSurface(Surface);
  end;
end;

procedure Require(Condition: Boolean; const MessageText: String);
begin
  if not Condition then raise Exception.Create('Graphical test failed: ' + MessageText);
end;

procedure PushKey(Key: LongInt);
var E: TEvent;
begin
  FillChar(E, SizeOf(E), 0); E.Kind := EventKeyDown; E.Key.Keysym.Sym := Key;
  Require(SDL_PushEvent(@E) = 1, 'push key'); Events;
end;

procedure SelfTest;
var I: Integer; Head: TPoint; E: TEvent; PreviousScore: Integer;
begin
  Events;
  PushKey(9); Require(A.Game.Mode = gmWrap, 'mode keyboard');
  PushKey(Ord('3')); Require(A.Game.Difficulty = dfFast, 'difficulty keyboard');
  PushKey(13); Require(A.Game.Phase = phRunning, 'start');
  Update(2); Head := A.Game.Body[1]; Update(0.1);
  Require(not SamePoint(Head, A.Game.Body[1]), 'simulation advances');
  PushKey(Ord('p')); Head := A.Game.Body[1]; Update(1);
  Require(SamePoint(Head, A.Game.Body[1]) and (A.Game.Phase = phPaused), 'pause freezes');
  PushKey(32); PushKey(KeyUp); Update(0.1);
  Require(A.Game.Direction = dirUp, 'arrow turn');
  FillChar(E, SizeOf(E), 0); E.Kind := EventWindow; E.Window.Event := WindowFocusLost;
  SDL_PushEvent(@E); Events;
  Require(A.Game.Phase = phPaused, 'focus loss pauses');
  PushKey(Ord('v')); Require(A.ReducedMotion, 'reduced motion');
  PushKey(Ord('m')); Require(A.Muted, 'mute');
  Require((A.Audio = 0) or (SDL_GetQueuedAudioSize(A.Audio) = 0), 'mute clears queued sound');
  PushKey(27); Require(A.Game.Phase = phReady, 'menu');
  FillChar(E, SizeOf(E), 0); E.Kind := EventMouseDown; E.Mouse.Button := 1;
  E.Mouse.X := 930; E.Mouse.Y := 393;
  SDL_PushEvent(@E); Events;
  Require(A.Game.Mode = gmClassic, 'mode pointer');
  E.Mouse.X := 950; E.Mouse.Y := 572; SDL_PushEvent(@E); Events;
  Require(A.Game.Phase = phRunning, 'start pointer');
  Update(2);
  A.Game.Food := Point(A.Game.Body[1].X + 1, A.Game.Body[1].Y);
  PreviousScore := A.Game.Score; Update(0.2);
  Require(A.Game.Score = PreviousScore + PointsPerFood, 'food and score');
  Require(A.Toast > 0, 'food feedback');
  for I := 1 to 35 do Update(0.2);
  Require(A.Game.Phase = phLost, 'wall loss');
  Head := A.Game.Body[1]; Update(1); Require(SamePoint(Head, A.Game.Body[1]), 'finished game freezes');
  Require(A.Best[A.Game.Mode, A.Game.Difficulty] = A.Game.Score, 'session record');
  Draw; SDL_RenderPresent(A.Renderer);
  PushKey(Ord('r')); Require((A.Game.Phase = phRunning) and (A.Game.Score = 0), 'restart');
  PushKey(Ord('q')); Require(A.Quit, 'quit');
  WriteLn('PASS graphical SDL replay: controls, modes, time, score, audio, focus and lifecycle');
end;

procedure SetScene(const Scene: String);
var I, X, Y: Integer;
begin
  A.PhaseAge := 1;
  if Scene = 'menu' then Exit;
  { Explicit screenshot fixture; ordinary games always start through the engine. }
  A.Game.Length := 21;
  for I := 1 to 8 do A.Game.Body[I] := Point(19 - I, 7);
  for I := 9 to 13 do A.Game.Body[I] := Point(11, I - 1);
  for I := 14 to 21 do A.Game.Body[I] := Point(I - 2, 12);
  A.Game.Direction := dirRight; A.Game.Food := Point(22, 7);
  A.Game.Score := 40; A.Best[gmClassic, dfClassic] := 120;
  A.Game.Phase := phRunning; A.Previous := A.Game; A.ReducedMotion := True;
  if Scene = 'pause' then A.Game.Phase := phPaused;
  if Scene = 'over' then A.Game.Phase := phLost;
  if Scene = 'win' then
  begin
    I := 0;
    for Y := 1 to BoardH do
      if Odd(Y) then
        for X := 2 to BoardW do begin Inc(I); A.Game.Body[I] := Point(X, Y); end
      else
        for X := BoardW downto 2 do begin Inc(I); A.Game.Body[I] := Point(X, Y); end;
    for Y := BoardH downto 2 do begin Inc(I); A.Game.Body[I] := Point(1, Y); end;
    A.Game.Length := I; A.Game.Direction := dirLeft;
    A.Game.Food := Point(1, 1); A.Game.Score := 990;
    StepGame(A.Game); A.Previous := A.Game;
    A.Best[gmClassic, dfClassic] := A.Game.Score;
  end;
end;

function RunDesktop(const Options: TDesktopOptions): Integer;
var Last, Now, FrameTime: QWord; Delta: Double;
begin
  Result := 0;
  try
    try
      Initialize(Options);
      if Options.SelfTest then SelfTest
      else if Options.Snapshot <> '' then
      begin
        SetScene(Options.Scene); Draw; Snapshot(Options.Snapshot);
        WriteLn('Saved rendered frame: ' + Options.Snapshot);
      end
      else
      begin
        Last := SDL_GetTicks64();
        while not A.Quit do
        begin
          Now := SDL_GetTicks64(); Delta := Min(0.05, (Now - Last) / 1000); Last := Now;
          Events; Update(Delta); Draw; SDL_RenderPresent(A.Renderer);
          FrameTime := SDL_GetTicks64() - Now;
          if FrameTime < 16 then SDL_Delay(16 - FrameTime);
        end;
      end;
    finally
      Cleanup;
    end;
  except
    on E: Exception do
    begin
      WriteLn(StdErr, E.Message);
      if GetEnvironmentVariable('SNAKE_DEBUG') = '1' then DumpExceptionBackTrace(StdErr);
      Result := 1;
    end;
  end;
end;

end.
