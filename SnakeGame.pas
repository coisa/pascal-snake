program SnakeGame;

uses crt;

type
    TSnakeSeg = record
              x, y : integer;
              end;
    TSnake = array[1..1400] of TSnakeSeg;
    TFood = record
          x, y : integer;
          end;

const UP = 1;
      RIGHT = 2;
      DOWN = 3;
      LEFT = 4;
      UPLIMIT = 1;
      DOWNLIMIT = 50;
      RIGHTLIMIT = 79;
      LEFTLIMIT = 1;
      BODY = 219;
      C1 = 6;
      C2 = 4;
      C3 = 2;

procedure MoveSnake(var snake : TSnake; direction : integer; size : integer);
var
   i : integer;
begin
     textcolor(C1);
     gotoxy(snake[size].x, snake[size].y); write(' ');

     for i:=size downto 2 do
     begin
         snake[i].x:=snake[i-1].x;
         snake[i].y:=snake[i-1].y;
     end;

     case direction of
          UP: snake[1].y:=snake[1].y-1;
          RIGHT: snake[1].x:=snake[1].x+1;
          DOWN: snake[1].y:=snake[1].y+1;
          LEFT: snake[1].x:=snake[1].x-1;
     end;

     gotoxy(snake[1].x, snake[1].y); write(chr(BODY));
end;

function EvaluatePosition(snake : TSnake; food : TFood; size : integer) : integer;
var
   i : integer;
begin
     if (snake[1].y = UPLIMIT) or (snake[1].y = DOWNLIMIT) or
        (snake[1].x = RIGHTLIMIT) or (snake[1].x = LEFTLIMIT) then
        EvaluatePosition:=0
     else if (snake[1].x = food.x) and (snake[1].y = food.y) then
          EvaluatePosition:=1
     else EvaluatePosition:=2;

     for i:=2 to size do
         if (snake[1].x = snake[i].x) and (snake[1].y = snake[i].y) then
            EvaluatePosition:=0;
end;

procedure PutFood(var food : TFood);
begin
     food.x:=random(RIGHTLIMIT - LEFTLIMIT - 1) + LEFTLIMIT +1;
     food.y:=random(DOWNLIMIT - UPLIMIT - 1) + UPLIMIT + 1;

     textcolor(C2);
     gotoxy(food.x, food.y); write(chr(42));
end;

procedure DrawBorder(x0, y0, x1, y1 : integer);
var
   x, y : integer;
begin
     textcolor(C3);
     for x:=x0 to x1 do
     begin
          gotoxy(x, y0); write(chr(196));
     end;

     for y:=y0 to y1 do
     begin
          gotoxy(x0, y); write(chr(179));
          gotoxy(x1, y); write(chr(179));
     end;

     for x:=x0 to x1 do
     begin
          gotoxy(x, y1); write(chr(196));
     end;

     gotoxy(x0, y0); write(chr(218));
     gotoxy(x1, y0); write(chr(191));
     gotoxy(x0, y1); write(chr(192));
     gotoxy(x1, y1); write(chr(217));
end;

procedure InitGame(var snake : TSnake; var food : TFood; size : integer);
var
   i, x, y : integer;
begin
     x:=LEFTLIMIT+15; y:=UPLIMIT+10;
     for i:=1 to size do
     begin
          snake[i].x:=x;
          snake[i].y:=y;
          x:=x-1;

          gotoxy(snake[i].x, snake[i].y); write(chr(BODY));
     end;

     PutFood(food);
end;

var
   snake : TSnake;
   food : TFood;
   direction, size, n : integer;
   c : char;
   dlay : integer;

begin
     size:=5; direction:=RIGHT;

     Clrscr;
     Randomize;

     DrawBorder(LEFTLIMIT, UPLIMIT, RIGHTLIMIT, DOWNLIMIT);
     InitGame(snake, food, size);

     dlay := 75;
     repeat
           delay(dlay);

           if KeyPressed then
           begin
                c:=ReadKey;
                case c of
                     'w': if direction <> DOWN then
                             direction:=UP;
                     'd': if direction <> LEFT then
                             direction:=RIGHT;
                     's': if direction <> UP then
                             direction:=DOWN;
                     'a': if direction <> RIGHT then
                             direction:=LEFT;
                end;
           end;

           MoveSnake(snake, direction, size);
           n:=EvaluatePosition(snake, food, size);

           randomize;
           if n=1 then
           begin
                size:=size+5;
                dlay := dlay - 2;
                if dlay <= 1 then dlay := 1;
                PutFood(food);
                sound(random(3000));
                delay(50);
                nosound;
           end;
     until n=0;
end.
